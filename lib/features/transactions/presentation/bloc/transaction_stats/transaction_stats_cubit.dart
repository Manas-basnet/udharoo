import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/events/event_bus.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/events/transaction_events.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_stats_usecase.dart';

part 'transaction_stats_state.dart';

class TransactionStatsCubit extends Cubit<TransactionStatsState> {
  final GetTransactionStatsUseCase getTransactionStatsUseCase;
  late StreamSubscription _eventSubscription;

  TransactionStatsCubit({
    required this.getTransactionStatsUseCase,
  }) : super(const TransactionStatsInitial()) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = EventBus().on<TransactionStatsChangedEvent>().listen(_handleStatsChanged);
  }

  void _handleStatsChanged(TransactionStatsChangedEvent event) {
    if (isClosed) return;
    
    final stats = _calculateStatsFromTransactions(event.allTransactions);
    emit(TransactionStatsLoaded(stats));
  }

  Future<void> loadTransactionStats([List<Transaction>? transactionData]) async {
    emit(const TransactionStatsLoading());

    if (transactionData != null && transactionData.isNotEmpty) {
      final stats = _calculateStatsFromTransactions(transactionData);
      emit(TransactionStatsLoaded(stats));
      return;
    }

    final result = await getTransactionStatsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (stats) => emit(TransactionStatsLoaded(stats)),
        onFailure: (message, type) => emit(TransactionStatsError(message, type)),
      );
    }
  }

  void updateStatsFromTransactions(List<Transaction> transactions) {
    final stats = _calculateStatsFromTransactions(transactions);
    emit(TransactionStatsLoaded(stats));
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionStatsInitial());
    }
  }

  TransactionStats _calculateStatsFromTransactions(List<Transaction> transactions) {
    int totalTransactions = 0;
    int pendingTransactions = 0;
    int verifiedTransactions = 0;
    int completedTransactions = 0;
    double totalLending = 0;
    double totalBorrowing = 0;

    for (final transaction in transactions) {
      switch (transaction.status) {
        case TransactionStatus.pending:
          totalTransactions++;
          pendingTransactions++;
          if (transaction.type == TransactionType.lending) {
            totalLending += transaction.amount;
          } else {
            totalBorrowing += transaction.amount;
          }
          break;
        case TransactionStatus.verified:
          totalTransactions++;
          verifiedTransactions++;
          if (transaction.type == TransactionType.lending) {
            totalLending += transaction.amount;
          } else {
            totalBorrowing += transaction.amount;
          }
          break;
        case TransactionStatus.completed:
          completedTransactions++;
          break;
        case TransactionStatus.cancelled:
          break;
      }
    }

    return TransactionStats(
      totalTransactions: totalTransactions,
      pendingTransactions: pendingTransactions,
      verifiedTransactions: verifiedTransactions,
      completedTransactions: completedTransactions,
      totalLending: totalLending,
      totalBorrowing: totalBorrowing,
      netAmount: totalLending - totalBorrowing,
    );
  }

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}