import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_stats_usecase.dart';

part 'transaction_stats_state.dart';

class TransactionStatsCubit extends Cubit<TransactionStatsState> {
  final GetTransactionStatsUseCase getTransactionStatsUseCase;

  TransactionStatsCubit({
    required this.getTransactionStatsUseCase,
  }) : super(const TransactionStatsInitial());

  Future<void> loadTransactionStats() async {
    emit(const TransactionStatsLoading());

    final result = await getTransactionStatsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (stats) => emit(TransactionStatsLoaded(stats)),
        onFailure: (message, type) => emit(TransactionStatsError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionStatsInitial());
    }
  }
}