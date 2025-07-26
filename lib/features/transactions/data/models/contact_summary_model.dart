import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';

class ContactSummaryModel extends TransactionContact {
  final double totalLending;
  final double totalBorrowing;
  final double netAmount;

  const ContactSummaryModel({
    required super.phone,
    required super.name,
    super.email,
    required super.transactionCount,
    required super.lastTransactionDate,
    this.totalLending = 0.0,
    this.totalBorrowing = 0.0,
    this.netAmount = 0.0,
  });

  factory ContactSummaryModel.fromJson(Map<String, dynamic> json) {
    return ContactSummaryModel(
      phone: json['contactPhone'] as String,
      name: json['contactName'] as String,
      email: json['contactEmail'] as String?,
      transactionCount: json['transactionCount'] as int,
      lastTransactionDate: (json['lastTransactionDate'] as Timestamp).toDate(),
      totalLending: (json['totalLending'] as num?)?.toDouble() ?? 0.0,
      totalBorrowing: (json['totalBorrowing'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactPhone': phone,
      'contactName': name,
      'contactEmail': email,
      'transactionCount': transactionCount,
      'lastTransactionDate': Timestamp.fromDate(lastTransactionDate),
      'totalLending': totalLending,
      'totalBorrowing': totalBorrowing,
      'netAmount': netAmount,
    };
  }

  factory ContactSummaryModel.fromEntity(TransactionContact contact) {
    return ContactSummaryModel(
      phone: contact.phone,
      name: contact.name,
      email: contact.email,
      transactionCount: contact.transactionCount,
      lastTransactionDate: contact.lastTransactionDate,
    );
  }

  @override
  ContactSummaryModel copyWith({
    String? phone,
    String? name,
    String? email,
    int? transactionCount,
    DateTime? lastTransactionDate,
    double? totalLending,
    double? totalBorrowing,
    double? netAmount,
  }) {
    return ContactSummaryModel(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      transactionCount: transactionCount ?? this.transactionCount,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      totalLending: totalLending ?? this.totalLending,
      totalBorrowing: totalBorrowing ?? this.totalBorrowing,
      netAmount: netAmount ?? this.netAmount,
    );
  }
}