part of 'received_transaction_requests_cubit.dart';

sealed class ReceivedTransactionRequestsState extends Equatable {
  const ReceivedTransactionRequestsState();

  @override
  List<Object?> get props => [];
}

final class ReceivedTransactionRequestsInitial extends ReceivedTransactionRequestsState {
  const ReceivedTransactionRequestsInitial();
}

final class ReceivedTransactionRequestsLoading extends ReceivedTransactionRequestsState {
  const ReceivedTransactionRequestsLoading();
}

final class ReceivedTransactionRequestsLoaded extends ReceivedTransactionRequestsState {
  final List<Transaction> requests;

  const ReceivedTransactionRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

final class ReceivedTransactionRequestVerified extends ReceivedTransactionRequestsState {
  final Transaction transaction;

  const ReceivedTransactionRequestVerified(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class ReceivedTransactionRequestsError extends ReceivedTransactionRequestsState {
  final String message;
  final FailureType type;

  const ReceivedTransactionRequestsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}