import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class OtherPartyModel extends OtherParty {
  const OtherPartyModel({
    required super.uid,
    required super.name,
  });

  factory OtherPartyModel.fromJson(Map<String, dynamic> json) {
    return OtherPartyModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
    };
  }

  factory OtherPartyModel.fromEntity(OtherParty entity) {
    return OtherPartyModel(
      uid: entity.uid,
      name: entity.name,
    );
  }
}

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.transactionId,
    required super.type,
    required super.amount,
    required super.otherParty,
    required super.description,
    required super.status,
    required super.createdAt,
    super.verifiedAt,
    super.completedAt,
    required super.createdBy,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'] as String,
      type: _parseTransactionType(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      otherParty: OtherPartyModel.fromJson(json['otherParty'] as Map<String, dynamic>),
      description: json['description'] as String,
      status: _parseTransactionStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'type': _transactionTypeToString(type),
      'amount': amount,
      'otherParty': OtherPartyModel.fromEntity(otherParty).toJson(),
      'description': description,
      'status': _transactionStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      transactionId: entity.transactionId,
      type: entity.type,
      amount: entity.amount,
      otherParty: entity.otherParty,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      verifiedAt: entity.verifiedAt,
      completedAt: entity.completedAt,
      createdBy: entity.createdBy,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type.toUpperCase()) {
      case 'LENT':
        return TransactionType.lent;
      case 'BORROWED':
        return TransactionType.borrowed;
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }

  static String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'LENT';
      case TransactionType.borrowed:
        return 'BORROWED';
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return TransactionStatus.pendingVerification;
      case 'VERIFIED':
        return TransactionStatus.verified;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'REJECTED':
        return TransactionStatus.rejected;
      default:
        throw ArgumentError('Unknown transaction status: $status');
    }
  }

  static String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case TransactionStatus.verified:
        return 'VERIFIED';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }
}