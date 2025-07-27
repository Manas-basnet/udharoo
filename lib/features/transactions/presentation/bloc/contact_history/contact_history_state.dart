part of 'contact_history_cubit.dart';

sealed class ContactHistoryState extends Equatable {
  const ContactHistoryState();

  @override
  List<Object?> get props => [];
}

final class ContactHistoryInitial extends ContactHistoryState {
  const ContactHistoryInitial();
}

final class ContactHistoryLoading extends ContactHistoryState {
  const ContactHistoryLoading();
}

final class ContactHistorySearching extends ContactHistoryState {
  const ContactHistorySearching();
}

final class ContactHistoryLoaded extends ContactHistoryState {
  final List<ContactHistory> contacts;

  const ContactHistoryLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

final class ContactHistorySearchResults extends ContactHistoryState {
  final List<ContactHistory> contacts;
  final String query;

  const ContactHistorySearchResults(this.contacts, this.query);

  @override
  List<Object?> get props => [contacts, query];
}

final class ContactHistoryError extends ContactHistoryState {
  final String message;
  final FailureType type;

  const ContactHistoryError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}