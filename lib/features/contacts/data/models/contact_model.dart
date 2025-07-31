import 'package:udharoo/features/contacts/domain/entities/contact.dart';

class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.userId,
    required super.contactUserId,
    required super.name,
    required super.phoneNumber,
    super.email,
    super.photoUrl,
    required super.addedAt,
    required super.lastInteractionAt,
    super.totalTransactions = 0,
    super.totalLent = 0.0,
    super.totalBorrowed = 0.0,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      contactUserId: json['contactUserId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastInteractionAt: DateTime.parse(json['lastInteractionAt'] as String),
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      totalLent: (json['totalLent'] as num?)?.toDouble() ?? 0.0,
      totalBorrowed: (json['totalBorrowed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'contactUserId': contactUserId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'addedAt': addedAt.toIso8601String(),
      'lastInteractionAt': lastInteractionAt.toIso8601String(),
      'totalTransactions': totalTransactions,
      'totalLent': totalLent,
      'totalBorrowed': totalBorrowed,
    };
  }

  factory ContactModel.fromEntity(Contact entity) {
    return ContactModel(
      id: entity.id,
      userId: entity.userId,
      contactUserId: entity.contactUserId,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      photoUrl: entity.photoUrl,
      addedAt: entity.addedAt,
      lastInteractionAt: entity.lastInteractionAt,
      totalTransactions: entity.totalTransactions,
      totalLent: entity.totalLent,
      totalBorrowed: entity.totalBorrowed,
    );
  }

  @override
  ContactModel copyWith({
    String? id,
    String? userId,
    String? contactUserId,
    String? name,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    DateTime? addedAt,
    DateTime? lastInteractionAt,
    int? totalTransactions,
    double? totalLent,
    double? totalBorrowed,
  }) {
    return ContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId: contactUserId ?? this.contactUserId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalLent: totalLent ?? this.totalLent,
      totalBorrowed: totalBorrowed ?? this.totalBorrowed,
    );
  }
}