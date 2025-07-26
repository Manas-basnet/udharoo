import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

abstract class TransactionEvent {
  const TransactionEvent();
}

class TransactionCreatedEvent extends TransactionEvent {
  final Transaction transaction;
  const TransactionCreatedEvent(this.transaction);
}

class TransactionUpdatedEvent extends TransactionEvent {
  final Transaction transaction;
  const TransactionUpdatedEvent(this.transaction);
}

class TransactionDeletedEvent extends TransactionEvent {
  final String transactionId;
  const TransactionDeletedEvent(this.transactionId);
}

class TransactionVerifiedEvent extends TransactionEvent {
  final Transaction transaction;
  const TransactionVerifiedEvent(this.transaction);
}

class TransactionCompletedEvent extends TransactionEvent {
  final Transaction transaction;
  const TransactionCompletedEvent(this.transaction);
}

class TransactionStatsChangedEvent extends TransactionEvent {
  final List<Transaction> allTransactions;
  const TransactionStatsChangedEvent(this.allTransactions);
}