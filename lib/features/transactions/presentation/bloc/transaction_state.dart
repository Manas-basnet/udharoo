part of 'transaction_cubit.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionCreated extends TransactionState {
  final Transaction transaction;

  const TransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionsLoaded extends TransactionState {
  final List<Transaction> transactions;
  final bool hasMore;
  final String? lastDocumentId;

  const TransactionsLoaded({
    required this.transactions,
    this.hasMore = false,
    this.lastDocumentId,
  });

  @override
  List<Object?> get props => [transactions, hasMore, lastDocumentId];
}

final class TransactionDetailLoaded extends TransactionState {
  final Transaction transaction;

  const TransactionDetailLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionUpdated extends TransactionState {
  final Transaction transaction;

  const TransactionUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDeleted extends TransactionState {
  final String transactionId;

  const TransactionDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionVerified extends TransactionState {
  final Transaction transaction;

  const TransactionVerified(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionCompleted extends TransactionState {
  final Transaction transaction;

  const TransactionCompleted(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionContactsLoaded extends TransactionState {
  final List<TransactionContact> contacts;

  const TransactionContactsLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

final class ContactTransactionsLoaded extends TransactionState {
  final List<Transaction> transactions;
  final String contactPhone;

  const ContactTransactionsLoaded({
    required this.transactions,
    required this.contactPhone,
  });

  @override
  List<Object?> get props => [transactions, contactPhone];
}

final class TransactionStatsLoaded extends TransactionState {
  final Map<String, dynamic> stats;

  const TransactionStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

final class QRCodeGenerated extends TransactionState {
  final QRData qrData;

  const QRCodeGenerated(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

final class QRCodeParsed extends TransactionState {
  final QRData qrData;

  const QRCodeParsed(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

final class GlobalVerificationSettingLoaded extends TransactionState {
  final bool enabled;

  const GlobalVerificationSettingLoaded(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class GlobalVerificationSettingUpdated extends TransactionState {
  final bool enabled;

  const GlobalVerificationSettingUpdated(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class TransactionError extends TransactionState {
  final String message;
  final FailureType type;

  const TransactionError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}