import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/usecases/get_user_by_phone_usecase.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';

part 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  final GetUserByPhoneUseCase _getUserByPhoneUseCase;
  final CreateTransactionUseCase _createTransactionUseCase;

  TransactionFormCubit({
    required GetUserByPhoneUseCase getUserByPhoneUseCase,
    required CreateTransactionUseCase createTransactionUseCase,
  })  : _getUserByPhoneUseCase = getUserByPhoneUseCase,
        _createTransactionUseCase = createTransactionUseCase,
        super(const TransactionFormInitial());

  Future<void> lookupUserByPhone(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      emit(const TransactionFormInitial());
      return;
    }

    // Format phone number to include country code if not present
    String formattedPhone = phoneNumber.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+977$formattedPhone';
    }

    if (!isClosed) {
      emit(const TransactionFormUserLookupLoading());
    }

    final result = await _getUserByPhoneUseCase(formattedPhone);

    if (!isClosed) {
      result.fold(
        onSuccess: (user) {
          if (user != null) {
            emit(TransactionFormUserFound(user));
          } else {
            emit(TransactionFormUserNotFound(formattedPhone));
          }
        },
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  Future<void> createTransaction({
    required double amount,
    required String otherPartyUid,
    required String otherPartyName,
    required String description,
    required TransactionType type,
  }) async {
    if (!isClosed) {
      emit(const TransactionFormLoading());
    }

    final result = await _createTransactionUseCase(
      amount: amount,
      otherPartyUid: otherPartyUid,
      otherPartyName: otherPartyName,
      description: description,
      type: type,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(const TransactionFormSuccess()),
        onFailure: (message, type) => emit(TransactionFormError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionFormInitial());
    }
  }

  void clearUserLookup() {
    if (!isClosed) {
      emit(const TransactionFormInitial());
    }
  }
}