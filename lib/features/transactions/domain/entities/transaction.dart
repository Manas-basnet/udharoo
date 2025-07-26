import 'package:equatable/equatable.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';

class Transaction extends Equatable {
  final String id;
  final String creatorId;
  final String? recipientId;
  final String creatorPhone;
  final String? recipientPhone;
  final String contactName;
  final String? contactEmail;
  final TransactionType type;
  final double amount;
  final String? description;
  final DateTime? dueDate;
  final bool isVerified;
  final bool verificationRequired;
  final TransactionStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? completedAt;
  final String? completedBy;
  final String? verifiedBy;
  final QRData? qrGeneratedData;
  final bool completionRequested;
  final String? completionRequestedBy;
  final DateTime? completionRequestedAt;

  const Transaction({
    required this.id,
    required this.creatorId,
    this.recipientId,
    required this.creatorPhone,
    this.recipientPhone,
    required this.contactName,
    this.contactEmail,
    required this.type,
    required this.amount,
    this.description,
    this.dueDate,
    this.isVerified = false,
    this.verificationRequired = false,
    required this.status,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.completedAt,
    this.completedBy,
    this.verifiedBy,
    this.qrGeneratedData,
    this.completionRequested = false,
    this.completionRequestedBy,
    this.completionRequestedAt,
  });

  Transaction copyWith({
    String? id,
    String? creatorId,
    String? recipientId,
    String? creatorPhone,
    String? recipientPhone,
    String? contactName,
    String? contactEmail,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool? isVerified,
    bool? verificationRequired,
    TransactionStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? completedAt,
    String? completedBy,
    String? verifiedBy,
    QRData? qrGeneratedData,
    bool? completionRequested,
    String? completionRequestedBy,
    DateTime? completionRequestedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      recipientId: recipientId ?? this.recipientId,
      creatorPhone: creatorPhone ?? this.creatorPhone,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isVerified: isVerified ?? this.isVerified,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      qrGeneratedData: qrGeneratedData ?? this.qrGeneratedData,
      completionRequested: completionRequested ?? this.completionRequested,
      completionRequestedBy: completionRequestedBy ?? this.completionRequestedBy,
      completionRequestedAt: completionRequestedAt ?? this.completionRequestedAt,
    );
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get canBeVerified => status == TransactionStatus.pending && verificationRequired && !isVerified;
  bool get canBeCompleted => status == TransactionStatus.verified || (status == TransactionStatus.pending && !verificationRequired);
  bool get canRequestCompletion => !isCompleted && !completionRequested && status != TransactionStatus.cancelled;

  String get formattedAmount {
    return 'NPR ${amount.toStringAsFixed(2)}';
  }

  bool get hasValidRecipient => recipientPhone != null && recipientId != null;

  String get contactPhone => recipientPhone ?? creatorPhone;
  
  String get createdBy => creatorId;

  @override
  List<Object?> get props => [
        id,
        creatorId,
        recipientId,
        creatorPhone,
        recipientPhone,
        contactName,
        contactEmail,
        type,
        amount,
        description,
        dueDate,
        isVerified,
        verificationRequired,
        status,
        isDeleted,
        createdAt,
        updatedAt,
        deletedAt,
        deletedBy,
        completedAt,
        completedBy,
        verifiedBy,
        qrGeneratedData,
        completionRequested,
        completionRequestedBy,
        completionRequestedAt,
      ];
}