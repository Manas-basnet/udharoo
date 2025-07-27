import 'package:equatable/equatable.dart';

enum TransactionType { lent, borrowed }

enum TransactionStatus { 
  pendingVerification, 
  verified, 
  completed, 
  rejected 
}

class OtherParty extends Equatable {
  final String uid;
  final String name;

  const OtherParty({
    required this.uid,
    required this.name,
  });

  @override
  List<Object?> get props => [uid, name];
}

class DeviceInfo extends Equatable {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? model;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.model,
  });

  @override
  List<Object?> get props => [deviceId, deviceName, platform, model];
}

class TransactionActivity extends Equatable {
  final TransactionStatus action;
  final DateTime timestamp;
  final String performedBy;
  final DeviceInfo? deviceInfo;

  const TransactionActivity({
    required this.action,
    required this.timestamp,
    required this.performedBy,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [action, timestamp, performedBy, deviceInfo];
}

class Transaction extends Equatable {
  final String transactionId;
  final TransactionType type;
  final double amount;
  final OtherParty otherParty;
  final String description;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? completedAt;
  final String createdBy;
  final DeviceInfo? createdFromDevice;
  final List<TransactionActivity> activities;

  const Transaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.otherParty,
    required this.description,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.completedAt,
    required this.createdBy,
    this.createdFromDevice,
    this.activities = const [],
  });

  Transaction copyWith({
    String? transactionId,
    TransactionType? type,
    double? amount,
    OtherParty? otherParty,
    String? description,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? completedAt,
    String? createdBy,
    DeviceInfo? createdFromDevice,
    List<TransactionActivity>? activities,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      otherParty: otherParty ?? this.otherParty,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdFromDevice: createdFromDevice ?? this.createdFromDevice,
      activities: activities ?? this.activities,
    );
  }

  bool get isPending => status == TransactionStatus.pendingVerification;
  bool get isVerified => status == TransactionStatus.verified;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isRejected => status == TransactionStatus.rejected;
  
  bool get isLent => type == TransactionType.lent;
  bool get isBorrowed => type == TransactionType.borrowed;

  DeviceInfo? getDeviceForAction(TransactionStatus action) {
    final activities = this.activities.where((a) => a.action == action).toList();
    if (activities.isEmpty) return null;
    return activities.last.deviceInfo;
  }

  String getDeviceDisplayName(DeviceInfo? device) {
    if (device == null) return 'Unknown Device';
    // if (device.model != null && device.model!.isNotEmpty) {
    //   return device.model!;
    // }
    return device.deviceName;
  }

  @override
  List<Object?> get props => [
        transactionId,
        type,
        amount,
        otherParty,
        description,
        status,
        createdAt,
        verifiedAt,
        completedAt,
        createdBy,
        createdFromDevice,
        activities,
      ];
}