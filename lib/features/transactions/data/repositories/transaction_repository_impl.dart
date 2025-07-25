import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/data/models/qr_data_model.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';

class TransactionRepositoryImpl extends BaseRepository implements TransactionRepository {
  final TransactionRemoteDatasource _remoteDatasource;
  final TransactionLocalDatasource _localDatasource;
  final FirebaseAuth _firebaseAuth;

  TransactionRepositoryImpl({
    required TransactionRemoteDatasource remoteDatasource,
    required TransactionLocalDatasource localDatasource,
    required FirebaseAuth firebaseAuth,
    required super.networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource,
        _firebaseAuth = firebaseAuth;

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Future<ApiResult<Transaction>> createTransaction(Transaction transaction) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      String? recipientUserId;
      if (transaction.verificationRequired && transaction.contactPhone != null) {
        recipientUserId = await _remoteDatasource.verifyPhoneExists(transaction.contactPhone!);
        if (recipientUserId == null) {
          return ApiResult.failure('User with this phone number does not exist', FailureType.validation);
        }
      }

      final transactionWithRecipient = TransactionModel.fromEntity(
        transaction.copyWith(recipientUserId: recipientUserId),
      );
      
      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.createTransaction(transactionWithRecipient);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(_currentUserId!, TransactionModel.fromEntity(data));
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> getTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    String? lastDocumentId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      final cached = await _localDatasource.getCachedTransactions(_currentUserId!);
      List<TransactionModel> filtered = cached.where((t) => t.status != TransactionStatus.completed).toList();

      if (status != null) {
        filtered = filtered.where((t) => t.status == status).toList();
      }

      if (type != null) {
        filtered = filtered.where((t) => t.type == type).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        filtered = filtered.where((transaction) {
          return transaction.contactName.toLowerCase().contains(searchLower) ||
                 (transaction.contactPhone?.contains(searchQuery) ?? false) ||
                 (transaction.description?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      if (limit != null && filtered.length > limit) {
        filtered = filtered.take(limit).toList();
      }

      return ApiResult.success(filtered.cast<Transaction>());
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> refreshTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      final lastSyncTime = await _localDatasource.getLastSyncTimestamp(_currentUserId!);
      
      return handleRemoteCallFirst<List<Transaction>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getTransactions(
            userId: _currentUserId,
            status: status,
            type: type,
            searchQuery: searchQuery,
            limit: limit,
            lastSyncTime: lastSyncTime,
          );
          final activeTransactions = result.where((t) => t.status != TransactionStatus.completed).toList();
          return ApiResult.success(activeTransactions.cast<Transaction>());
        },
        saveLocalData: (data) async {
          if (data != null && data.isNotEmpty) {
            final transactionModels = data.map((t) => TransactionModel.fromEntity(t)).toList();
            
            if (lastSyncTime != null) {
              await _localDatasource.mergeTransactions(_currentUserId!, transactionModels);
            } else {
              await _localDatasource.cacheTransactions(_currentUserId!, transactionModels);
            }
            
            await _localDatasource.setLastSyncTimestamp(_currentUserId!, DateTime.now());
          } else if (lastSyncTime == null) {
            await _localDatasource.setLastSyncTimestamp(_currentUserId!, DateTime.now());
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<Transaction>> getTransactionById(String id) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleCacheCallFirst<Transaction>(
        localCall: () async {
          final cached = await _localDatasource.getCachedTransaction(_currentUserId!, id);
          if (cached != null) {
            return ApiResult.success(cached);
          }
          return ApiResult.failure('Transaction not found in cache', FailureType.noData);
        },
        remoteCall: () async {
          final result = await _remoteDatasource.getTransactionById(id, _currentUserId!);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(_currentUserId!, TransactionModel.fromEntity(data));
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<Transaction>> updateTransaction(Transaction transaction) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      String? recipientUserId = transaction.recipientUserId;
      if (transaction.verificationRequired && transaction.contactPhone != null && recipientUserId == null) {
        recipientUserId = await _remoteDatasource.verifyPhoneExists(transaction.contactPhone!);
        if (recipientUserId == null) {
          return ApiResult.failure('User with this phone number does not exist', FailureType.validation);
        }
      }

      final transactionModel = TransactionModel.fromEntity(
        transaction.copyWith(recipientUserId: recipientUserId),
      );
      
      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.updateTransaction(transactionModel);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(_currentUserId!, TransactionModel.fromEntity(data));
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<void>> deleteTransaction(String id) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<void>(
        remoteCall: () async {
          await _remoteDatasource.deleteTransaction(id, _currentUserId!);
          return ApiResult.success(null);
        },
        saveLocalData: (data) async {
          await _localDatasource.removeCachedTransaction(_currentUserId!, id);
        },
      );
    });
  }

  @override
  Future<ApiResult<Transaction>> verifyTransaction(String id, String verifiedBy) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.verifyTransaction(id, verifiedBy);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(_currentUserId!, TransactionModel.fromEntity(data));
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<Transaction>> completeTransaction(String id) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final transaction = await _remoteDatasource.getTransactionById(id, _currentUserId!);
          
          String userRole;
          if (transaction.createdBy == _currentUserId) {
            userRole = 'creator';
          } else if (transaction.recipientUserId == _currentUserId) {
            userRole = 'recipient';
          } else {
            throw Exception('User not authorized to complete this transaction');
          }

          if (transaction.type == TransactionType.lending && userRole != 'creator') {
            throw Exception('Only lender can complete lending transactions');
          }

          if (transaction.type == TransactionType.borrowing && userRole != 'recipient') {
            throw Exception('Only borrower can complete borrowing transactions');
          }

          if (transaction.verificationRequired && !transaction.isVerified) {
            throw Exception('Transaction must be verified before completion');
          }

          final result = await _remoteDatasource.completeTransaction(id, _currentUserId!, userRole);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.removeCachedTransaction(_currentUserId!, id);
          }
        },
      );
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> getFinishedTransactions() async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<List<Transaction>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getFinishedTransactions(_currentUserId!);
          return ApiResult.success(result.cast<Transaction>());
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<List<TransactionContact>>> getTransactionContacts() async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<List<TransactionContact>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getTransactionContacts(_currentUserId!);
          return ApiResult.success(result.cast<TransactionContact>());
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> getContactTransactions(String contactPhone) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<List<Transaction>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getContactTransactions(_currentUserId!, contactPhone);
          return ApiResult.success(result.cast<Transaction>());
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<QRData>> generateQRCode({
    required String userPhone,
    required String userName,
    String? userEmail,
    required bool verificationRequired,
    String? customMessage,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final qrData = QRDataModel(
        userPhone: userPhone,
        userName: userName,
        userEmail: userEmail,
        verificationRequired: verificationRequired,
        generatedAt: DateTime.now(),
        customMessage: customMessage,
      );

      return ApiResult.success(qrData);
    });
  }

  @override
  Future<ApiResult<QRData>> parseQRCode(String qrCodeData) async {
    return ExceptionHandler.handleExceptions(() async {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(qrCodeData);
        
        if (!jsonData.containsKey('userPhone') || 
            !jsonData.containsKey('userName') ||
            !jsonData.containsKey('verificationRequired') ||
            !jsonData.containsKey('generatedAt')) {
          return ApiResult.failure('Invalid QR code format', FailureType.validation);
        }

        final qrData = QRDataModel.fromJson(jsonData);
        return ApiResult.success(qrData);
      } catch (e) {
        return ApiResult.failure('Failed to parse QR code', FailureType.validation);
      }
    });
  }

  @override
  Future<ApiResult<bool>> getGlobalVerificationSetting() async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<bool>(
        remoteCall: () async {
          final result = await _remoteDatasource.getGlobalVerificationSetting(_currentUserId!);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<void>> setGlobalVerificationSetting(bool enabled) async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<void>(
        remoteCall: () async {
          await _remoteDatasource.setGlobalVerificationSetting(_currentUserId!, enabled);
          return ApiResult.success(null);
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> getTransactionStats() async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      final cached = await _localDatasource.getCachedTransactions(_currentUserId!);
      final activeTransactions = cached.where((t) => t.status != TransactionStatus.completed).toList();
      
      if (activeTransactions.isNotEmpty) {
        final stats = _calculateStatsFromTransactions(activeTransactions);
        return ApiResult.success(stats);
      }

      return handleRemoteCallFirst<Map<String, dynamic>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getTransactionStats(_currentUserId!);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<String?>> verifyPhoneExists(String phoneNumber) async {
    return ExceptionHandler.handleExceptions(() async {
      return handleRemoteCallFirst<String?>(
        remoteCall: () async {
          final result = await _remoteDatasource.verifyPhoneExists(phoneNumber);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> getReceivedTransactionRequests() async {
    return ExceptionHandler.handleExceptions(() async {
      if (_currentUserId == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }

      return handleRemoteCallFirst<List<Transaction>>(
        remoteCall: () async {
          final result = await _remoteDatasource.getReceivedTransactionRequests(_currentUserId!);
          return ApiResult.success(result.cast<Transaction>());
        },
        saveLocalData: (data) async {
        },
      );
    });
  }

  Map<String, dynamic> _calculateStatsFromTransactions(List<TransactionModel> transactions) {
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

    return {
      'totalTransactions': totalTransactions,
      'pendingTransactions': pendingTransactions,
      'verifiedTransactions': verifiedTransactions,
      'completedTransactions': completedTransactions,
      'totalLending': totalLending,
      'totalBorrowing': totalBorrowing,
    };
  }
}