import 'package:flutter/material.dart';

class TransactionSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool showNetAmount;
  final EdgeInsetsGeometry? padding;

  const TransactionSummaryWidget({
    super.key,
    required this.stats,
    this.showNetAmount = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLending = (stats['totalLending'] as double?) ?? 0.0;
    final totalBorrowing = (stats['totalBorrowing'] as double?) ?? 0.0;
    final netAmount = totalLending - totalBorrowing;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
          
          if (showNetAmount) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: netAmount >= 0 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (netAmount >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Net Amount',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NPR ${netAmount.abs().toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: netAmount >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    netAmount >= 0 
                        ? 'You are owed this amount'
                        : 'You owe this amount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: netAmount >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          color: theme.colorScheme.outline.withOpacity(0.1),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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
              'Total',
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
        color: color.withOpacity(0.1),
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