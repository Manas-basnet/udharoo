import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/generate_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/parse_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_stats_usecase.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final CreateTransactionUseCase createTransactionUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetTransactionByIdUseCase getTransactionByIdUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final VerifyTransactionUseCase verifyTransactionUseCase;
  final CompleteTransactionUseCase completeTransactionUseCase;
  final GetTransactionContactsUseCase getTransactionContactsUseCase;
  final GetContactTransactionsUseCase getContactTransactionsUseCase;
  final GenerateQRUseCase generateQRUseCase;
  final ParseQRUseCase parseQRUseCase;
  final GetTransactionStatsUseCase getTransactionStatsUseCase;

  TransactionCubit({
    required this.createTransactionUseCase,
    required this.getTransactionsUseCase,
    required this.getTransactionByIdUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.verifyTransactionUseCase,
    required this.completeTransactionUseCase,
    required this.getTransactionContactsUseCase,
    required this.getContactTransactionsUseCase,
    required this.generateQRUseCase,
    required this.parseQRUseCase,
    required this.getTransactionStatsUseCase,
  }) : super(const TransactionInitial());

  Future<void> createTransaction(Transaction transaction) async {
    emit(const TransactionLoading());

    final result = await createTransactionUseCase(transaction);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionCreated(transaction)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> getTransactions({
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
    int? limit,
    bool refresh = false,
  }) async {
    if (refresh || state is! TransactionsLoaded) {
      emit(const TransactionLoading());
    }

    String? lastDocumentId;
    List<Transaction> existingTransactions = [];

    if (!refresh && state is TransactionsLoaded) {
      final currentState = state as TransactionsLoaded;
      lastDocumentId = currentState.lastDocumentId;
      existingTransactions = currentState.transactions;
    }

    final result = await getTransactionsUseCase(
      status: status,
      type: type,
      searchQuery: searchQuery,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (newTransactions) {
          final allTransactions = refresh 
              ? newTransactions
              : [...existingTransactions, ...newTransactions];
          
          emit(TransactionsLoaded(
            transactions: allTransactions,
            hasMore: newTransactions.length == (limit ?? 20),
            lastDocumentId: newTransactions.isNotEmpty ? newTransactions.last.id : null,
          ));
        },
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> getTransactionById(String id) async {
    emit(const TransactionLoading());

    final result = await getTransactionByIdUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionDetailLoaded(transaction)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    emit(const TransactionLoading());

    final result = await updateTransactionUseCase(transaction);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionUpdated(transaction)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    emit(const TransactionLoading());

    final result = await deleteTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (_) => emit(TransactionDeleted(id)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> verifyTransaction(String id, String verifiedBy) async {
    emit(const TransactionLoading());

    final result = await verifyTransactionUseCase(id, verifiedBy);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionVerified(transaction)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> completeTransaction(String id) async {
    emit(const TransactionLoading());

    final result = await completeTransactionUseCase(id);

    if (!isClosed) {
      result.fold(
        onSuccess: (transaction) => emit(TransactionCompleted(transaction)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> getTransactionContacts() async {
    emit(const TransactionLoading());

    final result = await getTransactionContactsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (contacts) => emit(TransactionContactsLoaded(contacts)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> getContactTransactions(String contactPhone) async {
    emit(const TransactionLoading());

    final result = await getContactTransactionsUseCase(contactPhone);

    if (!isClosed) {
      result.fold(
        onSuccess: (transactions) => emit(ContactTransactionsLoaded(
          transactions: transactions,
          contactPhone: contactPhone,
        )),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> generateQRCode({
    required String userPhone,
    required String userName,
    String? userEmail,
    required bool verificationRequired,
    String? customMessage,
  }) async {
    emit(const TransactionLoading());

    final result = await generateQRUseCase(
      userPhone: userPhone,
      userName: userName,
      userEmail: userEmail,
      verificationRequired: verificationRequired,
      customMessage: customMessage,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (qrData) => emit(QRCodeGenerated(qrData)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> parseQRCode(String qrCodeData) async {
    final result = await parseQRUseCase(qrCodeData);

    if (!isClosed) {
      result.fold(
        onSuccess: (qrData) => emit(QRCodeParsed(qrData)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  Future<void> getTransactionStats() async {
    final result = await getTransactionStatsUseCase();

    if (!isClosed) {
      result.fold(
        onSuccess: (stats) => emit(TransactionStatsLoaded(stats)),
        onFailure: (message, type) => emit(TransactionError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const TransactionInitial());
    }
  }
}