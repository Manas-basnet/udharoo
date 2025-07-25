part of 'transaction_stats_cubit.dart';

sealed class TransactionStatsState extends Equatable {
  const TransactionStatsState();

  @override
  List<Object?> get props => [];
}

final class TransactionStatsInitial extends TransactionStatsState {
  const TransactionStatsInitial();
}

final class TransactionStatsLoading extends TransactionStatsState {
  const TransactionStatsLoading();
}

final class TransactionStatsLoaded extends TransactionStatsState {
  final TransactionStats stats;

  const TransactionStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

final class TransactionStatsError extends TransactionStatsState {
  final String message;
  final FailureType type;

  const TransactionStatsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}