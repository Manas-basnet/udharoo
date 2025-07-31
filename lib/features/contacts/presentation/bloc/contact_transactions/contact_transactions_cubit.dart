import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

part 'contact_transactions_state.dart';

class ContactTransactionsCubit extends Cubit<ContactTransactionsState> {
  final GetContactTransactionsUseCase _getContactTransactionsUseCase;

  ContactTransactionsCubit({
    required GetContactTransactionsUseCase getContactTransactionsUseCase,
  })  : _getContactTransactionsUseCase = getContactTransactionsUseCase,
        super(const ContactTransactionsInitial());

  Future<void> loadContactTransactions(String contactUserId) async {
    if (!isClosed) {
      emit(const ContactTransactionsLoading());
    }

    final result = await _getContactTransactionsUseCase(contactUserId);

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) {
          final sortedTransactions = List<Transaction>.from(transactions)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(ContactTransactionsLoaded(sortedTransactions));
        },
        onFailure: (message, type) => emit(ContactTransactionsError(message, type)),
      );
    }
  }

  void refreshTransactions(String contactUserId) {
    loadContactTransactions(contactUserId);
  }
}