import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final String id;
  final String userId;
  final String contactUserId;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? photoUrl;
  final DateTime addedAt;
  final DateTime lastInteractionAt;

  const Contact({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.photoUrl,
    required this.addedAt,
    required this.lastInteractionAt,
  });

  Contact copyWith({
    String? id,
    String? userId,
    String? contactUserId,
    String? name,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    DateTime? addedAt,
    DateTime? lastInteractionAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId: contactUserId ?? this.contactUserId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }

  String get displayName => name.trim().isEmpty ? phoneNumber : name;

  String get formattedLastInteraction {
    final now = DateTime.now();
    final difference = now.difference(lastInteractionAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastInteractionAt.day}/${lastInteractionAt.month}/${lastInteractionAt.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        contactUserId,
        name,
        phoneNumber,
        email,
        photoUrl,
        addedAt,
        lastInteractionAt,
      ];
}