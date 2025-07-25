import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';

part 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final GetTransactionContactsUseCase getTransactionContactsUseCase;

  TransactionFormCubit({
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.getTransactionContactsUseCase,
  }) : super(const TransactionFormInitial());

  Future<void> createTransaction(Transaction transaction) async {
    emit(const TransactionFormLoading());

    final result = await createTransactionUseCase(transaction);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionFormCreated(transaction)),
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    emit(const TransactionFormLoading());

    final result = await updateTransactionUseCase(transaction);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionFormUpdated(transaction)),
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  Future<void> loadTransactionContacts() async {
    final result = await getTransactionContactsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(TransactionFormContactsLoaded(contacts)),
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionFormInitial());
    }
  }
}