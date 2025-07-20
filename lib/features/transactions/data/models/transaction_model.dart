import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.fromUserId,
    required super.toUserId,
    required super.amount,
    required super.type,
    required super.status,
    super.description,
    super.dueDate,
    required super.createdAt,
    super.updatedAt,
    super.fromUserName,
    super.toUserName,
    super.fromUserPhone,
    super.toUserPhone,
  });

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      fromUserId: transaction.fromUserId,
      toUserId: transaction.toUserId,
      amount: transaction.amount,
      type: transaction.type,
      status: transaction.status,
      description: transaction.description,
      dueDate: transaction.dueDate,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      fromUserName: transaction.fromUserName,
      toUserName: transaction.toUserName,
      fromUserPhone: transaction.fromUserPhone,
      toUserPhone: transaction.toUserPhone,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TransactionModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.lend,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: data['description'] as String?,
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      fromUserName: data['fromUserName'] as String?,
      toUserName: data['toUserName'] as String?,
      fromUserPhone: data['fromUserPhone'] as String?,
      toUserPhone: data['toUserPhone'] as String?,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.lend,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      fromUserName: json['fromUserName'] as String?,
      toUserName: json['toUserName'] as String?,
      fromUserPhone: json['fromUserPhone'] as String?,
      toUserPhone: json['toUserPhone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserPhone': fromUserPhone,
      'toUserPhone': toUserPhone,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserPhone': fromUserPhone,
      'toUserPhone': toUserPhone,
    };
  }

  @override
  TransactionModel copyWith({
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
    return TransactionModel(
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
}