import 'package:equatable/equatable.dart';

enum TransactionType { lend, borrow }
enum TransactionStatus { pending, verified, rejected }

class Transaction extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? description;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fromUserName;
  final String? toUserName;
  final String? fromUserPhone;
  final String? toUserPhone;

  const Transaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.fromUserName,
    this.toUserName,
    this.fromUserPhone,
    this.toUserPhone,
  });

  Transaction copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhone,
    String? toUserPhone,
  }) {
    return Transaction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserPhone: fromUserPhone ?? this.fromUserPhone,
      toUserPhone: toUserPhone ?? this.toUserPhone,
    );
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isVerified => status == TransactionStatus.verified;
  bool get isRejected => status == TransactionStatus.rejected;
  bool get isLending => type == TransactionType.lend;
  bool get isBorrowing => type == TransactionType.borrow;
  
  bool get isOverdue {
    if (dueDate == null || isVerified) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        amount,
        type,
        status,
        description,
        dueDate,
        createdAt,
        updatedAt,
        fromUserName,
        toUserName,
        fromUserPhone,
        toUserPhone,
      ];
}