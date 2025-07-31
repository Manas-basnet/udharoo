import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';

class ContactHistoryModel extends ContactHistory {
  const ContactHistoryModel({
    required super.phoneNumber,
    required super.name,
    required super.lastUsed,
    super.transactionCount = 1,
    super.userId,
  });

  factory ContactHistoryModel.fromJson(Map<String, dynamic> json) {
    return ContactHistoryModel(
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      transactionCount: json['transactionCount'] as int? ?? 1,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'lastUsed': lastUsed.toIso8601String(),
      'transactionCount': transactionCount,
      'userId': userId,
    };
  }

  factory ContactHistoryModel.fromEntity(ContactHistory entity) {
    return ContactHistoryModel(
      phoneNumber: entity.phoneNumber,
      name: entity.name,
      lastUsed: entity.lastUsed,
      transactionCount: entity.transactionCount,
      userId: entity.userId,
    );
  }

  String get storageKey {
    final userPrefix = userId != null ? '${userId}_' : '';
    return '${userPrefix}contact_$phoneNumber';
  }

  @override
  ContactHistoryModel copyWith({
    String? phoneNumber,
    String? name,
    DateTime? lastUsed,
    int? transactionCount,
    String? userId,
  }) {
    return ContactHistoryModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      lastUsed: lastUsed ?? this.lastUsed,
      transactionCount: transactionCount ?? this.transactionCount,
      userId: userId ?? this.userId,
    );
  }

  @override
  ContactHistoryModel incrementUsage() {
    return copyWith(
      lastUsed: DateTime.now(),
      transactionCount: transactionCount + 1,
    );
  }

  @override
  ContactHistoryModel updateName(String newName) {
    return copyWith(
      name: newName,
      lastUsed: DateTime.now(),
    );
  }
}