import 'package:equatable/equatable.dart';

class QRData extends Equatable {
  final String userPhone;
  final String userName;
  final String? userEmail;
  final bool verificationRequired;
  final DateTime generatedAt;
  final String? customMessage;

  const QRData({
    required this.userPhone,
    required this.userName,
    this.userEmail,
    required this.verificationRequired,
    required this.generatedAt,
    this.customMessage,
  });

  QRData copyWith({
    String? userPhone,
    String? userName,
    String? userEmail,
    bool? verificationRequired,
    DateTime? generatedAt,
    String? customMessage,
  }) {
    return QRData(
      userPhone: userPhone ?? this.userPhone,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      generatedAt: generatedAt ?? this.generatedAt,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  @override
  List<Object?> get props => [
        userPhone,
        userName,
        userEmail,
        verificationRequired,
        generatedAt,
        customMessage,
      ];
}
