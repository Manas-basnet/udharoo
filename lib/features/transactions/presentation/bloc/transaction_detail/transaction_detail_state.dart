part of 'transaction_detail_cubit.dart';

sealed class TransactionDetailState extends Equatable {
  const TransactionDetailState();

  @override
  List<Object?> get props => [];
}

final class TransactionDetailInitial extends TransactionDetailState {
  const TransactionDetailInitial();
}

final class TransactionDetailLoading extends TransactionDetailState {
  const TransactionDetailLoading();
}

final class TransactionDetailLoaded extends TransactionDetailState {
  final Transaction transaction;

  const TransactionDetailLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDetailUpdated extends TransactionDetailState {
  final Transaction transaction;

  const TransactionDetailUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDetailDeleted extends TransactionDetailState {
  final String transactionId;

  const TransactionDetailDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionDetailVerifying extends TransactionDetailState {
  final String transactionId;

  const TransactionDetailVerifying(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionDetailVerified extends TransactionDetailState {
  final Transaction transaction;

  const TransactionDetailVerified(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDetailCompleting extends TransactionDetailState {
  final String transactionId;

  const TransactionDetailCompleting(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionDetailCompleted extends TransactionDetailState {
  final Transaction transaction;

  const TransactionDetailCompleted(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDetailError extends TransactionDetailState {
  final String message;
  final FailureType type;

  const TransactionDetailError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}