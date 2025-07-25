import 'package:flutter/material.dart';

class TransactionSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final EdgeInsetsGeometry? padding;

  const TransactionSummaryWidget({
    super.key,
    required this.stats,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLending = (stats['totalLending'] as double?) ?? 0.0;
    final totalBorrowing = (stats['totalBorrowing'] as double?) ?? 0.0;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Lending',
              'NPR ${totalLending.toStringAsFixed(2)}',
              Colors.green,
              Icons.trending_up,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Borrowing',
              'NPR ${totalBorrowing.toStringAsFixed(2)}',
              Colors.orange,
              Icons.trending_down,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionQuickStats extends StatelessWidget {
  final int totalTransactions;
  final int pendingTransactions;
  final int completedTransactions;
  final EdgeInsetsGeometry? padding;

  const TransactionQuickStats({
    super.key,
    required this.totalTransactions,
    required this.pendingTransactions,
    required this.completedTransactions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatItem(
              'Active',
              totalTransactions.toString(),
              theme.colorScheme.primary,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatItem(
              'Pending',
              pendingTransactions.toString(),
              Colors.orange,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatItem(
              'Completed',
              completedTransactions.toString(),
              Colors.green,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}