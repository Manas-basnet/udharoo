part of 'contact_cubit.dart';

class ContactState extends Equatable {
  final List<Contact> contacts;
  final List<Contact> searchResults;
  
  final bool isInitialLoading;
  final bool isAdding;
  final bool isDeleting;
  final bool isSearching;
  final bool isLookingUpUser;
  
  final String? errorMessage;
  final String? successMessage;
  final bool isInitialized;
  final String? searchQuery;
  final AuthUser? foundUser;

  const ContactState({
    this.contacts = const [],
    this.searchResults = const [],
    this.isInitialLoading = false,
    this.isAdding = false,
    this.isDeleting = false,
    this.isSearching = false,
    this.isLookingUpUser = false,
    this.errorMessage,
    this.successMessage,
    this.isInitialized = false,
    this.searchQuery,
    this.foundUser,
  });

  factory ContactState.initial() => const ContactState();

  ContactState copyWith({
    List<Contact>? contacts,
    List<Contact>? searchResults,
    bool? isInitialLoading,
    bool? isAdding,
    bool? isDeleting,
    bool? isSearching,
    bool? isLookingUpUser,
    String? errorMessage,
    String? successMessage,
    bool? isInitialized,
    String? searchQuery,
    AuthUser? foundUser,
  }) {
    return ContactState(
      contacts: contacts ?? this.contacts,
      searchResults: searchResults ?? this.searchResults,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isAdding: isAdding ?? this.isAdding,
      isDeleting: isDeleting ?? this.isDeleting,
      isSearching: isSearching ?? this.isSearching,
      isLookingUpUser: isLookingUpUser ?? this.isLookingUpUser,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      searchQuery: searchQuery,
      foundUser: foundUser,
    );
  }

  ContactState clearMessages() {
    return ContactState(
      contacts: contacts,
      searchResults: searchResults,
      isInitialLoading: isInitialLoading,
      isAdding: isAdding,
      isDeleting: isDeleting,
      isSearching: isSearching,
      isLookingUpUser: isLookingUpUser,
      errorMessage: null,
      successMessage: null,
      isInitialized: isInitialized,
      searchQuery: searchQuery,
      foundUser: foundUser,
    );
  }

  ContactState clearError() {
    return ContactState(
      contacts: contacts,
      searchResults: searchResults,
      isInitialLoading: isInitialLoading,
      isAdding: isAdding,
      isDeleting: isDeleting,
      isSearching: isSearching,
      isLookingUpUser: isLookingUpUser,
      errorMessage: null,
      successMessage: successMessage,
      isInitialized: isInitialized,
      searchQuery: searchQuery,
      foundUser: foundUser,
    );
  }

  ContactState clearSuccess() {
    return ContactState(
      contacts: contacts,
      searchResults: searchResults,
      isInitialLoading: isInitialLoading,
      isAdding: isAdding,
      isDeleting: isDeleting,
      isSearching: isSearching,
      isLookingUpUser: isLookingUpUser,
      errorMessage: errorMessage,
      successMessage: null,
      isInitialized: isInitialized,
      searchQuery: searchQuery,
      foundUser: foundUser,
    );
  }

  ContactState clearFoundUser() {
    return ContactState(
      contacts: contacts,
      searchResults: searchResults,
      isInitialLoading: isInitialLoading,
      isAdding: isAdding,
      isDeleting: isDeleting,
      isSearching: isSearching,
      isLookingUpUser: isLookingUpUser,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isInitialized: isInitialized,
      searchQuery: searchQuery,
      foundUser: null,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
  bool get hasContacts => contacts.isNotEmpty;
  bool get isLoading => isInitialLoading && !isInitialized;
  bool get isEmpty => contacts.isEmpty && isInitialized;
  bool get isSearchActive => searchQuery != null && searchQuery!.isNotEmpty;
  bool get hasSearchResults => searchResults.isNotEmpty;
  bool get hasFoundUser => foundUser != null;

  List<Contact> get displayContacts {
    if (isSearchActive) {
      return searchResults;
    }
    return contacts;
  }

  @override
  List<Object?> get props => [
        contacts,
        searchResults,
        isInitialLoading,
        isAdding,
        isDeleting,
        isSearching,
        isLookingUpUser,
        errorMessage,
        successMessage,
        isInitialized,
        searchQuery,
        foundUser,
      ];
}