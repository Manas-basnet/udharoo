import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_phone_exists_usecase.dart';

part 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final GetTransactionContactsUseCase getTransactionContactsUseCase;
  final VerifyPhoneExistsUseCase verifyPhoneExistsUseCase;

  TransactionFormCubit({
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.getTransactionContactsUseCase,
    required this.verifyPhoneExistsUseCase,
  }) : super(const TransactionFormInitial());

  Future<void> createTransaction(Transaction transaction) async {
    emit(const TransactionFormLoading());

    if (transaction.verificationRequired && transaction.contactPhone != null) {
      final phoneVerificationResult = await verifyPhoneExistsUseCase(transaction.contactPhone!);
      
      final phoneValidationFailed = phoneVerificationResult.fold(
        onSuccess: (userId) => userId == null,
        onFailure: (message, type) => true,
      );

      if (phoneValidationFailed) {
        emit(const TransactionFormError('User with this phone number does not exist', FailureType.validation));
        return;
      }
    }

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

    if (transaction.verificationRequired && transaction.contactPhone != null) {
      final phoneVerificationResult = await verifyPhoneExistsUseCase(transaction.contactPhone!);
      
      final phoneValidationFailed = phoneVerificationResult.fold(
        onSuccess: (userId) => userId == null,
        onFailure: (message, type) => true,
      );

      if (phoneValidationFailed) {
        emit(const TransactionFormError('User with this phone number does not exist', FailureType.validation));
        return;
      }
    }

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

  Future<void> verifyPhoneExists(String phoneNumber) async {
    emit(TransactionFormPhoneValidating(phoneNumber));

    final result = await verifyPhoneExistsUseCase(phoneNumber);

    if (!isClosed) {
      result.fold(
        onSuccess: (userId) {
          if (userId != null) {
            emit(TransactionFormPhoneVerified(phoneNumber, userId));
          } else {
            emit(const TransactionFormPhoneNotFound('No user found with this phone number'));
          }
        },
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionFormInitial());
    }
  }

  void resetPhoneValidation() {
    if (!isClosed && state is! TransactionFormLoading) {
      emit(const TransactionFormInitial());
    }
  }
}