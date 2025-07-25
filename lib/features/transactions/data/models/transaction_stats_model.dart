import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';

class TransactionStatsModel extends TransactionStats {
  const TransactionStatsModel({
    required super.totalTransactions,
    required super.pendingTransactions,
    required super.verifiedTransactions,
    required super.completedTransactions,
    required super.totalLending,
    required super.totalBorrowing,
    required super.netAmount,
  });

  factory TransactionStatsModel.fromJson(Map<String, dynamic> json) {
    final totalLending = (json['totalLending'] as num?)?.toDouble() ?? 0.0;
    final totalBorrowing = (json['totalBorrowing'] as num?)?.toDouble() ?? 0.0;
    
    return TransactionStatsModel(
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      pendingTransactions: json['pendingTransactions'] as int? ?? 0,
      verifiedTransactions: json['verifiedTransactions'] as int? ?? 0,
      completedTransactions: json['completedTransactions'] as int? ?? 0,
      totalLending: totalLending,
      totalBorrowing: totalBorrowing,
      netAmount: totalLending - totalBorrowing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'pendingTransactions': pendingTransactions,
      'verifiedTransactions': verifiedTransactions,
      'completedTransactions': completedTransactions,
      'totalLending': totalLending,
      'totalBorrowing': totalBorrowing,
      'netAmount': netAmount,
    };
  }

  factory TransactionStatsModel.fromEntity(TransactionStats stats) {
    return TransactionStatsModel(
      totalTransactions: stats.totalTransactions,
      pendingTransactions: stats.pendingTransactions,
      verifiedTransactions: stats.verifiedTransactions,
      completedTransactions: stats.completedTransactions,
      totalLending: stats.totalLending,
      totalBorrowing: stats.totalBorrowing,
      netAmount: stats.netAmount,
    );
  }
}