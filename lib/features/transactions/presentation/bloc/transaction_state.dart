part of 'transaction_cubit.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

final class TransactionCreating extends TransactionState {
  const TransactionCreating();
}

final class TransactionCreated extends TransactionState {
  final Transaction transaction;

  const TransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionUpdating extends TransactionState {
  const TransactionUpdating();
}

final class TransactionUpdated extends TransactionState {
  final Transaction transaction;

  const TransactionUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionSummaryLoading extends TransactionState {
  const TransactionSummaryLoading();
}

final class TransactionSummaryLoaded extends TransactionState {
  final Map<String, double> summary;

  const TransactionSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

final class TransactionSearching extends TransactionState {
  const TransactionSearching();
}

final class TransactionSearchResults extends TransactionState {
  final List<Transaction> transactions;

  const TransactionSearchResults(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

final class TransactionError extends TransactionState {
  final String message;
  final FailureType type;

  const TransactionError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}