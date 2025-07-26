import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionUtils {
  static TransactionType parseTransactionType(String type) {
    switch (type.toUpperCase()) {
      case 'LENT':
        return TransactionType.lent;
      case 'BORROWED':
        return TransactionType.borrowed;
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }

  static String transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'LENT';
      case TransactionType.borrowed:
        return 'BORROWED';
    }
  }

  static TransactionStatus parseTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return TransactionStatus.pendingVerification;
      case 'VERIFIED':
        return TransactionStatus.verified;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'REJECTED':
        return TransactionStatus.rejected;
      default:
        throw ArgumentError('Unknown transaction status: $status');
    }
  }

  static String transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case TransactionStatus.verified:
        return 'VERIFIED';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }
}