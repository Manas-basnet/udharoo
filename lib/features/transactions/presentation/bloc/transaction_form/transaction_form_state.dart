part of 'transaction_form_cubit.dart';

sealed class TransactionFormState extends Equatable {
  const TransactionFormState();

  @override
  List<Object?> get props => [];
}

final class TransactionFormInitial extends TransactionFormState {
  const TransactionFormInitial();
}

final class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading();
}

final class TransactionFormCreated extends TransactionFormState {
  final Transaction transaction;

  const TransactionFormCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionFormUpdated extends TransactionFormState {
  final Transaction transaction;

  const TransactionFormUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionFormContactsLoaded extends TransactionFormState {
  final List<TransactionContact> contacts;

  const TransactionFormContactsLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

final class TransactionFormPhoneValidating extends TransactionFormState {
  final String phoneNumber;

  const TransactionFormPhoneValidating(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

final class TransactionFormPhoneVerified extends TransactionFormState {
  final String phoneNumber;
  final String userId;

  const TransactionFormPhoneVerified(this.phoneNumber, this.userId);

  @override
  List<Object?> get props => [phoneNumber, userId];
}

final class TransactionFormPhoneNotFound extends TransactionFormState {
  final String message;

  const TransactionFormPhoneNotFound(this.message);

  @override
  List<Object?> get props => [message];
}

final class TransactionFormError extends TransactionFormState {
  final String message;
  final FailureType type;

  const TransactionFormError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}