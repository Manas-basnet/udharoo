import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionDisplayHelper {
  static String formatAmount(double amount) {
    if (amount == 0) return '0';
    
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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

  static String getContextualStatusLabel(Transaction transaction, bool isCurrentUserLender) {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserLender) {
          return 'Awaiting confirmation';
        } else {
          return 'Needs your response';
        }
      case TransactionStatus.verified:
        if (isCurrentUserLender) {
          return 'They owe you';
        } else {
          return 'You owe them';
        }
      case TransactionStatus.completed:
        if (isCurrentUserLender) {
          return 'Money received';
        } else {
          return 'Money paid back';
        }
      case TransactionStatus.rejected:
        return 'Declined';
    }
  }

  static String getStatusDescription(Transaction transaction, bool isCurrentUserLender) {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserLender) {
          return 'Waiting for ${transaction.otherParty.name} to confirm';
        } else {
          return 'Please confirm or decline this transaction';
        }
      case TransactionStatus.verified:
        if (isCurrentUserLender) {
          return 'Confirmed - waiting for payment';
        } else {
          return 'Confirmed - you need to pay back';
        }
      case TransactionStatus.completed:
        if (isCurrentUserLender) {
          return 'Transaction completed - money received';
        } else {
          return 'Transaction completed - money paid back';
        }
      case TransactionStatus.rejected:
        if (isCurrentUserLender) {
          return 'Transaction was declined by ${transaction.otherParty.name}';
        } else {
          return 'You declined this transaction';
        }
    }
  }

  static String getWhatHappensNext(Transaction transaction, bool isCurrentUserCreator) {
    final isCurrentUserLender = transaction.isLent;
    
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        if (isCurrentUserCreator) {
          return 'Waiting for ${transaction.otherParty.name} to confirm this transaction. They will receive a notification and can accept or decline.';
        } else {
          return 'Please review and confirm this transaction. You can accept if the details are correct, or decline if there\'s an issue.';
        }
        
      case TransactionStatus.verified:
        if (isCurrentUserLender) {
          return 'Transaction confirmed! When ${transaction.otherParty.name} pays you back, you can mark it as received to complete the transaction.';
        } else {
          return 'Transaction confirmed! When you pay back ${transaction.otherParty.name}, they will mark it as received to complete the transaction.';
        }
        
      case TransactionStatus.completed:
        if (isCurrentUserLender) {
          return 'Transaction completed! You have successfully received the money back from ${transaction.otherParty.name}.';
        } else {
          return 'Transaction completed! You have successfully paid back the money to ${transaction.otherParty.name}.';
        }
        
      case TransactionStatus.rejected:
        if (isCurrentUserCreator) {
          return 'This transaction was declined by ${transaction.otherParty.name}. You can create a new transaction if needed.';
        } else {
          return 'You declined this transaction. ${transaction.otherParty.name} can create a new transaction if needed.';
        }
    }
  }

  static String getBalanceLabel(double netBalance) {
    if (netBalance > 0) {
      return 'Net Credit';
    } else if (netBalance < 0) {
      return 'Net Debt';
    } else {
      return 'Balanced';
    }
  }

  static List<Transaction> getActiveTransactions(List<Transaction> transactions) {
    return transactions.where((t) => t.isVerified).toList();
  }

  static double calculateActiveAmountOwedToYou(List<Transaction> transactions) {
    return getActiveTransactions(transactions)
        .where((t) => t.isLent)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double calculateActiveAmountYouOwe(List<Transaction> transactions) {
    return getActiveTransactions(transactions)
        .where((t) => t.isBorrowed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}