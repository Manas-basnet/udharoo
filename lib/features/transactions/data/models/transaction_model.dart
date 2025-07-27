import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class DeviceInfoModel extends DeviceInfo {
  const DeviceInfoModel({
    required super.deviceId,
    required super.deviceName,
    required super.platform,
    super.model,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'model': model,
    };
  }

  factory DeviceInfoModel.fromEntity(DeviceInfo entity) {
    return DeviceInfoModel(
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      platform: entity.platform,
      model: entity.model,
    );
  }
}

class TransactionActivityModel extends TransactionActivity {
  const TransactionActivityModel({
    required super.action,
    required super.timestamp,
    required super.performedBy,
    super.deviceInfo,
  });

  factory TransactionActivityModel.fromJson(Map<String, dynamic> json) {
    return TransactionActivityModel(
      action: TransactionActivityModel._parseTransactionStatus(json['action'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      performedBy: json['performedBy'] as String,
      deviceInfo: json['deviceInfo'] != null 
          ? DeviceInfoModel.fromJson(json['deviceInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': TransactionActivityModel._transactionStatusToString(action),
      'timestamp': timestamp.toIso8601String(),
      'performedBy': performedBy,
      'deviceInfo': deviceInfo != null 
          ? DeviceInfoModel.fromEntity(deviceInfo!).toJson()
          : null,
    };
  }

  factory TransactionActivityModel.fromEntity(TransactionActivity entity) {
    return TransactionActivityModel(
      action: entity.action,
      timestamp: entity.timestamp,
      performedBy: entity.performedBy,
      deviceInfo: entity.deviceInfo,
    );
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return TransactionStatus.pendingVerification;
      case 'VERIFIED':
        return TransactionStatus.verified;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'REJECTED':
        return TransactionStatus.rejected;
      default:
        throw ArgumentError('Unknown transaction status: $status');
    }
  }

  static String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case TransactionStatus.verified:
        return 'VERIFIED';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }
}

class OtherPartyModel extends OtherParty {
  const OtherPartyModel({
    required super.uid,
    required super.name,
    required super.phoneNumber,
  });

  factory OtherPartyModel.fromJson(Map<String, dynamic> json) {
    return OtherPartyModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory OtherPartyModel.fromEntity(OtherParty entity) {
    return OtherPartyModel(
      uid: entity.uid,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
    );
  }
}

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.transactionId,
    required super.type,
    required super.amount,
    required super.otherParty,
    required super.description,
    required super.status,
    required super.createdAt,
    super.verifiedAt,
    super.completedAt,
    required super.createdBy,
    super.createdFromDevice,
    super.activities = const [],
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'] as String,
      type: _parseTransactionType(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      otherParty: OtherPartyModel.fromJson(json['otherParty'] as Map<String, dynamic>),
      description: json['description'] as String,
      status: _parseTransactionStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      createdBy: json['createdBy'] as String,
      createdFromDevice: json['createdFromDevice'] != null
          ? DeviceInfoModel.fromJson(json['createdFromDevice'] as Map<String, dynamic>)
          : null,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((activity) => TransactionActivityModel.fromJson(activity as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'type': _transactionTypeToString(type),
      'amount': amount,
      'otherParty': OtherPartyModel.fromEntity(otherParty).toJson(),
      'description': description,
      'status': _transactionStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdBy': createdBy,
      'createdFromDevice': createdFromDevice != null
          ? DeviceInfoModel.fromEntity(createdFromDevice!).toJson()
          : null,
      'activities': activities
          .map((activity) => TransactionActivityModel.fromEntity(activity).toJson())
          .toList(),
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      transactionId: entity.transactionId,
      type: entity.type,
      amount: entity.amount,
      otherParty: entity.otherParty,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      verifiedAt: entity.verifiedAt,
      completedAt: entity.completedAt,
      createdBy: entity.createdBy,
      createdFromDevice: entity.createdFromDevice,
      activities: entity.activities,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type.toUpperCase()) {
      case 'LENT':
        return TransactionType.lent;
      case 'BORROWED':
        return TransactionType.borrowed;
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }

  static String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.lent:
        return 'LENT';
      case TransactionType.borrowed:
        return 'BORROWED';
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return TransactionStatus.pendingVerification;
      case 'VERIFIED':
        return TransactionStatus.verified;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'REJECTED':
        return TransactionStatus.rejected;
      default:
        throw ArgumentError('Unknown transaction status: $status');
    }
  }

  static String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case TransactionStatus.verified:
        return 'VERIFIED';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }
}