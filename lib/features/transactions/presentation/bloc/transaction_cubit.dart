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
  final Set<String> _processingTransactionIds = <String>{};

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
          final lentTransactions = transactions.where((t) => t.isLent && (t.isVerified || t.isCompleted)).toList();
          final borrowedTransactions = transactions.where((t) => t.isBorrowed && (t.isVerified || t.isCompleted)).toList();
          final pendingTransactions = transactions.where((t) => t.isPending).toList();
          final completedTransactions = transactions.where((t) => t.isCompleted).toList();

          emit(TransactionLoaded(
            transactions: transactions,
            lentTransactions: lentTransactions,
            borrowedTransactions: borrowedTransactions,
            pendingTransactions: pendingTransactions,
            completedTransactions: completedTransactions,
            processingTransactionIds: Set.from(_processingTransactionIds),
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          final currentData = _getCurrentTransactionData();
          
          if (currentData.transactions.isNotEmpty) {
            emit(TransactionError(
              message: _getErrorMessage(error),
              type: FailureType.unknown,
              transactions: currentData.transactions,
              lentTransactions: currentData.lentTransactions,
              borrowedTransactions: currentData.borrowedTransactions,
              pendingTransactions: currentData.pendingTransactions,
              completedTransactions: currentData.completedTransactions,
              processingTransactionIds: Set.from(_processingTransactionIds),
            ));
          } else {
            emit(TransactionInitialError(
              _getErrorMessage(error),
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
        processingTransactionIds: Set.from(_processingTransactionIds),
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
          processingTransactionIds: Set.from(_processingTransactionIds),
        )),
        onFailure: (message, type) => emit(TransactionError(
          message: message,
          type: type,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
          processingTransactionIds: Set.from(_processingTransactionIds),
        )),
      );
    }
  }

  Future<void> verifyTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      actionType: 'verify',
      actionFunction: () => _verifyTransactionUseCase(transactionId),
      successMessage: 'Transaction verified successfully',
    );
  }

  Future<void> completeTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      actionType: 'complete',
      actionFunction: () => _completeTransactionUseCase(transactionId),
      successMessage: 'Transaction completed successfully',
    );
  }

  Future<void> rejectTransaction(String transactionId) async {
    await _performTransactionAction(
      transactionId: transactionId,
      actionType: 'reject',
      actionFunction: () => _rejectTransactionUseCase(transactionId),
      successMessage: 'Transaction rejected',
    );
  }

  Future<void> _performTransactionAction({
    required String transactionId,
    required String actionType,
    required Future<ApiResult<void>> Function() actionFunction,
    required String successMessage,
  }) async {
    _processingTransactionIds.add(transactionId);
    
    
    if (!isClosed && state is TransactionLoaded) {
      emit((state as TransactionLoaded).copyWithProcessingIds(Set.from(_processingTransactionIds)));
    }

    try {
      final result = await actionFunction();

      _processingTransactionIds.remove(transactionId);

      if (!isClosed) {
        final updatedData = _getCurrentTransactionData();
        
        result.fold(
          onSuccess: (_) => emit(TransactionActionSuccess(
            message: successMessage,
            actionType: actionType,
            transactions: updatedData.transactions,
            lentTransactions: updatedData.lentTransactions,
            borrowedTransactions: updatedData.borrowedTransactions,
            pendingTransactions: updatedData.pendingTransactions,
            completedTransactions: updatedData.completedTransactions,
            processingTransactionIds: Set.from(_processingTransactionIds),
          )),
          onFailure: (message, type) => emit(TransactionActionError(
            message: message,
            transactionId: transactionId,
            actionType: actionType,
            type: type,
            transactions: updatedData.transactions,
            lentTransactions: updatedData.lentTransactions,
            borrowedTransactions: updatedData.borrowedTransactions,
            pendingTransactions: updatedData.pendingTransactions,
            completedTransactions: updatedData.completedTransactions,
            processingTransactionIds: Set.from(_processingTransactionIds),
          )),
        );
      }
    } catch (error) {
      // Remove from processing set on error
      _processingTransactionIds.remove(transactionId);
      
      if (!isClosed) {
        final updatedData = _getCurrentTransactionData();
        
        emit(TransactionActionError(
          message: _getErrorMessage(error),
          transactionId: transactionId,
          actionType: actionType,
          type: FailureType.unknown,
          transactions: updatedData.transactions,
          lentTransactions: updatedData.lentTransactions,
          borrowedTransactions: updatedData.borrowedTransactions,
          pendingTransactions: updatedData.pendingTransactions,
          completedTransactions: updatedData.completedTransactions,
          processingTransactionIds: Set.from(_processingTransactionIds),
        ));
      }
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
          processingTransactionIds: Set.from(_processingTransactionIds),
        ));
      } else {
        loadTransactions();
      }
    }
  }

  void clearActionMessages() {
    if (!isClosed && 
        (state is TransactionActionSuccess || state is TransactionActionError)) {
      final currentData = _getCurrentTransactionData();
      
      emit(TransactionLoaded(
        transactions: currentData.transactions,
        lentTransactions: currentData.lentTransactions,
        borrowedTransactions: currentData.borrowedTransactions,
        pendingTransactions: currentData.pendingTransactions,
        completedTransactions: currentData.completedTransactions,
        processingTransactionIds: Set.from(_processingTransactionIds),
      ));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    return error?.toString() ?? 'An unexpected error occurred';
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    _processingTransactionIds.clear();
    return super.close();
  }
}