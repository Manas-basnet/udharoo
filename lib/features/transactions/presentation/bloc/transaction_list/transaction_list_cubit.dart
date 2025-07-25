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

  TransactionListCubit({
    required this.getTransactionsUseCase,
    required this.refreshTransactionsUseCase,
    required this.deleteTransactionUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const TransactionListInitial());

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
    if (state is TransactionListLoaded) {
      final currentState = state as TransactionListLoaded;
      final updatedTransactions = [transaction, ...currentState.transactions];
      emit(currentState.copyWith(transactions: updatedTransactions));
    } else {
      loadTransactions();
    }
  }

  void updateFromEdit(Transaction transaction) {
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
}