import 'package:equatable/equatable.dart';

class ContactHistory extends Equatable {
  final String phoneNumber;
  final String name;
  final DateTime lastUsed;
  final int transactionCount;
  final String? userId;

  const ContactHistory({
    required this.phoneNumber,
    required this.name,
    required this.lastUsed,
    this.transactionCount = 1,
    this.userId,
  });

  ContactHistory copyWith({
    String? phoneNumber,
    String? name,
    DateTime? lastUsed,
    int? transactionCount,
    String? userId,
  }) {
    return ContactHistory(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      lastUsed: lastUsed ?? this.lastUsed,
      transactionCount: transactionCount ?? this.transactionCount,
      userId: userId ?? this.userId,
    );
  }

  ContactHistory incrementUsage() {
    return copyWith(
      lastUsed: DateTime.now(),
      transactionCount: transactionCount + 1,
    );
  }

  ContactHistory updateName(String newName) {
    return copyWith(
      name: newName,
      lastUsed: DateTime.now(),
    );
  }

  String get displayName => name.trim().isEmpty ? phoneNumber : name;

  String get formattedLastUsed {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

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
      return '${lastUsed.day}/${lastUsed.month}/${lastUsed.year}';
    }
  }

  @override
  List<Object?> get props => [
        phoneNumber,
        name,
        lastUsed,
        transactionCount,
        userId,
      ];
}