import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_completion_requests_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/request_transaction_completion_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';

part 'completion_requests_state.dart';

class CompletionRequestsCubit extends Cubit<CompletionRequestsState> {
  final GetCompletionRequestsUseCase getCompletionRequestsUseCase;
  final RequestTransactionCompletionUseCase requestTransactionCompletionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;

  CompletionRequestsCubit({
    required this.getCompletionRequestsUseCase,
    required this.requestTransactionCompletionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const CompletionRequestsInitial());

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
}