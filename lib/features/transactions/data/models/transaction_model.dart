import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/data/models/qr_data_model.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.contactPhone,
    required super.contactName,
    super.contactEmail,
    super.description,
    super.dueDate,
    super.isVerified = false,
    super.verificationRequired = false,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.verifiedBy,
    super.qrGeneratedData,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      contactPhone: json['contactPhone'] as String,
      contactName: json['contactName'] as String,
      contactEmail: json['contactEmail'] as String?,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationRequired: json['verificationRequired'] as bool? ?? false,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
      verifiedBy: json['verifiedBy'] as String?,
      qrGeneratedData: json['qrGeneratedData'] != null
          ? QRDataModel.fromJson(json['qrGeneratedData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isVerified': isVerified,
      'verificationRequired': verificationRequired,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'verifiedBy': verifiedBy,
      'qrGeneratedData': qrGeneratedData != null
          ? QRDataModel.fromEntity(qrGeneratedData!).toJson()
          : null,
    };
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      contactPhone: transaction.contactPhone,
      contactName: transaction.contactName,
      contactEmail: transaction.contactEmail,
      description: transaction.description,
      dueDate: transaction.dueDate,
      isVerified: transaction.isVerified,
      verificationRequired: transaction.verificationRequired,
      status: transaction.status,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      createdBy: transaction.createdBy,
      verifiedBy: transaction.verifiedBy,
      qrGeneratedData: transaction.qrGeneratedData,
    );
  }
}