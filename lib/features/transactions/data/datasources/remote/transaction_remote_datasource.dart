import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/utils/transaction_extensions.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRemoteDatasource {
  Future<void> createTransaction(TransactionModel transaction);
  Stream<List<TransactionModel>> getTransactions();
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status);
  Future<TransactionModel?> getTransactionById(String transactionId);
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type);
  Future<List<TransactionModel>> getTransactionsByStatus(TransactionStatus status);
}

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  TransactionRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _userTransactionsCollection {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('transactions');
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    await _userTransactionsCollection
        .doc(transaction.transactionId)
        .set(transaction.toJson());
  }

  @override
  Stream<List<TransactionModel>> getTransactions() {
    return _userTransactionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromJson(doc.data());
      }).toList();
    });
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    final updateData = <String, dynamic>{
      'status': TransactionUtils.transactionStatusToString(status),
    };

    // Add timestamp based on status
    final now = DateTime.now().toIso8601String();
    switch (status) {
      case TransactionStatus.verified:
        updateData['verifiedAt'] = now;
        break;
      case TransactionStatus.completed:
        updateData['completedAt'] = now;
        break;
      case TransactionStatus.rejected:
        // Keep the original timestamps
        break;
      case TransactionStatus.pendingVerification:
        // Reset timestamps if going back to pending
        updateData['verifiedAt'] = null;
        updateData['completedAt'] = null;
        break;
    }

    await _userTransactionsCollection
        .doc(transactionId)
        .update(updateData);
  }

  @override
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    final doc = await _userTransactionsCollection
        .doc(transactionId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TransactionModel.fromJson(doc.data()!);
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type) async {
    final typeString = TransactionUtils.transactionTypeToString(type);
    
    final snapshot = await _userTransactionsCollection
        .where('type', isEqualTo: typeString)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return TransactionModel.fromJson(doc.data());
    }).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByStatus(TransactionStatus status) async {
    final statusString = TransactionUtils.transactionStatusToString(status);
    
    final snapshot = await _userTransactionsCollection
        .where('status', isEqualTo: statusString)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return TransactionModel.fromJson(doc.data());
    }).toList();
  }
}