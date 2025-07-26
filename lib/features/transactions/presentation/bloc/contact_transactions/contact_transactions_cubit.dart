import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/events/event_bus.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/events/transaction_events.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';

part 'contact_transactions_state.dart';

class ContactTransactionsCubit extends Cubit<ContactTransactionsState> {
  final GetTransactionContactsUseCase getTransactionContactsUseCase;
  final GetContactTransactionsUseCase getContactTransactionsUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  late StreamSubscription _eventSubscription;
  String? _currentContactPhone;

  ContactTransactionsCubit({
    required this.getTransactionContactsUseCase,
    required this.getContactTransactionsUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(const ContactTransactionsInitial()) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = EventBus().on<TransactionEvent>().listen(_handleEvent);
  }

  void _handleEvent(TransactionEvent event) {
    if (isClosed || _currentContactPhone == null) return;

    switch (event) {
      case TransactionCreatedEvent():
        if (_isTransactionForCurrentContact(event.transaction)) {
          _handleTransactionUpdatedForContact(event.transaction);
        }
      case TransactionUpdatedEvent():
        if (_isTransactionForCurrentContact(event.transaction)) {
          _handleTransactionUpdatedForContact(event.transaction);
        }
      case TransactionDeletedEvent():
        if (state is ContactTransactionsLoaded) {
          final currentState = state as ContactTransactionsLoaded;
          final hasTransaction = currentState.transactions.any((t) => t.id == event.transactionId);
          if (hasTransaction) {
            _handleTransactionDeletedForContact(event.transactionId);
          }
        }
      case TransactionVerifiedEvent():
        if (_isTransactionForCurrentContact(event.transaction)) {
          _handleTransactionUpdatedForContact(event.transaction);
        }
      case TransactionCompletedEvent():
        if (_isTransactionForCurrentContact(event.transaction)) {
          _handleTransactionDeletedForContact(event.transaction.id);
        }
      default:
        break;
    }
  }

  bool _isTransactionForCurrentContact(Transaction transaction) {
    if (_currentContactPhone == null) return false;
    return transaction.recipientPhone == _currentContactPhone || 
           transaction.creatorPhone == _currentContactPhone;
  }

  void _handleTransactionUpdatedForContact(Transaction transaction) {
    if (state is ContactTransactionsLoaded) {
      final currentState = state as ContactTransactionsLoaded;
      final transactions = List<Transaction>.from(currentState.transactions);
      
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        transactions[index] = transaction;
      } else {
        transactions.insert(0, transaction);
      }
      
      emit(ContactTransactionsLoaded(
        transactions: transactions,
        contactPhone: currentState.contactPhone,
      ));
    }
  }

  void _handleTransactionDeletedForContact(String transactionId) {
    if (state is ContactTransactionsLoaded) {
      final currentState = state as ContactTransactionsLoaded;
      final transactions = currentState.transactions
          .where((t) => t.id != transactionId)
          .toList();
      
      emit(ContactTransactionsLoaded(
        transactions: transactions,
        contactPhone: currentState.contactPhone,
      ));
    }
  }

  Future<void> loadTransactionContacts() async {
    emit(const ContactTransactionsLoading());
    _currentContactPhone = null;

    final result = await getTransactionContactsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(ContactsLoaded(contacts)),
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> loadContactTransactions(String contactPhone) async {
    emit(const ContactTransactionsLoading());
    _currentContactPhone = contactPhone;

    final result = await getContactTransactionsUseCase(contactPhone);

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) => emit(ContactTransactionsLoaded(
          transactions: transactions,
          contactPhone: contactPhone,
        )),
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(ContactTransactionUpdated(transaction));
          EventBus().emit(TransactionVerifiedEvent(transaction));
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(ContactTransactionUpdated(transaction));
          EventBus().emit(TransactionCompletedEvent(transaction));
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (state is ContactTransactionsLoaded) {
      final currentState = state as ContactTransactionsLoaded;
      final optimisticTransactions = currentState.transactions
          .where((t) => t.id != id)
          .toList();
      emit(ContactTransactionsLoaded(
        transactions: optimisticTransactions,
        contactPhone: currentState.contactPhone,
      ));
    }

    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) {
          emit(ContactTransactionDeleted(id));
          EventBus().emit(TransactionDeletedEvent(id));
        },
        onFailure: (message, type) {
          if (_currentContactPhone != null) {
            loadContactTransactions(_currentContactPhone!);
          }
          emit(ContactTransactionsError(message, type));
        },
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      _currentContactPhone = null;
      emit(const ContactTransactionsInitial());
    }
  }

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}