import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_contact_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_stats_model.dart';
import 'package:udharoo/features/transactions/data/models/contact_summary_model.dart';
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
    final docRef = _firestore.collection('transactions').doc();

    final transactionWithId = TransactionModel.fromEntity(
      transaction.copyWith(id: docRef.id),
    );

    await docRef.set(transactionWithId.toJson());

    _updateContactSummaryAsync(
      transaction.creatorId,
      transaction.recipientPhone ?? transaction.contactPhone,
      transaction.contactName,
      transaction.contactEmail,
    );

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

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    List<Query> queries = [];

    Query creatorQuery = _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    Query recipientQuery = _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    if (lastSyncTime != null) {
      creatorQuery = creatorQuery.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      recipientQuery = recipientQuery.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
    }

    if (status != null) {
      creatorQuery = creatorQuery.where('status', isEqualTo: status.name);
      recipientQuery = recipientQuery.where('status', isEqualTo: status.name);
    }

    queries.add(creatorQuery);
    queries.add(recipientQuery);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    List<TransactionModel> transactions = [];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
        transactions.add(transaction.transformForUser(userId, userPhone: userPhone, userName: userName));
      }
    }

    transactions = transactions.where((t) => t.status != TransactionStatus.completed).toList();

    if (type != null) {
      transactions = transactions.where((t) => t.type == type).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      transactions = transactions.where((transaction) {
        return transaction.contactName.toLowerCase().contains(searchLower) ||
               (transaction.recipientPhone?.contains(searchQuery) ?? false) ||
               (transaction.description?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && transactions.length > limit) {
      transactions = transactions.take(limit).toList();
    }

    return transactions;
  }

  @override
  Future<List<String>> getDeletedTransactions({
    required String userId,
    DateTime? lastSyncTime,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .where('isDeleted', isEqualTo: true);

    if (lastSyncTime != null) {
      query = query.where('deletedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
    }

    final creatorQuery = query.where('creatorId', isEqualTo: userId);
    final recipientQuery = query.where('recipientId', isEqualTo: userId);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    final deletedIds = <String>{};
    
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        deletedIds.add(doc.id);
      }
    }

    return deletedIds.toList();
  }

  @override
  Future<TransactionModel> getTransactionById(String id, String userId) async {
    final doc = await _firestore.collection('transactions').doc(id).get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = TransactionModel.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });

    if (!transaction.isUserInvolved(userId)) {
      throw Exception('Access denied');
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    return transaction.transformForUser(userId, userPhone: userPhone, userName: userName);
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final updatedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(updatedAt: DateTime.now()),
    );

    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(updatedTransaction.toJson());

    _updateContactSummaryAsync(
      transaction.creatorId,
      transaction.recipientPhone ?? transaction.contactPhone,
      transaction.contactName,
      transaction.contactEmail,
    );

    return updatedTransaction;
  }

  @override
  Future<void> deleteTransaction(String id, String userId) async {
    final transaction = await getTransactionById(id, userId);
    
    if (transaction.isVerified) {
      throw Exception('Cannot delete verified transactions');
    }

    if (!transaction.isUserCreator(userId)) {
      throw Exception('Only transaction creator can delete the transaction');
    }

    await _firestore.collection('transactions').doc(id).update({
      'isDeleted': true,
      'deletedAt': Timestamp.fromDate(DateTime.now()),
      'deletedBy': userId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    _updateContactSummaryAsync(
      transaction.creatorId,
      transaction.recipientPhone ?? transaction.contactPhone,
      transaction.contactName,
      transaction.contactEmail,
    );
  }

  @override
  Future<TransactionModel> verifyTransaction(String id, String verifiedBy) async {
    final transaction = await getTransactionById(id, verifiedBy);
    
    if (!transaction.isUserRecipient(verifiedBy)) {
      throw Exception('Only transaction recipients can verify transactions');
    }

    if (transaction.isVerified) {
      throw Exception('Transaction is already verified');
    }

    if (!transaction.verificationRequired) {
      throw Exception('This transaction does not require verification');
    }

    final updatedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(
        isVerified: true,
        verifiedBy: verifiedBy,
        status: TransactionStatus.verified,
        updatedAt: DateTime.now(),
      ),
    );

    await _firestore.collection('transactions').doc(id).update(updatedTransaction.toJson());

    return updatedTransaction;
  }

  @override
  Future<TransactionModel> completeTransaction(String id, String userId, String userRole) async {
    final transaction = await getTransactionById(id, userId);

    if (transaction.type == TransactionType.lending && userRole != 'creator') {
      throw Exception('Only lender can complete lending transactions');
    }

    if (transaction.type == TransactionType.borrowing && userRole != 'recipient') {
      throw Exception('Only borrower can complete borrowing transactions');
    }

    if (transaction.verificationRequired && !transaction.isVerified) {
      throw Exception('Transaction must be verified before completion');
    }

    final completedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(
        status: TransactionStatus.completed,
        completedAt: DateTime.now(),
        completedBy: userId,
        updatedAt: DateTime.now(),
      ),
    );

    await _firestore.collection('transactions').doc(id).update(completedTransaction.toJson());

    _updateContactSummaryAsync(
      transaction.creatorId,
      transaction.recipientPhone ?? transaction.contactPhone,
      transaction.contactName,
      transaction.contactEmail,
    );

    return completedTransaction;
  }

  @override
  Future<void> moveTransactionToFinished(TransactionModel transaction) async {
  }

  @override
  Future<List<TransactionModel>> getFinishedTransactions(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    final creatorQuery = _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('status', isEqualTo: TransactionStatus.completed.name)
        .where('isDeleted', isEqualTo: false);

    final recipientQuery = _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: TransactionStatus.completed.name)
        .where('isDeleted', isEqualTo: false);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    List<TransactionModel> transactions = [];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
        transactions.add(transaction.transformForUser(userId, userPhone: userPhone, userName: userName));
      }
    }

    transactions.sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

    return transactions;
  }

  @override
  Future<List<TransactionContactModel>> getTransactionContacts(String userId) async {
    try {
      final summariesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transaction_summaries')
          .orderBy('lastTransactionDate', descending: true)
          .get();

      if (summariesSnapshot.docs.isNotEmpty) {
        return summariesSnapshot.docs
            .map((doc) => TransactionContactModel.fromJson({
                  ...doc.data(),
                  'phone': doc.data()['contactPhone'],
                  'name': doc.data()['contactName'],
                  'email': doc.data()['contactEmail'],
                }))
            .toList();
      }
    } catch (e) {
    }

    return _calculateContactsFromTransactions(userId);
  }

  Future<List<TransactionContactModel>> _calculateContactsFromTransactions(String userId) async {
    final creatorQuery = _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    final recipientQuery = _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    final Map<String, TransactionContactModel> contactsMap = {};

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });

        String? contactPhone;
        String contactName;

        if (transaction.creatorId == userId) {
          contactPhone = transaction.recipientPhone;
          contactName = transaction.contactName;
        } else {
          contactPhone = transaction.creatorPhone;
          contactName = 'Transaction Partner';
        }

        if (contactPhone == null) continue;

        final existing = contactsMap[contactPhone];

        if (existing == null) {
          contactsMap[contactPhone] = TransactionContactModel(
            phone: contactPhone,
            name: contactName,
            email: transaction.contactEmail,
            transactionCount: 1,
            lastTransactionDate: transaction.createdAt,
          );
        } else {
          contactsMap[contactPhone] = TransactionContactModel(
            phone: contactPhone,
            name: contactName,
            email: transaction.contactEmail,
            transactionCount: existing.transactionCount + 1,
            lastTransactionDate: transaction.createdAt.isAfter(existing.lastTransactionDate)
                ? transaction.createdAt
                : existing.lastTransactionDate,
          );
        }
      }
    }

    final contacts = contactsMap.values.toList();
    contacts.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));

    return contacts;
  }

  @override
  Future<List<TransactionModel>> getContactTransactions(String userId, String contactPhone) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    final creatorQuery = _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('recipientPhone', isEqualTo: contactPhone)
        .where('isDeleted', isEqualTo: false);

    final recipientQuery = _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('creatorPhone', isEqualTo: contactPhone)
        .where('isDeleted', isEqualTo: false);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    List<TransactionModel> transactions = [];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
        transactions.add(transaction.transformForUser(userId, userPhone: userPhone, userName: userName));
      }
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
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
  Future<TransactionStatsModel> getTransactionStats(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    final creatorQuery = _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    final recipientQuery = _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    final results = await Future.wait([
      creatorQuery.get(),
      recipientQuery.get(),
    ]);

    List<TransactionModel> transactions = [];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
        transactions.add(transaction.transformForUser(userId, userPhone: userPhone, userName: userName));
      }
    }

    final activeTransactions = transactions
        .where((transaction) => transaction.status != TransactionStatus.completed)
        .toList();

    return _calculateStatsFromTransactions(activeTransactions);
  }

  @override
  Future<String?> verifyPhoneExists(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: '+977$phoneNumber')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    
    return null;
  }

  @override
  Future<List<TransactionModel>> getReceivedTransactionRequests(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    final querySnapshot = await _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: TransactionStatus.pending.name)
        .where('verificationRequired', isEqualTo: true)
        .where('isVerified', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) {
          final transaction = TransactionModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          return transaction.transformForUser(userId, userPhone: userPhone, userName: userName);
        })
        .toList();
  }

  @override
  Future<TransactionModel> requestTransactionCompletion(String transactionId, String requestedBy) async {
    final transaction = await getTransactionById(transactionId, requestedBy);
    
    if (transaction.completionRequested) {
      throw Exception('Completion request already sent for this transaction');
    }

    if (transaction.isCompleted) {
      throw Exception('Transaction is already completed');
    }

    final updatedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(
        completionRequested: true,
        completionRequestedBy: requestedBy,
        completionRequestedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await _firestore.collection('transactions').doc(transactionId).update(updatedTransaction.toJson());

    return updatedTransaction;
  }

  @override
  Future<List<TransactionModel>> getCompletionRequests(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userPhone = userData?['phoneNumber'] as String?;
    final userName = userData?['displayName'] as String? ?? userData?['email'] as String?;

    final querySnapshot = await _firestore
        .collection('transactions')
        .where('creatorId', isEqualTo: userId)
        .where('completionRequested', isEqualTo: true)
        .where('status', whereIn: [TransactionStatus.pending.name, TransactionStatus.verified.name])
        .where('isDeleted', isEqualTo: false)
        .orderBy('completionRequestedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) {
          final transaction = TransactionModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          return transaction.transformForUser(userId, userPhone: userPhone, userName: userName);
        })
        .toList();
  }

  void _updateContactSummaryAsync(String userId, String? contactPhone, String contactName, String? contactEmail) {
    if (contactPhone == null) return;

    Future.microtask(() async {
      try {
        final transactions = await getContactTransactions(userId, contactPhone);
        
        if (transactions.isEmpty) return;

        double totalLending = 0;
        double totalBorrowing = 0;
        DateTime lastTransactionDate = transactions.first.createdAt;

        for (final transaction in transactions) {
          if (transaction.status != TransactionStatus.completed) {
            if (transaction.type == TransactionType.lending) {
              totalLending += transaction.amount;
            } else {
              totalBorrowing += transaction.amount;
            }
          }

          if (transaction.createdAt.isAfter(lastTransactionDate)) {
            lastTransactionDate = transaction.createdAt;
          }
        }

        final summary = ContactSummaryModel(
          phone: contactPhone,
          name: contactName,
          email: contactEmail,
          transactionCount: transactions.length,
          lastTransactionDate: lastTransactionDate,
          totalLending: totalLending,
          totalBorrowing: totalBorrowing,
          netAmount: totalLending - totalBorrowing,
        );

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('transaction_summaries')
            .doc(contactPhone)
            .set(summary.toJson());
      } catch (e) {
      }
    });
  }

  TransactionStatsModel _calculateStatsFromTransactions(List<TransactionModel> transactions) {
    int totalTransactions = 0;
    int pendingTransactions = 0;
    int verifiedTransactions = 0;
    int completedTransactions = 0;
    double totalLending = 0;
    double totalBorrowing = 0;

    for (final transaction in transactions) {
      if (transaction.status == TransactionStatus.completed) continue;
      
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

    return TransactionStatsModel(
      totalTransactions: totalTransactions,
      pendingTransactions: pendingTransactions,
      verifiedTransactions: verifiedTransactions,
      completedTransactions: completedTransactions,
      totalLending: totalLending,
      totalBorrowing: totalBorrowing,
      netAmount: totalLending - totalBorrowing,
    );
  }
}