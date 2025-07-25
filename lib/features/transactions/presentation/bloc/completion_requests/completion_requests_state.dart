part of 'completion_requests_cubit.dart';

sealed class CompletionRequestsState extends Equatable {
  const CompletionRequestsState();

  @override
  List<Object?> get props => [];
}

final class CompletionRequestsInitial extends CompletionRequestsState {
  const CompletionRequestsInitial();
}

final class CompletionRequestsLoading extends CompletionRequestsState {
  const CompletionRequestsLoading();
}

final class CompletionRequestsLoaded extends CompletionRequestsState {
  final List<Transaction> requests;

  const CompletionRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

final class CompletionRequestSent extends CompletionRequestsState {
  final Transaction transaction;

  const CompletionRequestSent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class CompletionRequestApproved extends CompletionRequestsState {
  final Transaction transaction;

  const CompletionRequestApproved(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class CompletionRequestsError extends CompletionRequestsState {
  final String message;
  final FailureType type;

  const CompletionRequestsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}