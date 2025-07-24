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

      final transactionModel = TransactionModel.fromEntity(transaction);
      
      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.createTransaction(transactionModel);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(TransactionModel.fromEntity(data));
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

      final cached = await _localDatasource.getCachedTransactions();
      List<TransactionModel> filtered = cached;

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
                 transaction.contactPhone.contains(searchQuery) ||
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

      final lastSyncTime = await _localDatasource.getLastSyncTimestamp();
      
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
          return ApiResult.success(result.cast<Transaction>());
        },
        saveLocalData: (data) async {
          if (data != null && data.isNotEmpty) {
            final transactionModels = data.map((t) => TransactionModel.fromEntity(t)).toList();
            
            if (lastSyncTime != null) {
              await _localDatasource.mergeTransactions(transactionModels);
            } else {
              await _localDatasource.cacheTransactions(transactionModels);
            }
            
            await _localDatasource.setLastSyncTimestamp(DateTime.now());
          } else if (lastSyncTime == null) {
            await _localDatasource.setLastSyncTimestamp(DateTime.now());
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
          final cached = await _localDatasource.getCachedTransaction(id);
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
            await _localDatasource.cacheTransaction(TransactionModel.fromEntity(data));
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

      final transactionModel = TransactionModel.fromEntity(transaction);
      
      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.updateTransaction(transactionModel);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(TransactionModel.fromEntity(data));
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
          await _localDatasource.removeCachedTransaction(id);
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

      final transaction = await _remoteDatasource.getTransactionById(id, _currentUserId!);
      final updatedTransaction = TransactionModel.fromEntity(
        transaction.copyWith(
          isVerified: true,
          verifiedBy: verifiedBy,
          status: TransactionStatus.verified,
          updatedAt: DateTime.now(),
        ),
      );

      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.updateTransaction(updatedTransaction);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(TransactionModel.fromEntity(data));
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

      final transaction = await _remoteDatasource.getTransactionById(id, _currentUserId!);
      final updatedTransaction = TransactionModel.fromEntity(
        transaction.copyWith(
          status: TransactionStatus.completed,
          updatedAt: DateTime.now(),
        ),
      );

      return handleRemoteCallFirst<Transaction>(
        remoteCall: () async {
          final result = await _remoteDatasource.updateTransaction(updatedTransaction);
          return ApiResult.success(result);
        },
        saveLocalData: (data) async {
          if (data != null) {
            await _localDatasource.cacheTransaction(TransactionModel.fromEntity(data));
          }
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
}