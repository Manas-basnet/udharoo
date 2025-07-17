import 'package:equatable/equatable.dart';

class QrTransactionData extends Equatable {
  final String userId;
  final String userName;
  final String? userPhone;
  final double? amount;
  final String? description;
  final DateTime? dueDate;
  final bool requiresVerification;
  final String qrType;

  const QrTransactionData({
    required this.userId,
    required this.userName,
    this.userPhone,
    this.amount,
    this.description,
    this.dueDate,
    this.requiresVerification = true,
    this.qrType = 'transaction',
  });

  factory QrTransactionData.fromJson(Map<String, dynamic> json) {
    return QrTransactionData(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      requiresVerification: json['requiresVerification'] as bool? ?? true,
      qrType: json['qrType'] as String? ?? 'transaction',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'amount': amount,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'requiresVerification': requiresVerification,
      'qrType': qrType,
    };
  }

  QrTransactionData copyWith({
    String? userId,
    String? userName,
    String? userPhone,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool? requiresVerification,
    String? qrType,
  }) {
    return QrTransactionData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      qrType: qrType ?? this.qrType,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        userName,
        userPhone,
        amount,
        description,
        dueDate,
        requiresVerification,
        qrType,
      ];
}