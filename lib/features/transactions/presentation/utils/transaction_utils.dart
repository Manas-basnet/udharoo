import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';

class TransactionUtils {
  static Color getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.lending:
        return Colors.green;
      case TransactionType.borrowing:
        return Colors.orange;
    }
  }

  static IconData getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.lending:
        return Icons.trending_up;
      case TransactionType.borrowing:
        return Icons.trending_down;
    }
  }

  static Color getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  static IconData getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.verified:
        return Icons.verified;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }

  static String formatCurrency(double amount, {String currency = 'NPR'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatSimpleDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static bool isDueDatePassed(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  static bool isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanPhone.length >= 7 && cleanPhone.length <= 15;
  }

  static bool isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidAmount(double? amount) {
    return amount != null && amount > 0;
  }

  static String? validatePhoneNumber(String? phone, {bool required = false}) {
    if (!required && (phone == null || phone.isEmpty)) {
      return null;
    }
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhoneNumber(phone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateContactName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Contact name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email != null && email.isNotEmpty && !isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String getTransactionSummary(Transaction transaction) {
    final typeText = transaction.type == TransactionType.lending ? 'lent' : 'borrowed';
    return 'You $typeText ${formatCurrency(transaction.amount)} ${transaction.type == TransactionType.lending ? 'to' : 'from'} ${transaction.contactName}';
  }

  static List<Transaction> filterTransactions(
    List<Transaction> transactions, {
    TransactionStatus? status,
    TransactionType? type,
    String? searchQuery,
  }) {
    var filtered = transactions;

    if (status != null) {
      filtered = filtered.where((t) => t.status == status).toList();
    }

    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
          t.contactName.toLowerCase().contains(query) ||
          (t.contactPhone?.contains(searchQuery) ?? false) ||
          (t.description?.toLowerCase().contains(query) ?? false)).toList();
    }

    return filtered;
  }

  static TransactionStats calculateTransactionSummary(List<Transaction> transactions) {
    double totalLending = 0;
    double totalBorrowing = 0;
    int pendingTransactions = 0;
    int verifiedTransactions = 0;
    int completedTransactions = 0;

    for (final transaction in transactions) {
      if (transaction.status != TransactionStatus.cancelled && transaction.status != TransactionStatus.completed) {
        if (transaction.type == TransactionType.lending) {
          totalLending += transaction.amount;
          if (transaction.status == TransactionStatus.pending) {
            pendingTransactions++;
          } else if (transaction.status == TransactionStatus.verified) {
            verifiedTransactions++;
          }
        } else {
          totalBorrowing += transaction.amount;
          if (transaction.status == TransactionStatus.pending) {
            pendingTransactions++;
          } else if (transaction.status == TransactionStatus.verified) {
            verifiedTransactions++;
          }
        }
      } else if (transaction.status == TransactionStatus.completed) {
        completedTransactions++;
      }
    }

    return TransactionStats(
      totalTransactions: transactions.length,
      pendingTransactions: pendingTransactions,
      verifiedTransactions: verifiedTransactions,
      completedTransactions: completedTransactions,
      totalLending: totalLending,
      totalBorrowing: totalBorrowing,
      netAmount: totalLending - totalBorrowing,
    );
  }

  static String getTransactionIdentifier(Transaction transaction) {
    if (transaction.contactPhone != null) {
      return '${transaction.contactName} (${transaction.contactPhone})';
    }
    return transaction.contactName;
  }

  static bool requiresVerification(Transaction transaction) {
    return transaction.verificationRequired && transaction.contactPhone != null;
  }

  static bool canUserVerify(Transaction transaction, String currentUserId) {
    return transaction.verificationRequired && 
           transaction.recipientUserId == currentUserId && 
           !transaction.isVerified &&
           transaction.status == TransactionStatus.pending;
  }

  static bool canUserComplete(Transaction transaction, String currentUserId) {
    if (transaction.status == TransactionStatus.completed || transaction.status == TransactionStatus.cancelled) {
      return false;
    }

    if (transaction.verificationRequired && !transaction.isVerified) {
      return false;
    }

    final isCreator = transaction.createdBy == currentUserId;
    final isRecipient = transaction.recipientUserId == currentUserId;

    if (transaction.type == TransactionType.lending) {
      return isCreator;
    } else {
      return isRecipient;
    }
  }

  static bool canUserRequestCompletion(Transaction transaction, String currentUserId) {
    if (!transaction.canRequestCompletion) {
      return false;
    }

    final isCreator = transaction.createdBy == currentUserId;
    final isRecipient = transaction.recipientUserId == currentUserId;

    if (transaction.type == TransactionType.lending) {
      return isRecipient && transaction.recipientUserId != null;
    } else {
      return isCreator;
    }
  }

  static String getCompletionButtonText(Transaction transaction, String currentUserId) {
    final isCreator = transaction.createdBy == currentUserId;
    
    if (transaction.type == TransactionType.lending && isCreator) {
      return 'Mark as Completed';
    } else if (transaction.type == TransactionType.borrowing && !isCreator) {
      return 'Mark as Completed';
    }
    
    return 'Complete';
  }
}