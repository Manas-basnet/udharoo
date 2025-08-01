import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';

part 'contact_transactions_state.dart';

class ContactTransactionsCubit extends Cubit<ContactTransactionsState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  ContactTransactionsCubit({
    required GetTransactionsUseCase getTransactionsUseCase,
  })  : _getTransactionsUseCase = getTransactionsUseCase,
        super(const ContactTransactionsInitial());

  void loadContactTransactions(String contactUserId) {
    if (!isClosed) {
      emit(const ContactTransactionsLoading());
    }

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _getTransactionsUseCase().listen(
      (allTransactions) {
        if (!isClosed) {
          final contactTransactions = allTransactions
              .where((transaction) => transaction.otherParty.uid == contactUserId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          emit(ContactTransactionsLoaded(contactTransactions));
        }
      },
      onError: (error) {
        if (!isClosed) {
          final errorMessage = _getErrorMessage(error);
          emit(ContactTransactionsError(errorMessage, FailureType.unknown));
        }
      },
    );
  }

  void refreshTransactions(String contactUserId) {
    loadContactTransactions(contactUserId);
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    return error?.toString() ?? 'An unexpected error occurred';
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}