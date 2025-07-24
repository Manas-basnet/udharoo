import 'package:equatable/equatable.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final String contactPhone;
  final String contactName;
  final String? contactEmail;
  final String? description;
  final DateTime? dueDate;
  final bool isVerified;
  final bool verificationRequired;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? verifiedBy;
  final QRData? qrGeneratedData;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.contactPhone,
    required this.contactName,
    this.contactEmail,
    this.description,
    this.dueDate,
    this.isVerified = false,
    this.verificationRequired = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.verifiedBy,
    this.qrGeneratedData,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? contactPhone,
    String? contactName,
    String? contactEmail,
    String? description,
    DateTime? dueDate,
    bool? isVerified,
    bool? verificationRequired,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? verifiedBy,
    QRData? qrGeneratedData,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isVerified: isVerified ?? this.isVerified,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      qrGeneratedData: qrGeneratedData ?? this.qrGeneratedData,
    );
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get canBeVerified => status == TransactionStatus.pending && verificationRequired;
  bool get canBeCompleted => status == TransactionStatus.verified || (status == TransactionStatus.pending && !verificationRequired);

  String get formattedAmount {
    return 'NPR ${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        contactPhone,
        contactName,
        contactEmail,
        description,
        dueDate,
        isVerified,
        verificationRequired,
        status,
        createdAt,
        updatedAt,
        createdBy,
        verifiedBy,
        qrGeneratedData,
      ];
}