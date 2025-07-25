import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';

part 'transaction_detail_state.dart';

class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  final GetTransactionByIdUseCase getTransactionByIdUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;

  TransactionDetailCubit({
    required this.getTransactionByIdUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
  }) : super(const TransactionDetailInitial());

  Future<void> loadTransaction(String id) async {
    emit(const TransactionDetailLoading());

    final result = await getTransactionByIdUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionDetailLoaded(transaction)),
        onFailure: (message, type) => emit(TransactionDetailError(message, type)),
      );
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    emit(const TransactionDetailLoading());

    final result = await updateTransactionUseCase(transaction);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionDetailUpdated(transaction)),
        onFailure: (message, type) => emit(TransactionDetailError(message, type)),
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    emit(const TransactionDetailLoading());

    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(TransactionDetailDeleted(id)),
        onFailure: (message, type) => emit(TransactionDetailError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    if (state is TransactionDetailLoaded) {
      emit(TransactionDetailVerifying(id));
    }

    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionDetailVerified(transaction)),
        onFailure: (message, type) => emit(TransactionDetailError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    if (state is TransactionDetailLoaded) {
      emit(TransactionDetailCompleting(id));
    }

    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionDetailCompleted(transaction)),
        onFailure: (message, type) => emit(TransactionDetailError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionDetailInitial());
    }
  }
}