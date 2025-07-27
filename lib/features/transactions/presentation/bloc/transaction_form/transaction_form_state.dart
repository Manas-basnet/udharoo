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

final class TransactionFormUserLookupLoading extends TransactionFormState {
  const TransactionFormUserLookupLoading();
}

final class TransactionFormUserFound extends TransactionFormState {
  final AuthUser user;

  const TransactionFormUserFound(this.user);

  @override
  List<Object?> get props => [user];
}

final class TransactionFormUserNotFound extends TransactionFormState {
  final String phoneNumber;

  const TransactionFormUserNotFound(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

final class TransactionFormRecentContactsLoaded extends TransactionFormState {
  final List<AuthUser> recentContacts;

  const TransactionFormRecentContactsLoaded(this.recentContacts);

  @override
  List<Object?> get props => [recentContacts];
}

final class TransactionFormSuccess extends TransactionFormState {
  const TransactionFormSuccess();
}

final class TransactionFormError extends TransactionFormState {
  final String message;
  final FailureType type;

  const TransactionFormError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}