import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/data/models/qr_data_model.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.creatorId,
    super.recipientId,
    required super.creatorPhone,
    super.recipientPhone,
    required super.contactName,
    super.contactEmail,
    required super.type,
    required super.amount,
    super.description,
    super.dueDate,
    super.isVerified = false,
    super.verificationRequired = false,
    required super.status,
    super.isDeleted = false,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.deletedBy,
    super.completedAt,
    super.completedBy,
    super.verifiedBy,
    super.qrGeneratedData,
    super.completionRequested = false,
    super.completionRequestedBy,
    super.completionRequestedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      recipientId: json['recipientId'] as String?,
      creatorPhone: json['creatorPhone'] as String,
      recipientPhone: json['recipientPhone'] as String?,
      contactName: json['contactName'] as String,
      contactEmail: json['contactEmail'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null 
          ? (json['dueDate'] as Timestamp).toDate()
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationRequired: json['verificationRequired'] as bool? ?? false,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      deletedAt: json['deletedAt'] != null
          ? (json['deletedAt'] as Timestamp).toDate()
          : null,
      deletedBy: json['deletedBy'] as String?,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: json['completedBy'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      qrGeneratedData: json['qrGeneratedData'] != null
          ? QRDataModel.fromJson(json['qrGeneratedData'] as Map<String, dynamic>)
          : null,
      completionRequested: json['completionRequested'] as bool? ?? false,
      completionRequestedBy: json['completionRequestedBy'] as String?,
      completionRequestedAt: json['completionRequestedAt'] != null
          ? (json['completionRequestedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'recipientId': recipientId,
      'creatorPhone': creatorPhone,
      'recipientPhone': recipientPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'type': type.name,
      'amount': amount,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isVerified': isVerified,
      'verificationRequired': verificationRequired,
      'status': status.name,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'verifiedBy': verifiedBy,
      'qrGeneratedData': qrGeneratedData != null
          ? QRDataModel.fromEntity(qrGeneratedData!).toJson()
          : null,
      'completionRequested': completionRequested,
      'completionRequestedBy': completionRequestedBy,
      'completionRequestedAt': completionRequestedAt != null 
          ? Timestamp.fromDate(completionRequestedAt!) 
          : null,
    };
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      creatorId: transaction.creatorId,
      recipientId: transaction.recipientId,
      creatorPhone: transaction.creatorPhone,
      recipientPhone: transaction.recipientPhone,
      contactName: transaction.contactName,
      contactEmail: transaction.contactEmail,
      type: transaction.type,
      amount: transaction.amount,
      description: transaction.description,
      dueDate: transaction.dueDate,
      isVerified: transaction.isVerified,
      verificationRequired: transaction.verificationRequired,
      status: transaction.status,
      isDeleted: transaction.isDeleted,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      deletedAt: transaction.deletedAt,
      deletedBy: transaction.deletedBy,
      completedAt: transaction.completedAt,
      completedBy: transaction.completedBy,
      verifiedBy: transaction.verifiedBy,
      qrGeneratedData: transaction.qrGeneratedData,
      completionRequested: transaction.completionRequested,
      completionRequestedBy: transaction.completionRequestedBy,
      completionRequestedAt: transaction.completionRequestedAt,
    );
  }

  TransactionModel transformForUser(String userId, {String? userPhone, String? userName}) {
    if (creatorId == userId) {
      return this;
    }
    
    if (recipientId == userId) {
      final flippedType = type == TransactionType.lending 
          ? TransactionType.borrowing 
          : TransactionType.lending;

      return TransactionModel(
        id: id,
        creatorId: userId,
        recipientId: creatorId,
        creatorPhone: userPhone ?? recipientPhone ?? '',
        recipientPhone: creatorPhone,
        contactName: _getCreatorDisplayName(),
        contactEmail: null,
        type: flippedType,
        amount: amount,
        description: description,
        dueDate: dueDate,
        isVerified: isVerified,
        verificationRequired: verificationRequired,
        status: status,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        deletedBy: deletedBy,
        completedAt: completedAt,
        completedBy: completedBy,
        verifiedBy: verifiedBy,
        qrGeneratedData: qrGeneratedData,
        completionRequested: completionRequested,
        completionRequestedBy: completionRequestedBy,
        completionRequestedAt: completionRequestedAt,
      );
    }

    return this;
  }

  String _getCreatorDisplayName() {
    return 'Transaction Partner';
  }

  bool isUserCreator(String userId) => creatorId == userId;
  bool isUserRecipient(String userId) => recipientId == userId;
  bool isUserInvolved(String userId) => isUserCreator(userId) || isUserRecipient(userId);
}