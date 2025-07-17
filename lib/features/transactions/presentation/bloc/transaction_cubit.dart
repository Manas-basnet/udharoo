import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final CreateTransactionUseCase _createTransactionUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final UpdateTransactionStatusUseCase _updateTransactionStatusUseCase;
  final GetTransactionSummaryUseCase _getTransactionSummaryUseCase;
  final SearchTransactionsUseCase _searchTransactionsUseCase;

  TransactionCubit({
    required CreateTransactionUseCase createTransactionUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
    required UpdateTransactionStatusUseCase updateTransactionStatusUseCase,
    required GetTransactionSummaryUseCase getTransactionSummaryUseCase,
    required SearchTransactionsUseCase searchTransactionsUseCase,
  }) : _createTransactionUseCase = createTransactionUseCase,
       _getTransactionsUseCase = getTransactionsUseCase,
       _updateTransactionStatusUseCase = updateTransactionStatusUseCase,
       _getTransactionSummaryUseCase = getTransactionSummaryUseCase,
       _searchTransactionsUseCase = searchTransactionsUseCase,
       super(const TransactionInitial());

  Future<void> getTransactions({
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    emit(const TransactionLoading());

    final result = await _getTransactionsUseCase(
      userId: userId,
      type: type,
      status: status,
    );

    result.fold(
      onSuccess: (transactions) => emit(TransactionLoaded(transactions)),
      onFailure: (message, errorType) => emit(TransactionError(message, errorType)),
    );
  }

  Future<void> createTransaction({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required TransactionType type,
    String? description,
    DateTime? dueDate,
    bool requiresVerification = true,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhone,
    String? toUserPhone,
  }) async {
    emit(const TransactionCreating());

    final result = await _createTransactionUseCase(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      type: type,
      description: description,
      dueDate: dueDate,
      requiresVerification: requiresVerification,
      fromUserName: fromUserName,
      toUserName: toUserName,
      fromUserPhone: fromUserPhone,
      toUserPhone: toUserPhone,
    );

    result.fold(
      onSuccess: (transaction) => emit(TransactionCreated(transaction)),
      onFailure: (message, errorType) => emit(TransactionError(message, errorType)),
    );
  }

  Future<void> updateTransactionStatus(
    String transactionId, 
    TransactionStatus status,
  ) async {
    emit(const TransactionUpdating());

    final result = await _updateTransactionStatusUseCase(transactionId, status);

    result.fold(
      onSuccess: (transaction) => emit(TransactionUpdated(transaction)),
      onFailure: (message, errorType) => emit(TransactionError(message, errorType)),
    );
  }

  Future<void> getTransactionSummary(String userId) async {
    emit(const TransactionSummaryLoading());

    final result = await _getTransactionSummaryUseCase(userId);

    result.fold(
      onSuccess: (summary) => emit(TransactionSummaryLoaded(summary)),
      onFailure: (message, errorType) => emit(TransactionError(message, errorType)),
    );
  }

  Future<void> searchTransactions({
    required String userId,
    String? query,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(const TransactionSearching());

    final result = await _searchTransactionsUseCase(
      userId: userId,
      query: query,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      onSuccess: (transactions) => emit(TransactionSearchResults(transactions)),
      onFailure: (message, errorType) => emit(TransactionError(message, errorType)),
    );
  }

  void resetState() {
    emit(const TransactionInitial());
  }

  void resetError() {
    if (state is TransactionError) {
      emit(const TransactionInitial());
    }
  }
}