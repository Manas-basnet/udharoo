import 'package:equatable/equatable.dart';

enum TransactionType { lent, borrowed }

enum TransactionStatus { 
  pendingVerification, 
  verified, 
  completed, 
  rejected 
}

class OtherParty extends Equatable {
  final String uid;
  final String name;

  const OtherParty({
    required this.uid,
    required this.name,
  });

  @override
  List<Object?> get props => [uid, name];
}

class Transaction extends Equatable {
  final String transactionId;
  final TransactionType type;
  final double amount;
  final OtherParty otherParty;
  final String description;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? completedAt;
  final String createdBy;

  const Transaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.otherParty,
    required this.description,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.completedAt,
    required this.createdBy,
  });

  Transaction copyWith({
    String? transactionId,
    TransactionType? type,
    double? amount,
    OtherParty? otherParty,
    String? description,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? completedAt,
    String? createdBy,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      otherParty: otherParty ?? this.otherParty,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isPending => status == TransactionStatus.pendingVerification;
  bool get isVerified => status == TransactionStatus.verified;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isRejected => status == TransactionStatus.rejected;
  
  bool get isLent => type == TransactionType.lent;
  bool get isBorrowed => type == TransactionType.borrowed;

  @override
  List<Object?> get props => [
        transactionId,
        type,
        amount,
        otherParty,
        description,
        status,
        createdAt,
        verifiedAt,
        completedAt,
        createdBy,
      ];
}