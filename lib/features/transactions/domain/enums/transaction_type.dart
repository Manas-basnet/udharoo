enum TransactionType {
  lending,
  borrowing;

  String get displayName {
    switch (this) {
      case TransactionType.lending:
        return 'Lending';
      case TransactionType.borrowing:
        return 'Borrowing';
    }
  }

  String get description {
    switch (this) {
      case TransactionType.lending:
        return 'You are lending money';
      case TransactionType.borrowing:
        return 'You are borrowing money';
    }
  }
}
