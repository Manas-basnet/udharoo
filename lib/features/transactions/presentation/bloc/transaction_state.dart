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
  final List<Transaction> lentTransactions;
  final List<Transaction> borrowedTransactions;
  final List<Transaction> pendingTransactions;
  final List<Transaction> completedTransactions;

  const TransactionLoaded({
    required this.transactions,
    required this.lentTransactions,
    required this.borrowedTransactions,
    required this.pendingTransactions,
    required this.completedTransactions,
  });

  @override
  List<Object?> get props => [transactions, lentTransactions, borrowedTransactions, pendingTransactions];
}

final class TransactionError extends TransactionState {
  final String message;
  final FailureType type;

  const TransactionError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}

final class TransactionActionLoading extends TransactionState {
  final String transactionId;
  final String action;

  const TransactionActionLoading(this.transactionId, this.action);

  @override
  List<Object?> get props => [transactionId, action];
}

final class TransactionActionSuccess extends TransactionState {
  final String message;

  const TransactionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

final class TransactionCreating extends TransactionState {
  const TransactionCreating();
}

final class TransactionCreated extends TransactionState {
  const TransactionCreated();
}