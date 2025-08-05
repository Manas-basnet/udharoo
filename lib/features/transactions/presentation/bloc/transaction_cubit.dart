import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/reject_transaction_usecase.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final CreateTransactionUseCase _createTransactionUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final VerifyTransactionUseCase _verifyTransactionUseCase;
  final CompleteTransactionUseCase _completeTransactionUseCase;
  final RejectTransactionUseCase _rejectTransactionUseCase;

  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  TransactionCubit({
    required CreateTransactionUseCase createTransactionUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
    required VerifyTransactionUseCase verifyTransactionUseCase,
    required CompleteTransactionUseCase completeTransactionUseCase,
    required RejectTransactionUseCase rejectTransactionUseCase,
  })  : _createTransactionUseCase = createTransactionUseCase,
        _getTransactionsUseCase = getTransactionsUseCase,
        _verifyTransactionUseCase = verifyTransactionUseCase,
        _completeTransactionUseCase = completeTransactionUseCase,
        _rejectTransactionUseCase = rejectTransactionUseCase,
        super(TransactionState.initial());

  void loadTransactions() {
    if (!isClosed && !state.isInitialized) {
      emit(state.copyWith(isInitialLoading: true));
    }

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _getTransactionsUseCase().listen(
      _handleTransactionUpdate,
      onError: _handleStreamError,
    );
  }

  void _handleTransactionUpdate(List<Transaction> transactions) {
    if (isClosed) return;

    final categorizedTransactions = _categorizeTransactions(transactions);

    emit(state.copyWith(
      transactions: transactions,
      lentTransactions: categorizedTransactions.lent,
      borrowedTransactions: categorizedTransactions.borrowed,
      activeLentTransactions: categorizedTransactions.activeLent,
      activeBorrowedTransactions: categorizedTransactions.activeBorrowed,
      pendingTransactions: categorizedTransactions.pending,
      completedTransactions: categorizedTransactions.completed,
      isInitialLoading: false,
      isInitialized: true,
    ).clearError());
  }

  void _handleStreamError(dynamic error) {
    if (isClosed) return;

    final errorMessage = _getErrorMessage(error);
    
    emit(state.copyWith(
      isInitialLoading: false,
      errorMessage: errorMessage,
    ));
  }

  ({
    List<Transaction> lent,
    List<Transaction> borrowed,
    List<Transaction> activeLent,
    List<Transaction> activeBorrowed,
    List<Transaction> pending,
    List<Transaction> completed,
  }) _categorizeTransactions(List<Transaction> transactions) {
    final lent = transactions.where((t) => t.isLent && (t.isVerified || t.isCompleted)).toList();
    final borrowed = transactions.where((t) => t.isBorrowed && (t.isVerified || t.isCompleted)).toList();
    final activeLent = transactions.where((t) => t.isLent && t.isVerified).toList();
    final activeBorrowed = transactions.where((t) => t.isBorrowed && t.isVerified).toList();
    final pending = transactions.where((t) => t.isPending).toList();
    final completed = transactions.where((t) => t.isCompleted).toList();

    return (
      lent: lent,
      borrowed: borrowed,
      activeLent: activeLent,
      activeBorrowed: activeBorrowed,
      pending: pending,
      completed: completed,
    );
  }

  Future<void> createTransaction({
    required double amount,
    required String otherPartyUid,
    required String otherPartyName,
    required String otherPartyPhone,
    required String description,
    required TransactionType type,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(isCreatingTransaction: true).clearMessages());

    try {
      final result = await _createTransactionUseCase(
        amount: amount,
        otherPartyUid: otherPartyUid,
        otherPartyName: otherPartyName,
        otherPartyPhone: otherPartyPhone,
        description: description,
        type: type,
      );

      if (isClosed) return;

      emit(state.copyWith(isCreatingTransaction: false));

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(successMessage: 'Transaction created successfully'));
        },
        onFailure: (message, _) => emit(state.copyWith(errorMessage: message)),
      );
    } catch (error) {
      if (isClosed) return;
      
      emit(state.copyWith(
        isCreatingTransaction: false,
        errorMessage: _getErrorMessage(error),
      ));
    }
  }

  Future<void> verifyTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      action: () => _verifyTransactionUseCase(transactionId),
      successMessage: 'Transaction verified successfully',
    );
  }

  Future<void> completeTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      action: () => _completeTransactionUseCase(transactionId),
      successMessage: 'Transaction completed successfully',
    );
  }

  Future<void> rejectTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      action: () => _rejectTransactionUseCase(transactionId),
      successMessage: 'Transaction rejected',
    );
  }

  Future<void> _performTransactionAction({
    required String transactionId,
    required Future<ApiResult<void>> Function() action,
    required String successMessage,
  }) async {
    if (isClosed) return;

    final updatedProcessingIds = Set<String>.from(state.processingTransactionIds)
      ..add(transactionId);

    emit(state.copyWith(processingTransactionIds: updatedProcessingIds).clearMessages());

    try {
      final result = await action();

      if (isClosed) return;

      final finalProcessingIds = Set<String>.from(state.processingTransactionIds)
        ..remove(transactionId);

      emit(state.copyWith(processingTransactionIds: finalProcessingIds));

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(successMessage: successMessage));
        },
        onFailure: (message, _) => emit(state.copyWith(errorMessage: message)),
      );
    } catch (error) {
      if (isClosed) return;

      final finalProcessingIds = Set<String>.from(state.processingTransactionIds)
        ..remove(transactionId);

      emit(state.copyWith(
        processingTransactionIds: finalProcessingIds,
        errorMessage: _getErrorMessage(error),
      ));
    }
  }

  void clearMessages() {
    if (isClosed) return;
    emit(state.clearMessages());
  }

  void clearError() {
    if (isClosed) return;
    emit(state.clearError());
  }

  void clearSuccess() {
    if (isClosed) return;
    emit(state.clearSuccess());
  }

  void resetActionState() {
    clearMessages();
  }

  void clearActionMessages() {
    clearMessages();
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    return error?.toString() ?? 'An unexpected error occurred';
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}