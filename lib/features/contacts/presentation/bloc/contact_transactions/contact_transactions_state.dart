part of 'contact_transactions_cubit.dart';

sealed class ContactTransactionsState extends Equatable {
  const ContactTransactionsState();

  @override
  List<Object?> get props => [];
}

final class ContactTransactionsInitial extends ContactTransactionsState {
  const ContactTransactionsInitial();
}

final class ContactTransactionsLoading extends ContactTransactionsState {
  const ContactTransactionsLoading();
}

final class ContactTransactionsLoaded extends ContactTransactionsState {
  final List<Transaction> transactions;

  const ContactTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

final class ContactTransactionsError extends ContactTransactionsState {
  final String message;
  final FailureType type;

  const ContactTransactionsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}