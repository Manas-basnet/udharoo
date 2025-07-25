import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_contact_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final FirebaseFirestore _firestore;

  TransactionRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final docRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc();

    final transactionWithId = TransactionModel.fromEntity(
      transaction.copyWith(id: docRef.id),
    );

    await docRef.set(transactionWithId.toJson());

    return transactionWithId;
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    String? lastDocumentId,
    DateTime? lastSyncTime,
  }) async {
    if (userId == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');

    // if (lastSyncTime != null) {
    //   query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
    // }

    query = query.orderBy('updatedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (lastDocumentId != null && lastSyncTime == null) {
      final lastDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(lastDocumentId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final querySnapshot = await query.get();
    
    List<TransactionModel> transactions = querySnapshot.docs
        .map((doc) => TransactionModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      transactions = transactions.where((transaction) {
        return transaction.contactName.toLowerCase().contains(searchLower) ||
               transaction.contactPhone.contains(searchQuery) ||
               (transaction.description?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    if (lastSyncTime == null) {
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return transactions;
  }

  @override
  Future<TransactionModel> getTransactionById(String id, String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    return TransactionModel.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final updatedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(updatedAt: DateTime.now()),
    );

    await _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(transaction.id)
        .update(updatedTransaction.toJson());

    return updatedTransaction;
  }

  @override
  Future<void> deleteTransaction(String id, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  @override
  Future<List<TransactionContactModel>> getTransactionContacts(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    final Map<String, TransactionContactModel> contactsMap = {};

    for (final doc in querySnapshot.docs) {
      final transaction = TransactionModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      });

      final phone = transaction.contactPhone;
      final existing = contactsMap[phone];

      if (existing == null) {
        contactsMap[phone] = TransactionContactModel(
          phone: phone,
          name: transaction.contactName,
          email: transaction.contactEmail,
          transactionCount: 1,
          lastTransactionDate: transaction.createdAt,
        );
      } else {
        contactsMap[phone] = TransactionContactModel(
          phone: phone,
          name: transaction.contactName,
          email: transaction.contactEmail,
          transactionCount: existing.transactionCount + 1,
          lastTransactionDate: transaction.createdAt.isAfter(existing.lastTransactionDate)
              ? transaction.createdAt
              : existing.lastTransactionDate,
        );
      }
    }

    final contacts = contactsMap.values.toList();
    contacts.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));

    return contacts;
  }

  @override
  Future<List<TransactionModel>> getContactTransactions(String userId, String contactPhone) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('contactPhone', isEqualTo: contactPhone)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  @override
  Future<bool> getGlobalVerificationSetting(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    
    if (!doc.exists) {
      return false;
    }

    final data = doc.data();
    return data?['globalVerificationRequired'] as bool? ?? false;
  }

  @override
  Future<void> setGlobalVerificationSetting(String userId, bool enabled) async {
    await _firestore.collection('users').doc(userId).update({
      'globalVerificationRequired': enabled,
    });
  }

  @override
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    int totalTransactions = 0;
    int pendingTransactions = 0;
    int verifiedTransactions = 0;
    int completedTransactions = 0;
    double totalLending = 0;
    double totalBorrowing = 0;

    for (final doc in querySnapshot.docs) {
      final transaction = TransactionModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      });

      totalTransactions++;

      switch (transaction.status) {
        case TransactionStatus.pending:
          pendingTransactions++;
          break;
        case TransactionStatus.verified:
          verifiedTransactions++;
          break;
        case TransactionStatus.completed:
          completedTransactions++;
          break;
        case TransactionStatus.cancelled:
          break;
      }

      if (transaction.status != TransactionStatus.cancelled) {
        if (transaction.type == TransactionType.lending) {
          totalLending += transaction.amount;
        } else {
          totalBorrowing += transaction.amount;
        }
      }
    }

    return {
      'totalTransactions': totalTransactions,
      'pendingTransactions': pendingTransactions,
      'verifiedTransactions': verifiedTransactions,
      'completedTransactions': completedTransactions,
      'totalLending': totalLending,
      'totalBorrowing': totalBorrowing,
      'netAmount': totalLending - totalBorrowing,
    };
  }
}