import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_contact_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_stats_model.dart';
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

    final batch = _firestore.batch();

    batch.set(docRef, transactionWithId.toJson());

    if (transaction.recipientUserId != null) {
      final recipientDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('received_transactions')
          .doc(docRef.id);

      batch.set(recipientDocRef, transactionWithId.toJson());

      final recipientTransactionDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('transactions')
          .doc(docRef.id);

      final flippedTransaction = await _createFlippedTransaction(transactionWithId, transaction.recipientUserId!);
      batch.set(recipientTransactionDocRef, flippedTransaction.toJson());
    }

    await batch.commit();

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
        .where((transaction) => transaction.status != TransactionStatus.completed)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      transactions = transactions.where((transaction) {
        return transaction.contactName.toLowerCase().contains(searchLower) ||
               (transaction.contactPhone?.contains(searchQuery) ?? false) ||
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
    final userRole = await _getUserRoleForTransaction(id, userId);
    
    if (userRole == null) {
      throw Exception('Transaction not found or access denied');
    }

    late DocumentSnapshot doc;
    
    if (userRole == UserTransactionRole.creator) {
      doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(id)
          .get();
      
      if (!doc.exists) {
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('finished_transactions')
            .doc(id)
            .get();
      }
    } else {
      doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('received_transactions')
          .doc(id)
          .get();
      
      if (!doc.exists) {
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('finished_transactions')
            .doc(id)
            .get();
      }
    }

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    return TransactionModel.fromJson({
      ...doc.data()! as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final updatedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(updatedAt: DateTime.now()),
    );

    final batch = _firestore.batch();

    final creatorDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(transaction.id);

    batch.update(creatorDocRef, updatedTransaction.toJson());

    if (transaction.recipientUserId != null) {
      final recipientDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('received_transactions')
          .doc(transaction.id);

      batch.update(recipientDocRef, updatedTransaction.toJson());

      final recipientTransactionDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('transactions')
          .doc(transaction.id);

      final flippedTransaction = await _createFlippedTransaction(updatedTransaction, transaction.recipientUserId!);
      batch.update(recipientTransactionDocRef, flippedTransaction.toJson());
    }

    await batch.commit();

    return updatedTransaction;
  }

  @override
  Future<void> deleteTransaction(String id, String userId) async {
    final transaction = await getTransactionById(id, userId);
    
    final batch = _firestore.batch();

    final creatorDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(id);

    batch.delete(creatorDocRef);

    if (transaction.recipientUserId != null) {
      final recipientDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('received_transactions')
          .doc(id);

      batch.delete(recipientDocRef);

      final recipientTransactionDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('transactions')
          .doc(id);

      batch.delete(recipientTransactionDocRef);
    }

    await batch.commit();
  }

  @override
  Future<TransactionModel> verifyTransaction(String id, String verifiedBy) async {
    final userRole = await _getUserRoleForTransaction(id, verifiedBy);
    
    if (userRole != UserTransactionRole.recipient) {
      throw Exception('Only transaction recipients can verify transactions');
    }

    final transaction = await getTransactionById(id, verifiedBy);
    
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

    final batch = _firestore.batch();

    final creatorDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(id);

    batch.update(creatorDocRef, updatedTransaction.toJson());

    final recipientDocRef = _firestore
        .collection('users')
        .doc(verifiedBy)
        .collection('received_transactions')
        .doc(id);

    batch.update(recipientDocRef, updatedTransaction.toJson());

    final recipientTransactionDocRef = _firestore
        .collection('users')
        .doc(verifiedBy)
        .collection('transactions')
        .doc(id);

    final flippedTransaction = await _createFlippedTransaction(updatedTransaction, verifiedBy);
    batch.update(recipientTransactionDocRef, flippedTransaction.toJson());

    await batch.commit();

    return updatedTransaction;
  }

  @override
  Future<TransactionModel> completeTransaction(String id, String userId, String userRole) async {
    final transaction = await getTransactionById(id, userId);
    
    final completedTransaction = TransactionModel.fromEntity(
      transaction.copyWith(
        status: TransactionStatus.completed,
        updatedAt: DateTime.now(),
      ),
    );

    await moveTransactionToFinished(completedTransaction);

    final batch = _firestore.batch();

    final creatorDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(id);

    batch.delete(creatorDocRef);

    if (transaction.recipientUserId != null) {
      final recipientDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('received_transactions')
          .doc(id);

      batch.delete(recipientDocRef);

      final recipientTransactionDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('transactions')
          .doc(id);

      batch.delete(recipientTransactionDocRef);
    }

    await batch.commit();

    return completedTransaction;
  }

  @override
  Future<void> moveTransactionToFinished(TransactionModel transaction) async {
    final batch = _firestore.batch();

    final creatorFinishedDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('finished_transactions')
        .doc(transaction.id);

    batch.set(creatorFinishedDocRef, transaction.toJson());

    if (transaction.recipientUserId != null) {
      final recipientFinishedDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('finished_transactions')
          .doc(transaction.id);

      final flippedTransaction = await _createFlippedTransaction(transaction, transaction.recipientUserId!);
      batch.set(recipientFinishedDocRef, flippedTransaction.toJson());
    }

    await batch.commit();
  }

  @override
  Future<List<TransactionModel>> getFinishedTransactions(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('finished_transactions')
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
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

      if (transaction.contactPhone == null) continue;

      final phone = transaction.contactPhone!;
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
  Future<TransactionStatsModel> getTransactionStats(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    final activeTransactions = querySnapshot.docs
        .map((doc) => TransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
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
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('received_transactions')
        .where('status', isEqualTo: TransactionStatus.pending.name)
        .where('verificationRequired', isEqualTo: true)
        .where('isVerified', isEqualTo: false)
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

    final batch = _firestore.batch();

    final creatorDocRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('transactions')
        .doc(transactionId);

    batch.update(creatorDocRef, updatedTransaction.toJson());

    if (transaction.recipientUserId != null) {
      final recipientDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('received_transactions')
          .doc(transactionId);

      batch.update(recipientDocRef, updatedTransaction.toJson());

      final recipientTransactionDocRef = _firestore
          .collection('users')
          .doc(transaction.recipientUserId)
          .collection('transactions')
          .doc(transactionId);

      final flippedTransaction = await _createFlippedTransaction(updatedTransaction, transaction.recipientUserId!);
      batch.update(recipientTransactionDocRef, flippedTransaction.toJson());
    }

    final completionRequestRef = _firestore
        .collection('users')
        .doc(transaction.createdBy)
        .collection('completion_requests')
        .doc(transactionId);

    batch.set(completionRequestRef, updatedTransaction.toJson());

    await batch.commit();

    return updatedTransaction;
  }

  @override
  Future<List<TransactionModel>> getCompletionRequests(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('completion_requests')
        .where('completionRequested', isEqualTo: true)
        .orderBy('completionRequestedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  Future<UserTransactionRole?> _getUserRoleForTransaction(String transactionId, String userId) async {
    final recipientDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('received_transactions')
        .doc(transactionId)
        .get();

    if (recipientDoc.exists && recipientDoc.data()?['recipientUserId'] == userId) {
      return UserTransactionRole.recipient;
    }

    final finishedDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('finished_transactions')
        .doc(transactionId)
        .get();

    if (finishedDoc.exists) {
      final data = finishedDoc.data();
      if (data?['createdBy'] == userId) {
        return UserTransactionRole.creator;
      } else if (data?['recipientUserId'] == userId) {
        return UserTransactionRole.recipient;
      }
    }

    return null;
  }

  Future<TransactionModel> _createFlippedTransaction(TransactionModel originalTransaction, String recipientUserId) async {
    final flippedType = originalTransaction.type == TransactionType.lending 
        ? TransactionType.borrowing 
        : TransactionType.lending;

    final creatorName = await _getOriginalCreatorName(originalTransaction);

    return TransactionModel.fromEntity(
      originalTransaction.copyWith(
        type: flippedType,
        createdBy: recipientUserId,
        contactPhone: null,
        contactName: creatorName,
        contactEmail: null,
        recipientUserId: originalTransaction.createdBy,
      ),
    );
  }

  Future<String> _getOriginalCreatorName(TransactionModel transaction) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(transaction.createdBy)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['displayName'] as String? ?? userData['email'] as String? ?? 'Transaction Partner';
      }
    } catch (e) {
      // Fallback to default name if unable to fetch user data
    }
    return 'Transaction Partner';
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

enum UserTransactionRole {
  creator,
  recipient,
}