import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';
  static const String _transactionsSubcollection = 'transactions';

  TransactionRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _getUserTransactionsCollection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_transactionsSubcollection);
  }

  Future<String?> _findUserByPhone(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection(_usersCollection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    
    return null;
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    if (userId == null) {
      throw Exception('User ID is required to fetch transactions');
    }

    Query query = _getUserTransactionsCollection(userId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();

    final uniqueTransactions = <String, TransactionModel>{};
    for (final transaction in transactions) {
      uniqueTransactions[transaction.id] = transaction;
    }

    return uniqueTransactions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<TransactionModel> getTransactionById(String transactionId) async {
    final usersSnapshot = await _firestore.collection(_usersCollection).get();
    
    for (final userDoc in usersSnapshot.docs) {
      final transactionDoc = await userDoc.reference
          .collection(_transactionsSubcollection)
          .doc(transactionId)
          .get();
      
      if (transactionDoc.exists) {
        return TransactionModel.fromFirestore(transactionDoc);
      }
    }
    
    throw Exception('Transaction not found');
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    String actualFromUserId = transaction.fromUserId;
    String actualToUserId = transaction.toUserId;

    if (!_isValidUserId(transaction.fromUserId)) {
      final foundUserId = await _findUserByPhone(transaction.fromUserPhone ?? '');
      if (foundUserId != null) {
        actualFromUserId = foundUserId;
      } else {
        throw Exception('User with phone ${transaction.fromUserPhone} not found. They need to register first.');
      }
    }

    if (!_isValidUserId(transaction.toUserId)) {
      final foundUserId = await _findUserByPhone(transaction.toUserPhone ?? '');
      if (foundUserId != null) {
        actualToUserId = foundUserId;
      } else {
        throw Exception('User with phone ${transaction.toUserPhone} not found. They need to register first.');
      }
    }

    final fromUserCollection = _getUserTransactionsCollection(actualFromUserId);
    final toUserCollection = _getUserTransactionsCollection(actualToUserId);
    
    final docRef = fromUserCollection.doc();
    final transactionWithCorrectIds = transaction.copyWith(
      id: docRef.id,
      fromUserId: actualFromUserId,
      toUserId: actualToUserId,
    );
    
    final batch = _firestore.batch();
    
    batch.set(docRef, transactionWithCorrectIds.toFirestore());
    
    if (actualFromUserId != actualToUserId) {
      final toUserDocRef = toUserCollection.doc(docRef.id);
      batch.set(toUserDocRef, transactionWithCorrectIds.toFirestore());
    }
    
    await batch.commit();
    
    return transactionWithCorrectIds;
  }

  bool _isValidUserId(String userId) {
    return userId.length >= 20 && !userId.contains('_user') && !userId.contains('@');
  }

  @override
  Future<TransactionModel> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  ) async {
    final usersSnapshot = await _firestore.collection(_usersCollection).get();
    final batch = _firestore.batch();
    TransactionModel? originalTransaction;
    
    for (final userDoc in usersSnapshot.docs) {
      final transactionDocRef = userDoc.reference
          .collection(_transactionsSubcollection)
          .doc(transactionId);
      
      final transactionDoc = await transactionDocRef.get();
      
      if (transactionDoc.exists && originalTransaction == null) {
        originalTransaction = TransactionModel.fromFirestore(transactionDoc);
      }
      
      if (transactionDoc.exists) {
        batch.update(transactionDocRef, {
          'status': status.name,
          'updatedAt': Timestamp.now(),
        });
      }
    }
    
    if (originalTransaction == null) {
      throw Exception('Transaction not found');
    }
    
    await batch.commit();
    
    return originalTransaction.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final usersSnapshot = await _firestore.collection(_usersCollection).get();
    final batch = _firestore.batch();
    
    for (final userDoc in usersSnapshot.docs) {
      final transactionDocRef = userDoc.reference
          .collection(_transactionsSubcollection)
          .doc(transactionId);
      
      final transactionDoc = await transactionDocRef.get();
      
      if (transactionDoc.exists) {
        batch.delete(transactionDocRef);
      }
    }
    
    await batch.commit();
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _getUserTransactionsCollection(userId)
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
    Query firestoreQuery = _getUserTransactionsCollection(userId);

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

    final uniqueTransactions = <String, TransactionModel>{};
    for (final transaction in transactions) {
      uniqueTransactions[transaction.id] = transaction;
    }

    transactions = uniqueTransactions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (query != null && query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      transactions = transactions.where((transaction) {
        return (transaction.fromUserName?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.toUserName?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.description?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.fromUserPhone?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.toUserPhone?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    return transactions;
  }

  @override
  Future<Map<String, double>> getTransactionSummary(String userId) async {
    final snapshot = await _getUserTransactionsCollection(userId)
        .where('status', isEqualTo: TransactionStatus.verified.name)
        .get();

    final uniqueTransactions = <String, TransactionModel>{};
    for (final doc in snapshot.docs) {
      final transaction = TransactionModel.fromFirestore(doc);
      uniqueTransactions[transaction.id] = transaction;
    }

    double totalLent = 0.0;
    double totalBorrowed = 0.0;

    for (final transaction in uniqueTransactions.values) {
      if (transaction.type == TransactionType.lend && transaction.fromUserId == userId) {
        totalLent += transaction.amount;
      } else if (transaction.type == TransactionType.borrow && transaction.toUserId == userId) {
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