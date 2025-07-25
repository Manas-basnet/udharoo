part of 'finished_transactions_cubit.dart';

sealed class FinishedTransactionsState extends Equatable {
  const FinishedTransactionsState();

  @override
  List<Object?> get props => [];
}

final class FinishedTransactionsInitial extends FinishedTransactionsState {
  const FinishedTransactionsInitial();
}

final class FinishedTransactionsLoading extends FinishedTransactionsState {
  const FinishedTransactionsLoading();
}

final class FinishedTransactionsLoaded extends FinishedTransactionsState {
  final List<Transaction> transactions;
  final TransactionStats stats;

  const FinishedTransactionsLoaded(this.transactions, this.stats);

  @override
  List<Object?> get props => [transactions, stats];
}

final class FinishedTransactionsError extends FinishedTransactionsState {
  final String message;
  final FailureType type;

  const FinishedTransactionsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}