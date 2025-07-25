import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/refresh_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';

part 'transaction_list_state.dart';

class TransactionListCubit extends Cubit<TransactionListState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final RefreshTransactionsUseCase refreshTransactionsUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;

  List<Transaction> _allTransactions = [];
  Function(List<Transaction>)? _onTransactionsChanged;

  TransactionListCubit({
    required this.getTransactionsUseCase,
    required this.refreshTransactionsUseCase,
    required this.deleteTransactionUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const TransactionListInitial());

  void setTransactionsChangeListener(Function(List<Transaction>) listener) {
    _onTransactionsChanged = listener;
  }

  void removeTransactionsChangeListener() {
    _onTransactionsChanged = null;
  }

  Future<void> loadTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    bool refresh = false,
  }) async {
    if (refresh) {
      await refreshTransactions(
        status: status,
        type: type,
        searchQuery: searchQuery,
        limit: limit,
      );
      return;
    }

    if (state is! TransactionListLoaded) {
      emit(const TransactionListLoading());
    }

    final result = await getTransactionsUseCase(
      status: status,
      type: type,
      searchQuery: searchQuery,
      limit: limit,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) {
          _allTransactions = List.from(transactions);
          _notifyTransactionsChanged();
          
          emit(TransactionListLoaded(
            transactions: transactions,
            hasMore: false,
            lastDocumentId: null,
          ));
        },
        onFailure: (message, type) => emit(TransactionListError(message, type)),
      );
    }
  }

  Future<void> refreshTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
  }) async {
    final result = await refreshTransactionsUseCase(
      status: status,
      type: type,
      searchQuery: searchQuery,
      limit: limit,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) {
          _allTransactions = List.from(transactions);
          _notifyTransactionsChanged();
          
          loadTransactions(
            status: status,
            type: type,
            searchQuery: searchQuery,
            limit: limit,
          );
        },
        onFailure: (message, type) => emit(TransactionListError(message, type)),
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          _allTransactions.removeWhere((t) => t.id == id);
          _notifyTransactionsChanged();
          
          emit(TransactionListDeleted(id));
          _reloadCurrentTransactions();
        },
        onFailure: (message, type) => emit(TransactionListError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          _updateTransactionInList(transaction);
          _notifyTransactionsChanged();
          
          emit(TransactionListUpdated(transaction));
          _reloadCurrentTransactions();
        },
        onFailure: (message, type) => emit(TransactionListError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          _updateTransactionInList(transaction);
          _notifyTransactionsChanged();
          
          emit(TransactionListUpdated(transaction));
          _reloadCurrentTransactions();
        },
        onFailure: (message, type) => emit(TransactionListError(message, type)),
      );
    }
  }

  void _reloadCurrentTransactions() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        loadTransactions();
      }
    });
  }

  void updateFromCreation(Transaction transaction) {
    _allTransactions.insert(0, transaction);
    _notifyTransactionsChanged();
    
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final updatedTransactions = [transaction, ...currentState.transactions];
      emit(currentState.copyWith(transactions: updatedTransactions));
    } else {
      loadTransactions();
    }
  }

  void updateFromEdit(Transaction transaction) {
    _updateTransactionInList(transaction);
    _notifyTransactionsChanged();
    
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final updatedTransactions = currentState.transactions.map((t) {
        return t.id == transaction.id ? transaction : t;
      }).toList();
      emit(currentState.copyWith(transactions: updatedTransactions));
    } else {
      loadTransactions();
    }
  }

  void _updateTransactionInList(Transaction updatedTransaction) {
    final index = _allTransactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      _allTransactions[index] = updatedTransaction;
    }
  }

  void _notifyTransactionsChanged() {
    _onTransactionsChanged?.call(_allTransactions);
  }

  List<Transaction> get allTransactions => List.unmodifiable(_allTransactions);
}