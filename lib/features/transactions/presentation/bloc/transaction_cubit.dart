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

  ({
    List<Transaction> transactions,
    List<Transaction> lentTransactions,
    List<Transaction> borrowedTransactions,
    List<Transaction> pendingTransactions,
    List<Transaction> completedTransactions,
  }) _getCurrentTransactionData() {
    if (state is TransactionBaseState) {
      final baseState = state as TransactionBaseState;
      return (
        transactions: baseState.transactions,
        lentTransactions: baseState.lentTransactions,
        borrowedTransactions: baseState.borrowedTransactions,
        pendingTransactions: baseState.pendingTransactions,
        completedTransactions: baseState.completedTransactions,
      );
    }
    return (
      transactions: <Transaction>[],
      lentTransactions: <Transaction>[],
      borrowedTransactions: <Transaction>[],
      pendingTransactions: <Transaction>[],
      completedTransactions: <Transaction>[],
    );
  }

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
          final currentData = _getCurrentTransactionData();
          
          // If we have existing data, preserve it with error state
          if (currentData.transactions.isNotEmpty) {
            emit(TransactionError(
              message: error.toString(),
              type: FailureType.unknown,
              transactions: currentData.transactions,
              lentTransactions: currentData.lentTransactions,
              borrowedTransactions: currentData.borrowedTransactions,
              pendingTransactions: currentData.pendingTransactions,
              completedTransactions: currentData.completedTransactions,
            ));
          } else {
            // No existing data, use initial error state
            emit(TransactionInitialError(
              error.toString(),
              FailureType.unknown,
            ));
          }
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
    final currentData = _getCurrentTransactionData();
    
    if (!isClosed) {
      emit(TransactionCreating(
        transactions: currentData.transactions,
        lentTransactions: currentData.lentTransactions,
        borrowedTransactions: currentData.borrowedTransactions,
        pendingTransactions: currentData.pendingTransactions,
        completedTransactions: currentData.completedTransactions,
      ));
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
      final updatedData = _getCurrentTransactionData();
      
      result.fold(
        onSuccess: (_) => emit(TransactionCreated(
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
        onFailure: (message, type) => emit(TransactionError(
          message: message,
          type: type,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
      );
    }
  }

  Future<void> verifyTransaction(String transactionId) async {
    final currentData = _getCurrentTransactionData();
    
    if (!isClosed) {
      emit(TransactionActionLoading(
        transactionId: transactionId,
        action: 'verify',
        transactions: currentData.transactions,
        lentTransactions: currentData.lentTransactions,
        borrowedTransactions: currentData.borrowedTransactions,
        pendingTransactions: currentData.pendingTransactions,
        completedTransactions: currentData.completedTransactions,
      ));
    }

    final result = await _verifyTransactionUseCase(transactionId);

    if (!isClosed) {
      final updatedData = _getCurrentTransactionData();
      
      result.fold(
        onSuccess: (_) => emit(TransactionActionSuccess(
          message: 'Transaction verified successfully',
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
        onFailure: (message, type) => emit(TransactionError(
          message: message,
          type: type,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
      );
    }
  }

  Future<void> completeTransaction(String transactionId) async {

    final result = await _completeTransactionUseCase(transactionId);

    if (!isClosed) {
      final updatedData = _getCurrentTransactionData();
      
      result.fold(
        onSuccess: (_) => emit(TransactionActionSuccess(
          message: 'Transaction completed successfully',
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
        onFailure: (message, type) => emit(TransactionError(
          message: message,
          type: type,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
      );
    }
  }

  Future<void> rejectTransaction(String transactionId) async {
    final currentData = _getCurrentTransactionData();
    
    if (!isClosed) {
      emit(TransactionActionLoading(
        transactionId: transactionId,
        action: 'reject',
        transactions: currentData.transactions,
        lentTransactions: currentData.lentTransactions,
        borrowedTransactions: currentData.borrowedTransactions,
        pendingTransactions: currentData.pendingTransactions,
        completedTransactions: currentData.completedTransactions,
      ));
    }

    final result = await _rejectTransactionUseCase(transactionId);

    if (!isClosed) {
      final updatedData = _getCurrentTransactionData();
      
      result.fold(
        onSuccess: (_) => emit(TransactionActionSuccess(
          message: 'Transaction rejected',
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
        onFailure: (message, type) => emit(TransactionError(
          message: message,
          type: type,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
        )),
      );
    }
  }

  void resetActionState() {
    if (!isClosed && state is! TransactionLoaded) {
      final currentData = _getCurrentTransactionData();
      
      if (currentData.transactions.isNotEmpty) {
        emit(TransactionLoaded(
          transactions: currentData.transactions,
          lentTransactions: currentData.lentTransactions,
          borrowedTransactions: currentData.borrowedTransactions,
          pendingTransactions: currentData.pendingTransactions,
          completedTransactions: currentData.completedTransactions,
        ));
      } else {
        loadTransactions();
      }
    }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}