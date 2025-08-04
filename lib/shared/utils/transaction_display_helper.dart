import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionDisplayHelper {
  static String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  static String getTransactionAction(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'Lent to';
      case TransactionType.borrowed:
        return 'Borrowed from';
    }
  }

  static String getTransactionDirection(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'Lent';
      case TransactionType.borrowed:
        return 'Borrowed';
    }
  }

  static String getBalanceLabel(double balance) {
    if (balance >= 0) {
      return 'Net Credit';
    } else {
      return 'Net Debit';
    }
  }

  static String getContextualStatusLabel(Transaction transaction, bool isCurrentUserCreator) {
    final isLender = transaction.isLent;
    
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return isLender ? "Awaiting their response" : "Awaiting your response";
      case TransactionStatus.verified:
        return isLender ? "They owe you" : "You owe them";
      case TransactionStatus.completed:
        return isLender ? "Received" : "Paid back";
      case TransactionStatus.rejected:
        return isLender ? "They declined" : "You declined";
    }
  }

  static String getStatusDescription(Transaction transaction, bool isCurrentUserCreator) {
    final isLender = transaction.isLent;
    final contactName = transaction.otherParty.name;
    
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return isLender 
            ? "Waiting for $contactName to confirm this transaction"
            : "You need to confirm this transaction from $contactName";
      case TransactionStatus.verified:
        return isLender 
            ? "$contactName has confirmed they owe you money"
            : "You have confirmed you owe $contactName money";
      case TransactionStatus.completed:
        return isLender 
            ? "You have received the money back from $contactName"
            : "You have paid back the money to $contactName";
      case TransactionStatus.rejected:
        return isLender 
            ? "$contactName declined this transaction"
            : "You declined this transaction from $contactName";
    }
  }

  static String getWhatHappensNext(Transaction transaction, bool isCurrentUserCreator) {
    final isLender = transaction.isLent;
    final contactName = transaction.otherParty.name;
    
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return isLender
            ? "$contactName will receive a notification to confirm this transaction. Once they confirm, you can mark it as paid when you receive the money back."
            : "You need to confirm whether you received money from $contactName. If you confirm, they can mark it as paid when you return the money.";
      case TransactionStatus.verified:
        return isLender
            ? "The transaction is confirmed. You can mark it as 'Received' when $contactName pays you back."
            : "The transaction is confirmed. $contactName will mark it as 'Received' when you pay them back.";
      case TransactionStatus.completed:
        return "This transaction is complete. The money has been returned successfully.";
      case TransactionStatus.rejected:
        return "This transaction was declined and no money exchange took place.";
    }
  }

  static String getActionButtonText(Transaction transaction, bool isCurrentUserCreator) {
    final isLender = transaction.isLent;
    
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return isLender ? "Waiting..." : "Confirm";
      case TransactionStatus.verified:
        return isLender ? "Mark as Received" : "Waiting...";
      case TransactionStatus.completed:
      case TransactionStatus.rejected:
        return "";
    }
  }
}