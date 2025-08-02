import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionDisplayHelper {
  static String getTransactionDirection(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return "They owe me";
      case TransactionType.borrowed:
        return "I owe them";
    }
  }
  
  static String getTransactionAction(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return "I gave money to";
      case TransactionType.borrowed:
        return "I received money from";
    }
  }
  
  static String getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return "I gave money";
      case TransactionType.borrowed:
        return "I received money";
    }
  }
  
  static String getTransactionTypeDescription(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return "They owe me money";
      case TransactionType.borrowed:
        return "I owe them money";
    }
  }
  
  static String getStatusDescription(TransactionStatus status, bool isLender) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return isLender ? "Waiting for them to confirm" : "Please confirm this transaction";
      case TransactionStatus.verified:
        return "Confirmed - Waiting for payment";
      case TransactionStatus.completed:
        return "✅ Paid back";
      case TransactionStatus.rejected:
        return "❌ Declined";
    }
  }
  
  static String getActionRequired(Transaction transaction, bool isCurrentUserCreator) {
    if (transaction.isPending && !isCurrentUserCreator) {
      return "Tap to confirm this transaction";
    }
    if (transaction.isVerified && transaction.isLent) {
      return "Waiting for payment";
    }
    if (transaction.isCompleted) {
      return "All done! ✅";
    }
    if (transaction.isRejected) {
      return "Transaction was declined";
    }
    return "";
  }
  
  static String getSimpleStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return "Pending";
      case TransactionStatus.verified:
        return "Confirmed";
      case TransactionStatus.completed:
        return "Paid";
      case TransactionStatus.rejected:
        return "Declined";
    }
  }
  
  static String getWhatHappensNext(Transaction transaction, bool isCurrentUserCreator) {
    if (transaction.isPending) {
      if (isCurrentUserCreator) {
        return "Wait for ${transaction.otherParty.name} to confirm this transaction.";
      } else {
        return "Please confirm if this transaction is correct.";
      }
    }
    
    if (transaction.isVerified) {
      if (transaction.isLent) {
        return "Wait for ${transaction.otherParty.name} to pay you back.";
      } else {
        return "Pay back ${transaction.otherParty.name} when convenient.";
      }
    }
    
    if (transaction.isCompleted) {
      return "This transaction is complete. No further action needed.";
    }
    
    if (transaction.isRejected) {
      return "This transaction was declined. You can create a new one if needed.";
    }
    
    return "";
  }
  
  static String formatAmount(double amount) {
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
  
  static String getBalanceLabel(double netBalance) {
    if (netBalance > 0) {
      return "People owe you";
    } else if (netBalance < 0) {
      return "You owe people";
    } else {
      return "All settled";
    }
  }
}