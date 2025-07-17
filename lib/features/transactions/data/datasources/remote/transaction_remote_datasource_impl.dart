import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'transactions';

  TransactionRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    Query query = _firestore.collection(_collection);

    if (userId != null) {
      query = query.where(
        Filter.or(
          Filter('fromUserId', isEqualTo: userId),
          Filter('toUserId', isEqualTo: userId),
        ),
      );
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<TransactionModel> getTransactionById(String transactionId) async {
    final doc = await _firestore.collection(_collection).doc(transactionId).get();
    
    if (!doc.exists) {
      throw Exception('Transaction not found');
    }
    
    return TransactionModel.fromFirestore(doc);
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final docRef = _firestore.collection(_collection).doc();
    final transactionWithId = transaction.copyWith(id: docRef.id);
    
    await docRef.set(transactionWithId.toFirestore());
    
    return transactionWithId;
  }

  @override
  Future<TransactionModel> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  ) async {
    final docRef = _firestore.collection(_collection).doc(transactionId);
    
    await docRef.update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
    
    return getTransactionById(transactionId);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection(_collection).doc(transactionId).delete();
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: userId),
            Filter('toUserId', isEqualTo: userId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<List<TransactionModel>> searchTransactions({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query firestoreQuery = _firestore
        .collection(_collection)
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: userId),
            Filter('toUserId', isEqualTo: userId),
          ),
        );

    if (type != null) {
      firestoreQuery = firestoreQuery.where('type', isEqualTo: type.name);
    }

    if (status != null) {
      firestoreQuery = firestoreQuery.where('status', isEqualTo: status.name);
    }

    if (startDate != null) {
      firestoreQuery = firestoreQuery.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      firestoreQuery = firestoreQuery.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    firestoreQuery = firestoreQuery.orderBy('createdAt', descending: true);

    final snapshot = await firestoreQuery.get();
    List<TransactionModel> transactions = snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();

    if (query != null && query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      transactions = transactions.where((transaction) {
        return (transaction.fromUserName?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.toUserName?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.description?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    return transactions;
  }

  @override
  Future<Map<String, double>> getTransactionSummary(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: userId),
            Filter('toUserId', isEqualTo: userId),
          ),
        )
        .where('status', isEqualTo: TransactionStatus.verified.name)
        .get();

    double totalLent = 0.0;
    double totalBorrowed = 0.0;

    for (final doc in snapshot.docs) {
      final transaction = TransactionModel.fromFirestore(doc);
      
      if (transaction.fromUserId == userId && transaction.type == TransactionType.lend) {
        totalLent += transaction.amount;
      } else if (transaction.toUserId == userId && transaction.type == TransactionType.borrow) {
        totalBorrowed += transaction.amount;
      }
    }

    return {
      'totalLent': totalLent,
      'totalBorrowed': totalBorrowed,
      'netBalance': totalLent - totalBorrowed,
    };
  }
}