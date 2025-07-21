import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl extends BaseRepository implements TransactionRepository {
  final TransactionRemoteDatasource _remoteDatasource;
  final TransactionLocalDatasource _localDatasource;

  TransactionRepositoryImpl({
    required TransactionRemoteDatasource remoteDatasource,
    required TransactionLocalDatasource localDatasource,
    required super.networkInfo,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  @override
  Future<ApiResult<List<Transaction>>> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    if (userId == null) {
      return ApiResult.failure(
        'User ID is required to fetch transactions',
        FailureType.validation,
      );
    }

    return handleRemoteCallFirst<List<Transaction>>(
      localCall: () async {
        final cachedTransactions = await _localDatasource.getCachedTransactions(userId);
        List<Transaction> filtered = cachedTransactions.cast<Transaction>();

        if (type != null) {
          filtered = filtered.where((t) => t.type == type).toList();
        }

        if (status != null) {
          filtered = filtered.where((t) => t.status == status).toList();
        }

        return ApiResult.success(filtered);
      },
      remoteCall: () async {
        final transactions = await _remoteDatasource.getTransactions(
          userId: userId,
          type: type,
          status: status,
        );
        return ApiResult.success(transactions.cast<Transaction>());
      },
      saveLocalData: (transactions) async {
        if (transactions != null) {
          final transactionModels = transactions
              .map((t) => TransactionModel.fromEntity(t))
              .toList();
          await _localDatasource.cacheTransactions(userId, transactionModels);
        }
      },
    );
  }

  @override
  Future<ApiResult<Transaction>> getTransactionById(String transactionId) async {
    return handleCacheCallFirst<Transaction>(
      localCall: () async {
        final cachedTransaction = await _localDatasource.getCachedTransaction(transactionId);
        if (cachedTransaction != null) {
          return ApiResult.success(cachedTransaction);
        }
        return ApiResult.failure('Transaction not found in cache', FailureType.notFound);
      },
      remoteCall: () async {
        final transaction = await _remoteDatasource.getTransactionById(transactionId);
        return ApiResult.success(transaction);
      },
      saveLocalData: (transaction) async {
        if (transaction != null) {
          final transactionModel = TransactionModel.fromEntity(transaction);
          await _localDatasource.cacheTransaction(transactionModel);
        }
      },
    );
  }

  @override
  Future<ApiResult<Transaction>> createTransaction(Transaction transaction) async {
    return handleRemoteCallFirst<Transaction>(
      remoteCall: () async {
        final transactionModel = TransactionModel.fromEntity(transaction);
        final createdTransaction = await _remoteDatasource.createTransaction(transactionModel);
        return ApiResult.success(createdTransaction);
      },
      saveLocalData: (createdTransaction) async {
        if (createdTransaction != null) {
          final transactionModel = TransactionModel.fromEntity(createdTransaction);
          await _localDatasource.cacheTransaction(transactionModel);
          
          await _localDatasource.cacheTransactions(
            createdTransaction.fromUserId, 
            [transactionModel]
          );
          
          if (createdTransaction.fromUserId != createdTransaction.toUserId) {
            await _localDatasource.cacheTransactions(
              createdTransaction.toUserId, 
              [transactionModel]
            );
          }
        }
      },
    );
  }

  @override
  Future<ApiResult<Transaction>> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  ) async {
    return handleRemoteCallFirst<Transaction>(
      remoteCall: () async {
        final updatedTransaction = await _remoteDatasource.updateTransactionStatus(
          transactionId, 
          status,
        );
        return ApiResult.success(updatedTransaction);
      },
      saveLocalData: (updatedTransaction) async {
        if (updatedTransaction != null) {
          final transactionModel = TransactionModel.fromEntity(updatedTransaction);
          await _localDatasource.cacheTransaction(transactionModel);
        }
      },
    );
  }

  @override
  Future<ApiResult<void>> deleteTransaction(String transactionId) async {
    return handleRemoteCallFirst<void>(
      remoteCall: () async {
        await _remoteDatasource.deleteTransaction(transactionId);
        return ApiResult.success(null);
      },
      saveLocalData: (_) async {
        // Note: We would need additional implementation to remove from cache
        // This would require knowing which user's cache to clear from
      },
    );
  }

  @override
  Stream<List<Transaction>> watchTransactions(String userId) {
    return _remoteDatasource.watchTransactions(userId)
        .map((transactions) => transactions.cast<Transaction>());
  }

  @override
  Future<ApiResult<List<Transaction>>> searchTransactions({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return handleRemoteCallFirst<List<Transaction>>(
      remoteCall: () async {
        final transactions = await _remoteDatasource.searchTransactions(
          userId: userId,
          query: query,
          type: type,
          status: status,
          startDate: startDate,
          endDate: endDate,
        );
        return ApiResult.success(transactions.cast<Transaction>());
      },
      saveLocalData: (transactions) async {
        if (transactions != null) {
          final transactionModels = transactions
              .map((t) => TransactionModel.fromEntity(t))
              .toList();
          await _localDatasource.cacheTransactions(userId, transactionModels);
        }
      },
    );
  }

  @override
  Future<ApiResult<Map<String, double>>> getTransactionSummary(String userId) async {
    return handleRemoteCallFirst<Map<String, double>>(
      remoteCall: () async {
        final summary = await _remoteDatasource.getTransactionSummary(userId);
        return ApiResult.success(summary);
      },
      saveLocalData: (_) async {
        // Summary doesn't need caching
      },
    );
  }
}