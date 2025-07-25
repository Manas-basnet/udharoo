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

final class ContactsLoaded extends ContactTransactionsState {
  final List<TransactionContact> contacts;

  const ContactsLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

final class ContactTransactionsLoaded extends ContactTransactionsState {
  final List<Transaction> transactions;
  final String contactPhone;

  const ContactTransactionsLoaded({
    required this.transactions,
    required this.contactPhone,
  });

  @override
  List<Object?> get props => [transactions, contactPhone];
}

final class ContactTransactionUpdated extends ContactTransactionsState {
  final Transaction transaction;

  const ContactTransactionUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class ContactTransactionDeleted extends ContactTransactionsState {
  final String transactionId;

  const ContactTransactionDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class ContactTransactionsError extends ContactTransactionsState {
  final String message;
  final FailureType type;

  const ContactTransactionsError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}