import 'dart:convert';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class QRTransactionDataModel extends QRTransactionData {
  const QRTransactionDataModel({
    required super.userId,
    required super.userName,
    required super.phoneNumber,
    super.email,
    super.transactionTypeConstraint,
    required super.createdAt,
    super.expiresAt,
    super.version,
  });

  factory QRTransactionDataModel.fromJson(Map<String, dynamic> json) {
    return QRTransactionDataModel(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      transactionTypeConstraint: json['transactionType'] != null
          ? _parseTransactionType(json['transactionType'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      version: json['v'] as String? ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'userId': userId,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'email': email,
      'transactionType': transactionTypeConstraint != null
          ? _transactionTypeToString(transactionTypeConstraint!)
          : null,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  String toQRString() {
    try {
      final jsonString = jsonEncode(toJson());
      return base64Encode(utf8.encode(jsonString));
    } catch (e) {
      throw Exception('Failed to encode QR data: $e');
    }
  }

  factory QRTransactionDataModel.fromQRString(String qrString) {
    try {
      final decodedBytes = base64Decode(qrString);
      final jsonString = utf8.decode(decodedBytes);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return QRTransactionDataModel.fromJson(json);
    } catch (e) {
      throw Exception('Invalid QR code format: $e');
    }
  }

  factory QRTransactionDataModel.fromEntity(QRTransactionData entity) {
    return QRTransactionDataModel(
      userId: entity.userId,
      userName: entity.userName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      transactionTypeConstraint: entity.transactionTypeConstraint,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      version: entity.version,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'lent':
        return TransactionType.lent;
      case 'borrowed':
        return TransactionType.borrowed;
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }

  static String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'lent';
      case TransactionType.borrowed:
        return 'borrowed';
    }
  }

  @override
  QRTransactionDataModel copyWith({
    String? userId,
    String? userName,
    String? phoneNumber,
    String? email,
    TransactionType? transactionTypeConstraint,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? version,
  }) {
    return QRTransactionDataModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      transactionTypeConstraint: transactionTypeConstraint ?? this.transactionTypeConstraint,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      version: version ?? this.version,
    );
  }
}