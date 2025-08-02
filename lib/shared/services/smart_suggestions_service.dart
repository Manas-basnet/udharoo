import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class SmartSuggestionsService {
  static List<double> getAmountSuggestions({
    String? contactId, 
    List<Transaction>? history,
    List<double>? recentAmounts,
  }) {
    List<double> suggestions = [];
    
    // Contact-based suggestions
    if (contactId != null && history != null) {
      final contactTransactions = history
          .where((t) => t.otherParty.uid == contactId)
          .toList();
      
      if (contactTransactions.isNotEmpty) {
        // Get most common amounts for this contact
        final amounts = contactTransactions.map((t) => t.amount).toList();
        final amountFrequency = <double, int>{};
        
        for (final amount in amounts) {
          amountFrequency[amount] = (amountFrequency[amount] ?? 0) + 1;
        }
        
        // Add most frequent amounts
        final sortedAmounts = amountFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        suggestions.addAll(
          sortedAmounts.take(3).map((e) => e.key)
        );
        
        // Add average amount
        final avgAmount = amounts.fold(0.0, (sum, amount) => sum + amount) / amounts.length;
        suggestions.add(avgAmount.roundToDouble());
      }
    }
    
    // Recent amounts from user's history
    if (recentAmounts != null) {
      suggestions.addAll(recentAmounts.take(5));
    }
    
    // Common amounts
    suggestions.addAll([100, 200, 500, 1000, 2000, 5000, 10000, 25000, 50000]);
    
    // Remove duplicates and sort
    final uniqueSuggestions = suggestions.toSet().toList()
      ..sort();
    
    // Limit to reasonable number
    return uniqueSuggestions.take(8).toList();
  }
  
  static List<String> getDescriptionSuggestions(double amount) {
    if (amount <= 200) {
      return ["Tea/Coffee", "Snacks", "Auto fare", "Parking", "Small expense"];
    } else if (amount <= 500) {
      return ["Lunch", "Breakfast", "Transport", "Medicines", "Stationary"];
    } else if (amount <= 1000) {
      return ["Dinner", "Groceries", "Fuel", "Mobile recharge", "Utilities"];
    } else if (amount <= 5000) {
      return ["Shopping", "Movie", "Travel", "Repair work", "Medical"];
    } else if (amount <= 25000) {
      return ["Emergency", "Medical bills", "Rent", "Electronics", "Travel"];
    } else {
      return ["Emergency fund", "Medical emergency", "Business", "Investment", "Major expense"];
    }
  }
  
  static TransactionType? suggestTransactionType(String contactId, List<Transaction> history) {
    final contactTransactions = history
        .where((t) => t.otherParty.uid == contactId)
        .toList();
    
    if (contactTransactions.isEmpty) return null;
    
    final lentCount = contactTransactions.where((t) => t.isLent).length;
    final borrowedCount = contactTransactions.where((t) => t.isBorrowed).length;
    
    // Suggest based on most common pattern
    return lentCount > borrowedCount ? TransactionType.lent : TransactionType.borrowed;
  }
  
  static List<String> getRecentContacts(List<Transaction> history, {int limit = 5}) {
    final contactFrequency = <String, DateTime>{};
    
    for (final transaction in history) {
      final contactId = transaction.otherParty.uid;
      final existing = contactFrequency[contactId];
      
      if (existing == null || transaction.createdAt.isAfter(existing)) {
        contactFrequency[contactId] = transaction.createdAt;
      }
    }
    
    final sortedContacts = contactFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedContacts.take(limit).map((e) => e.key).toList();
  }
  
  static List<double> getRecentAmounts(List<Transaction> history, {int limit = 5}) {
    final recentTransactions = history.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final amounts = recentTransactions
        .take(20) // Look at last 20 transactions
        .map((t) => t.amount)
        .toSet() // Remove duplicates
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    
    return amounts.take(limit).toList();
  }
  
  static String getQuickDescription(TransactionType type, String contactName) {
    switch (type) {
      case TransactionType.lent:
        return "Gave money to $contactName";
      case TransactionType.borrowed:
        return "Received money from $contactName";
    }
  }
}