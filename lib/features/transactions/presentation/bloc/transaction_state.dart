part of 'transaction_cubit.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

abstract class TransactionBaseState extends TransactionState {
  final List<Transaction> transactions;
  final List<Transaction> lentTransactions;
  final List<Transaction> borrowedTransactions;
  final List<Transaction> pendingTransactions;
  final List<Transaction> completedTransactions;

  const TransactionBaseState({
    required this.transactions,
    required this.lentTransactions,
    required this.borrowedTransactions,
    required this.pendingTransactions,
    required this.completedTransactions,
  });

  @override
  List<Object?> get props => [
        transactions,
        lentTransactions,
        borrowedTransactions,
        pendingTransactions,
        completedTransactions,
      ];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

// States with loaded data
final class TransactionLoaded extends TransactionBaseState {
  const TransactionLoaded({
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });
}

final class TransactionCreating extends TransactionBaseState {
  const TransactionCreating({
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });
}

final class TransactionCreated extends TransactionBaseState {
  const TransactionCreated({
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });
}

final class TransactionActionLoading extends TransactionBaseState {
  final String transactionId;
  final String action;

  const TransactionActionLoading({
    required this.transactionId,
    required this.action,
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });

  @override
  List<Object?> get props => [
        transactionId,
        action,
        ...super.props,
      ];
}

final class TransactionActionSuccess extends TransactionBaseState {
  final String message;

  const TransactionActionSuccess({
    required this.message,
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}

final class TransactionError extends TransactionBaseState {
  final String message;
  final FailureType type;

  const TransactionError({
    required this.message,
    required this.type,
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
  });

  @override
  List<Object?> get props => [message, type, ...super.props];
}

final class TransactionInitialError extends TransactionState {
  final String message;
  final FailureType type;

  const TransactionInitialError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}