import 'package:equatable/equatable.dart';

class UserDevice extends Equatable {
  final String deviceId;
  final String deviceName;
  final String? deviceModel;
  final String platform;
  final DateTime verifiedAt;
  final bool isActive;
  final String? ipAddress;

  const UserDevice({
    required this.deviceId,
    required this.deviceName,
    this.deviceModel,
    required this.platform,
    required this.verifiedAt,
    this.isActive = true,
    this.ipAddress,
  });

  UserDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? platform,
    DateTime? verifiedAt,
    bool? isActive,
    String? ipAddress,
  }) {
    return UserDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      platform: platform ?? this.platform,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isActive: isActive ?? this.isActive,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'platform': platform,
      'verifiedAt': verifiedAt.toIso8601String(),
      'isActive': isActive,
      'ipAddress': ipAddress,
    };
  }

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      deviceModel: json['deviceModel'] as String?,
      platform: json['platform'] as String,
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      ipAddress: json['ipAddress'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        deviceModel,
        platform,
        verifiedAt,
        isActive,
        ipAddress,
      ];
}