import 'package:equatable/equatable.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class QRTransactionData extends Equatable {
  final String userId;
  final String userName;
  final String phoneNumber;
  final String? email;
  final TransactionType? transactionTypeConstraint;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String version;

  const QRTransactionData({
    required this.userId,
    required this.userName,
    required this.phoneNumber,
    this.email,
    this.transactionTypeConstraint,
    required this.createdAt,
    this.expiresAt,
    this.version = '1.0',
  });

  QRTransactionData copyWith({
    String? userId,
    String? userName,
    String? phoneNumber,
    String? email,
    TransactionType? transactionTypeConstraint,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? version,
  }) {
    return QRTransactionData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      transactionTypeConstraint: transactionTypeConstraint ?? this.transactionTypeConstraint,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      version: version ?? this.version,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasTransactionConstraint => transactionTypeConstraint != null;

  String get constraintDisplayText {
    switch (transactionTypeConstraint) {
      case TransactionType.lent:
        return 'Lend Only';
      case TransactionType.borrowed:
        return 'Borrow Only';
      case null:
        return 'Any Transaction';
    }
  }

  @override
  List<Object?> get props => [
        userId,
        userName,
        phoneNumber,
        email,
        transactionTypeConstraint,
        createdAt,
        expiresAt,
        version,
      ];
}