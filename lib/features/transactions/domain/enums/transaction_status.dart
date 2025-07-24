enum TransactionStatus {
  pending,
  verified,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.verified:
        return 'Verified';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this != TransactionStatus.cancelled;
  bool get isCompleted => this == TransactionStatus.completed;
  bool get needsVerification => this == TransactionStatus.pending;
}