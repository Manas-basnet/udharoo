import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/events/event_bus.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/events/transaction_events.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_received_transaction_requests_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';

part 'received_transaction_requests_state.dart';

class ReceivedTransactionRequestsCubit extends Cubit<ReceivedTransactionRequestsState> {
  final GetReceivedTransactionRequestsUseCase getReceivedTransactionRequestsUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  late StreamSubscription _eventSubscription;

  ReceivedTransactionRequestsCubit({
    required this.getReceivedTransactionRequestsUseCase,
    required this.verifyTransactionUseCase,
  }) : super(const ReceivedTransactionRequestsInitial()) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = EventBus().on<TransactionEvent>().listen(_handleEvent);
  }

  void _handleEvent(TransactionEvent event) {
    if (isClosed) return;

    switch (event) {
      case TransactionCreatedEvent():
        if (event.transaction.verificationRequired && !event.transaction.isVerified) {
          loadReceivedTransactionRequests();
        }
      case TransactionVerifiedEvent():
        _removeVerifiedRequest(event.transaction.id);
      default:
        break;
    }
  }

  void _removeVerifiedRequest(String transactionId) {
    if (state is ReceivedTransactionRequestsLoaded) {
      final currentState = state as ReceivedTransactionRequestsLoaded;
      final updatedRequests = currentState.requests
          .where((request) => request.id != transactionId)
          .toList();
      emit(ReceivedTransactionRequestsLoaded(updatedRequests));
    }
  }

  Future<void> loadReceivedTransactionRequests() async {
    emit(const ReceivedTransactionRequestsLoading());

    final result = await getReceivedTransactionRequestsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (requests) => emit(ReceivedTransactionRequestsLoaded(requests)),
        onFailure: (message, type) => emit(ReceivedTransactionRequestsError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(ReceivedTransactionRequestVerified(transaction));
          EventBus().emit(TransactionVerifiedEvent(transaction));
          loadReceivedTransactionRequests();
        },
        onFailure: (message, type) => emit(ReceivedTransactionRequestsError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const ReceivedTransactionRequestsInitial());
    }
  }

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}