import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_received_transaction_requests_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';

part 'received_transaction_requests_state.dart';

class ReceivedTransactionRequestsCubit extends Cubit<ReceivedTransactionRequestsState> {
  final GetReceivedTransactionRequestsUseCase getReceivedTransactionRequestsUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;

  ReceivedTransactionRequestsCubit({
    required this.getReceivedTransactionRequestsUseCase,
    required this.verifyTransactionUseCase,
  }) : super(const ReceivedTransactionRequestsInitial());

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
}