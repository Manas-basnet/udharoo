import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionDisplayHelper {
  static String formatAmount(double amount) {
    if (amount >= 10000000) {
      final crores = amount / 10000000;
      return '${crores.toStringAsFixed(crores.truncateToDouble() == crores ? 0 : 1)}Cr';
    } else if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '${lakhs.toStringAsFixed(lakhs.truncateToDouble() == lakhs ? 0 : 1)}L';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    } else {
      return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    }
  }

  static String getContextualStatusLabel(Transaction transaction, bool isCurrentUserCreator) {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserCreator) {
          return 'Awaiting their response';
        } else {
          return 'Awaiting your response';
        }
      case TransactionStatus.verified:
        if (transaction.isLent) {
          return isCurrentUserCreator ? 'They owe you' : 'You owe them';
        } else {
          return isCurrentUserCreator ? 'You owe them' : 'They owe you';
        }
      case TransactionStatus.completed:
        if (transaction.isLent) {
          return isCurrentUserCreator ? 'Received' : 'Paid back';
        } else {
          return isCurrentUserCreator ? 'Paid back' : 'Received';
        }
      case TransactionStatus.rejected:
        if (isCurrentUserCreator) {
          return 'They declined';
        } else {
          return 'You declined';
        }
    }
  }

  static String getStatusDescription(Transaction transaction, bool isCurrentUserCreator) {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserCreator) {
          return 'Waiting for ${transaction.otherParty.name} to confirm this transaction';
        } else {
          return 'Please confirm if you want to proceed with this transaction';
        }
      case TransactionStatus.verified:
        if (transaction.isLent) {
          if (isCurrentUserCreator) {
            return '${transaction.otherParty.name} owes you Rs. ${formatAmount(transaction.amount)}';
          } else {
            return 'You owe ${transaction.otherParty.name} Rs. ${formatAmount(transaction.amount)}';
          }
        } else {
          if (isCurrentUserCreator) {
            return 'You owe ${transaction.otherParty.name} Rs. ${formatAmount(transaction.amount)}';
          } else {
            return '${transaction.otherParty.name} owes you Rs. ${formatAmount(transaction.amount)}';
          }
        }
      case TransactionStatus.completed:
        if (transaction.isLent) {
          if (isCurrentUserCreator) {
            return 'You received Rs. ${formatAmount(transaction.amount)} from ${transaction.otherParty.name}';
          } else {
            return 'You paid back Rs. ${formatAmount(transaction.amount)} to ${transaction.otherParty.name}';
          }
        } else {
          if (isCurrentUserCreator) {
            return 'You paid back Rs. ${formatAmount(transaction.amount)} to ${transaction.otherParty.name}';
          } else {
            return 'You received Rs. ${formatAmount(transaction.amount)} from ${transaction.otherParty.name}';
          }
        }
      case TransactionStatus.rejected:
        if (isCurrentUserCreator) {
          return '${transaction.otherParty.name} declined this transaction';
        } else {
          return 'You declined this transaction';
        }
    }
  }

  static String getTransactionDirection(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'Money Lent';
      case TransactionType.borrowed:
        return 'Money Borrowed';
    }
  }

  static String getTransactionAction(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'Money lent to';
      case TransactionType.borrowed:
        return 'Money borrowed from';
    }
  }

  static String getWhatHappensNext(Transaction transaction, bool isCurrentUserCreator) {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserCreator) {
          return '${transaction.otherParty.name} will receive a notification about this transaction. Once they confirm, it will become active and track the money flow between you.';
        } else {
          return 'Please review this transaction carefully. If you confirm it, this will track the money ${transaction.isLent ? "you received from" : "you need to pay to"} ${transaction.otherParty.name}.';
        }
      case TransactionStatus.verified:
        if (transaction.isLent) {
          if (isCurrentUserCreator) {
            return 'This transaction is now active. When ${transaction.otherParty.name} pays you back, you can mark it as received to complete the transaction.';
          } else {
            return 'This transaction is confirmed. You can pay back ${transaction.otherParty.name} and they will mark it as received when the payment is complete.';
          }
        } else {
          if (isCurrentUserCreator) {
            return 'This transaction is confirmed. You can pay back ${transaction.otherParty.name} and they will mark it as received when the payment is complete.';
          } else {
            return 'This transaction is now active. When ${transaction.otherParty.name} pays you back, you can mark it as received to complete the transaction.';
          }
        }
      case TransactionStatus.completed:
        return 'This transaction has been completed successfully. The money has been ${transaction.isLent ? (isCurrentUserCreator ? "received by you" : "paid by you") : (isCurrentUserCreator ? "paid by you" : "received by you")}.';
      case TransactionStatus.rejected:
        if (isCurrentUserCreator) {
          return '${transaction.otherParty.name} declined this transaction. No money needs to be exchanged for this transaction.';
        } else {
          return 'You declined this transaction. No money needs to be exchanged for this transaction.';
        }
    }
  }

  static String getBalanceLabel(double balance) {
    if (balance > 0) {
      return 'Net you receive';
    } else if (balance < 0) {
      return 'Net you owe';
    } else {
      return 'Balanced';
    }
  }
}