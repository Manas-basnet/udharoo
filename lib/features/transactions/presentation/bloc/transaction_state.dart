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
  final Set<String> processingTransactionIds;

  const TransactionBaseState({
    required this.transactions,
    required this.lentTransactions,
    required this.borrowedTransactions,
    required this.pendingTransactions,
    required this.completedTransactions,
    this.processingTransactionIds = const {},
  });

  bool isTransactionProcessing(String transactionId) {
    return processingTransactionIds.contains(transactionId);
  }

  @override
  List<Object?> get props => [
        transactions,
        lentTransactions,
        borrowedTransactions,
        pendingTransactions,
        completedTransactions,
        processingTransactionIds,
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
    super.processingTransactionIds,
  });

  TransactionLoaded copyWithProcessingIds(Set<String> processingIds) {
    return TransactionLoaded(
      transactions: transactions,
      lentTransactions: lentTransactions,
      borrowedTransactions: borrowedTransactions,
      pendingTransactions: pendingTransactions,
      completedTransactions: completedTransactions,
      processingTransactionIds: processingIds,
    );
  }
}

final class TransactionCreating extends TransactionBaseState {
  const TransactionCreating({
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
    super.processingTransactionIds,
  });
}

final class TransactionCreated extends TransactionBaseState {
  const TransactionCreated({
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
    super.processingTransactionIds,
  });
}

final class TransactionActionSuccess extends TransactionBaseState {
  final String message;
  final String actionType;

  const TransactionActionSuccess({
    required this.message,
    required this.actionType,
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
    super.processingTransactionIds,
  });

  @override
  List<Object?> get props => [message, actionType, ...super.props];
}

final class TransactionActionError extends TransactionBaseState {
  final String message;
  final String transactionId;
  final String actionType;
  final FailureType type;

  const TransactionActionError({
    required this.message,
    required this.transactionId,
    required this.actionType,
    required this.type,
    required super.transactions,
    required super.lentTransactions,
    required super.borrowedTransactions,
    required super.pendingTransactions,
    required super.completedTransactions,
    super.processingTransactionIds,
  });

  @override
  List<Object?> get props => [message, transactionId, actionType, type, ...super.props];
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
    super.processingTransactionIds,
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