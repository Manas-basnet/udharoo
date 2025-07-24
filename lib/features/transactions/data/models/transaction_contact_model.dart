import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';

class TransactionContactModel extends TransactionContact {
  const TransactionContactModel({
    required super.phone,
    required super.name,
    super.email,
    required super.transactionCount,
    required super.lastTransactionDate,
  });

  factory TransactionContactModel.fromJson(Map<String, dynamic> json) {
    return TransactionContactModel(
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      transactionCount: json['transactionCount'] as int,
      lastTransactionDate: DateTime.parse(json['lastTransactionDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'name': name,
      'email': email,
      'transactionCount': transactionCount,
      'lastTransactionDate': lastTransactionDate.toIso8601String(),
    };
  }

  factory TransactionContactModel.fromEntity(TransactionContact contact) {
    return TransactionContactModel(
      phone: contact.phone,
      name: contact.name,
      email: contact.email,
      transactionCount: contact.transactionCount,
      lastTransactionDate: contact.lastTransactionDate,
    );
  }
}
