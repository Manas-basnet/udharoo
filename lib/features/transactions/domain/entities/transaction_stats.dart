import 'package:equatable/equatable.dart';

class TransactionStats extends Equatable {
  final int totalTransactions;
  final int pendingTransactions;
  final int verifiedTransactions;
  final int completedTransactions;
  final double totalLending;
  final double totalBorrowing;
  final double netAmount;

  const TransactionStats({
    required this.totalTransactions,
    required this.pendingTransactions,
    required this.verifiedTransactions,
    required this.completedTransactions,
    required this.totalLending,
    required this.totalBorrowing,
    required this.netAmount,
  });

  TransactionStats copyWith({
    int? totalTransactions,
    int? pendingTransactions,
    int? verifiedTransactions,
    int? completedTransactions,
    double? totalLending,
    double? totalBorrowing,
    double? netAmount,
  }) {
    return TransactionStats(
      totalTransactions: totalTransactions ?? this.totalTransactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      verifiedTransactions: verifiedTransactions ?? this.verifiedTransactions,
      completedTransactions: completedTransactions ?? this.completedTransactions,
      totalLending: totalLending ?? this.totalLending,
      totalBorrowing: totalBorrowing ?? this.totalBorrowing,
      netAmount: netAmount ?? this.netAmount,
    );
  }

  factory TransactionStats.empty() {
    return const TransactionStats(
      totalTransactions: 0,
      pendingTransactions: 0,
      verifiedTransactions: 0,
      completedTransactions: 0,
      totalLending: 0.0,
      totalBorrowing: 0.0,
      netAmount: 0.0,
    );
  }

  @override
  List<Object?> get props => [
        totalTransactions,
        pendingTransactions,
        verifiedTransactions,
        completedTransactions,
        totalLending,
        totalBorrowing,
        netAmount,
      ];
}