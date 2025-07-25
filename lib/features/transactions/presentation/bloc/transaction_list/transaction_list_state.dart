part of 'transaction_list_cubit.dart';

sealed class TransactionListState extends Equatable {
  const TransactionListState();

  @override
  List<Object?> get props => [];
}

final class TransactionListInitial extends TransactionListState {
  const TransactionListInitial();
}

final class TransactionListLoading extends TransactionListState {
  const TransactionListLoading();
}

final class TransactionListLoaded extends TransactionListState {
  final List<Transaction> transactions;
  final bool hasMore;
  final String? lastDocumentId;

  const TransactionListLoaded({
    required this.transactions,
    this.hasMore = false,
    this.lastDocumentId,
  });

  TransactionListLoaded copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    String? lastDocumentId,
  }) {
    return TransactionListLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
    );
  }

  @override
  List<Object?> get props => [transactions, hasMore, lastDocumentId];
}

final class TransactionListUpdated extends TransactionListState {
  final Transaction transaction;

  const TransactionListUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class TransactionListDeleted extends TransactionListState {
  final String transactionId;

  const TransactionListDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionListError extends TransactionListState {
  final String message;
  final FailureType type;

  const TransactionListError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}