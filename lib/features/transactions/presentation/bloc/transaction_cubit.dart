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
        super(const TransactionInitial());

  void loadTransactions() {
    if (!isClosed) {
      emit(const TransactionLoading());
    }

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _getTransactionsUseCase().listen(
      (transactions) {
        if (!isClosed) {
          final lentTransactions = transactions.where((t) => t.isLent && (t.isVerified)).toList();
          final borrowedTransactions = transactions.where((t) => t.isBorrowed && (t.isVerified)).toList();
          final pendingTransactions = transactions.where((t) => t.isPending).toList();
          final completedTransactions = transactions.where((t) => t.isCompleted).toList();

          emit(TransactionLoaded(
            transactions: transactions,
            lentTransactions: lentTransactions,
            borrowedTransactions: borrowedTransactions,
            pendingTransactions: pendingTransactions,
            completedTransactions: completedTransactions,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(TransactionError(
            error.toString(),
            FailureType.unknown,
          ));
        }
      },
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
    if (!isClosed) {
      emit(const TransactionCreating());
    }

    final result = await _createTransactionUseCase(
      amount: amount,
      otherPartyUid: otherPartyUid,
      otherPartyName: otherPartyName,
      otherPartyPhone: otherPartyPhone,
      description: description,
      type: type,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const TransactionCreated()),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String transactionId) async {
    if (!isClosed) {
      emit(TransactionActionLoading(transactionId, 'verify'));
    }

    final result = await _verifyTransactionUseCase(transactionId);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const TransactionActionSuccess('Transaction verified successfully')),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String transactionId) async {
    if (!isClosed) {
      emit(TransactionActionLoading(transactionId, 'complete'));
    }

    final result = await _completeTransactionUseCase(transactionId);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const TransactionActionSuccess('Transaction completed successfully')),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> rejectTransaction(String transactionId) async {
    if (!isClosed) {
      emit(TransactionActionLoading(transactionId, 'reject'));
    }

    final result = await _rejectTransactionUseCase(transactionId);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const TransactionActionSuccess('Transaction rejected')),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  void resetActionState() {
    if (!isClosed && state is! TransactionLoaded) {
      loadTransactions();
    }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}