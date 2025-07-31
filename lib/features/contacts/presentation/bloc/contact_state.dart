part of 'contact_cubit.dart';

sealed class ContactState extends Equatable {
  const ContactState();

  @override
  List<Object?> get props => [];
}

final class ContactInitial extends ContactState {
  const ContactInitial();
}

final class ContactLoading extends ContactState {
  const ContactLoading();
}

final class ContactSearching extends ContactState {
  const ContactSearching();
}

final class ContactAdding extends ContactState {
  const ContactAdding();
}

final class ContactLoaded extends ContactState {
  final List<Contact> contacts;

  const ContactLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

final class ContactSearchResults extends ContactState {
  final List<Contact> contacts;
  final String query;

  const ContactSearchResults(this.contacts, this.query);

  @override
  List<Object?> get props => [contacts, query];
}

final class ContactAddSuccess extends ContactState {
  const ContactAddSuccess();
}

final class ContactDeleteSuccess extends ContactState {
  const ContactDeleteSuccess();
}

final class ContactError extends ContactState {
  final String message;
  final FailureType type;

  const ContactError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}