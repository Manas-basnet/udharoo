import 'package:equatable/equatable.dart';

class TransactionContact extends Equatable {
  final String phone;
  final String name;
  final String? email;
  final int transactionCount;
  final DateTime lastTransactionDate;

  const TransactionContact({
    required this.phone,
    required this.name,
    this.email,
    required this.transactionCount,
    required this.lastTransactionDate,
  });

  TransactionContact copyWith({
    String? phone,
    String? name,
    String? email,
    int? transactionCount,
    DateTime? lastTransactionDate,
  }) {
    return TransactionContact(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      transactionCount: transactionCount ?? this.transactionCount,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }

  @override
  List<Object?> get props => [
        phone,
        name,
        email,
        transactionCount,
        lastTransactionDate,
      ];
}
