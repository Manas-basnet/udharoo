import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/events/event_bus.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/events/transaction_events.dart';
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
  late StreamSubscription _eventSubscription;

  TransactionListCubit({
    required this.getTransactionsUseCase,
    required this.refreshTransactionsUseCase,
    required this.deleteTransactionUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const TransactionListInitial()) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = EventBus().on<TransactionEvent>().listen(_handleEvent);
  }

  void _handleEvent(TransactionEvent event) {
    if (isClosed) return;

    switch (event) {
      case TransactionCreatedEvent():
        _handleTransactionCreated(event.transaction);
      case TransactionUpdatedEvent():
        _handleTransactionUpdated(event.transaction);
      case TransactionDeletedEvent():
        _handleTransactionDeleted(event.transactionId);
      case TransactionVerifiedEvent():
        _handleTransactionUpdated(event.transaction);
      case TransactionCompletedEvent():
        _handleTransactionCompleted(event.transaction);
      default:
        break;
    }
  }

  void _handleTransactionCreated(Transaction transaction) {
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

  void _handleTransactionUpdated(Transaction transaction) {
    final index = _allTransactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _allTransactions[index] = transaction;
      _notifyTransactionsChanged();
      
      if (state is TransactionListLoaded) {
        final currentState = state as TransactionListLoaded;
        final updatedTransactions = currentState.transactions.map((t) {
          return t.id == transaction.id ? transaction : t;
        }).toList();
        emit(currentState.copyWith(transactions: updatedTransactions));
      }
    }
  }

  void _handleTransactionDeleted(String transactionId) {
    _allTransactions.removeWhere((t) => t.id == transactionId);
    _notifyTransactionsChanged();
    
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final updatedTransactions = currentState.transactions
          .where((t) => t.id != transactionId)
          .toList();
      emit(currentState.copyWith(transactions: updatedTransactions));
    }
  }

  void _handleTransactionCompleted(Transaction transaction) {
    _allTransactions.removeWhere((t) => t.id == transaction.id);
    _notifyTransactionsChanged();
    
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final updatedTransactions = currentState.transactions
          .where((t) => t.id != transaction.id)
          .toList();
      emit(currentState.copyWith(transactions: updatedTransactions));
    }
  }

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
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final originalTransactions = List<Transaction>.from(currentState.transactions);
      
      final optimisticTransactions = originalTransactions
          .where((t) => t.id != id)
          .toList();
      emit(currentState.copyWith(transactions: optimisticTransactions));
    }

    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          EventBus().emit(TransactionDeletedEvent(id));
          emit(TransactionListDeleted(id));
        },
        onFailure: (message, type) {
          _revertOptimisticUpdate();
          emit(TransactionListError(message, type));
        },
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          EventBus().emit(TransactionVerifiedEvent(transaction));
          emit(TransactionListUpdated(transaction));
        },
        onFailure: (message, type) {
          if (message.contains('Only transaction recipients can verify')) {
            emit(TransactionListError('You can only verify transactions where you are the recipient', type));
          } else {
            emit(TransactionListError(message, type));
          }
        },
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          EventBus().emit(TransactionCompletedEvent(transaction));
          emit(TransactionListUpdated(transaction));
        },
        onFailure: (message, type) {
          if (message.contains('Only lender can complete lending transactions')) {
            emit(TransactionListError('Only the lender can complete lending transactions', type));
          } else if (message.contains('Only borrower can complete borrowing transactions')) {
            emit(TransactionListError('Only the borrower can complete borrowing transactions', type));
          } else if (message.contains('Transaction must be verified before completion')) {
            emit(TransactionListError('This transaction must be verified before it can be completed', type));
          } else {
            emit(TransactionListError(message, type));
          }
        },
      );
    }
  }

  void _revertOptimisticUpdate() {
    loadTransactions();
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
    EventBus().emit(TransactionStatsChangedEvent(_allTransactions));
  }

  List<Transaction> get allTransactions => List.unmodifiable(_allTransactions);

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}