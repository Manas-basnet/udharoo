import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';

class QRDataModel extends QRData {
  const QRDataModel({
    required super.userPhone,
    required super.userName,
    super.userEmail,
    required super.verificationRequired,
    required super.generatedAt,
    super.customMessage,
  });

  factory QRDataModel.fromJson(Map<String, dynamic> json) {
    return QRDataModel(
      userPhone: json['userPhone'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String?,
      verificationRequired: json['verificationRequired'] as bool,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      customMessage: json['customMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userPhone': userPhone,
      'userName': userName,
      'userEmail': userEmail,
      'verificationRequired': verificationRequired,
      'generatedAt': generatedAt.toIso8601String(),
      'customMessage': customMessage,
    };
  }

  factory QRDataModel.fromEntity(QRData qrData) {
    return QRDataModel(
      userPhone: qrData.userPhone,
      userName: qrData.userName,
      userEmail: qrData.userEmail,
      verificationRequired: qrData.verificationRequired,
      generatedAt: qrData.generatedAt,
      customMessage: qrData.customMessage,
    );
  }
}
