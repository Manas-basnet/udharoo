import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_finished_transactions_usecase.dart';

part 'finished_transactions_state.dart';

class FinishedTransactionsCubit extends Cubit<FinishedTransactionsState> {
  final GetFinishedTransactionsUseCase getFinishedTransactionsUseCase;

  FinishedTransactionsCubit({
    required this.getFinishedTransactionsUseCase,
  }) : super(const FinishedTransactionsInitial());

  Future<void> loadFinishedTransactions() async {
    emit(const FinishedTransactionsLoading());

    final result = await getFinishedTransactionsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) {
          final stats = _calculateStats(transactions);
          emit(FinishedTransactionsLoaded(transactions, stats));
        },
        onFailure: (message, type) => emit(FinishedTransactionsError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const FinishedTransactionsInitial());
    }
  }

  TransactionStats _calculateStats(List<Transaction> transactions) {
    double totalLending = 0;
    double totalBorrowing = 0;

    for (final transaction in transactions) {
      if (transaction.type.name == 'lending') {
        totalLending += transaction.amount;
      } else {
        totalBorrowing += transaction.amount;
      }
    }

    return TransactionStats(
      totalTransactions: transactions.length,
      pendingTransactions: 0,
      verifiedTransactions: 0,
      completedTransactions: transactions.length,
      totalLending: totalLending,
      totalBorrowing: totalBorrowing,
      netAmount: totalLending - totalBorrowing,
    );
  }
}