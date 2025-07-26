import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/events/event_bus.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/events/transaction_events.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_completion_requests_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/request_transaction_completion_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';

part 'completion_requests_state.dart';

class CompletionRequestsCubit extends Cubit<CompletionRequestsState> {
  final GetCompletionRequestsUseCase getCompletionRequestsUseCase;
  final RequestTransactionCompletionUseCase requestTransactionCompletionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;
  late StreamSubscription _eventSubscription;

  CompletionRequestsCubit({
    required this.getCompletionRequestsUseCase,
    required this.requestTransactionCompletionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const CompletionRequestsInitial()) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = EventBus().on<TransactionEvent>().listen(_handleEvent);
  }

  void _handleEvent(TransactionEvent event) {
    if (isClosed) return;

    switch (event) {
      case TransactionCompletedEvent():
        _removeCompletedRequest(event.transaction.id);
      default:
        break;
    }
  }

  void _removeCompletedRequest(String transactionId) {
    if (state is CompletionRequestsLoaded) {
      final currentState = state as CompletionRequestsLoaded;
      final updatedRequests = currentState.requests
          .where((request) => request.id != transactionId)
          .toList();
      emit(CompletionRequestsLoaded(updatedRequests));
    }
  }

  Future<void> loadCompletionRequests() async {
    emit(const CompletionRequestsLoading());

    final result = await getCompletionRequestsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (requests) => emit(CompletionRequestsLoaded(requests)),
        onFailure: (message, type) => emit(CompletionRequestsError(message, type)),
      );
    }
  }

  Future<void> requestCompletion(String transactionId, String requestedBy) async {
    final result = await requestTransactionCompletionUseCase(transactionId, requestedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(CompletionRequestSent(transaction));
          EventBus().emit(TransactionUpdatedEvent(transaction));
          loadCompletionRequests();
        },
        onFailure: (message, type) => emit(CompletionRequestsError(message, type)),
      );
    }
  }

  Future<void> approveCompletionRequest(String transactionId) async {
    final result = await completeTransactionUseCase(transactionId);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) {
          emit(CompletionRequestApproved(transaction));
          EventBus().emit(TransactionCompletedEvent(transaction));
          loadCompletionRequests();
        },
        onFailure: (message, type) => emit(CompletionRequestsError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const CompletionRequestsInitial());
    }
  }

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}