import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

class StatusIndicator extends StatelessWidget {
  final Transaction transaction;
  final bool isCurrentUserCreator;
  final bool compact;

  const StatusIndicator({
    super.key,
    required this.transaction,
    required this.isCurrentUserCreator,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (compact) {
      return _buildCompactChip(theme);
    }
    
    return _buildFullIndicator(theme);
  }

  Widget _buildCompactChip(ThemeData theme) {
    final statusData = _getStatusData();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusData.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusData.color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusData.icon,
            size: 12,
            color: statusData.color,
          ),
          const SizedBox(width: 4),
          Text(
            TransactionDisplayHelper.getContextualStatusLabel(transaction, isCurrentUserCreator),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusData.color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullIndicator(ThemeData theme) {
    final statusData = _getStatusData();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusData.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusData.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusData.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusData.icon,
                  size: 20,
                  color: statusData.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TransactionDisplayHelper.getContextualStatusLabel(transaction, isCurrentUserCreator),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusData.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TransactionDisplayHelper.getStatusDescription(transaction, isCurrentUserCreator),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StatusData _getStatusData() {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return _StatusData(
          color: Colors.orange,
          icon: Icons.hourglass_empty_rounded,
        );
      case TransactionStatus.verified:
        return _StatusData(
          color: Colors.blue,
          icon: Icons.verified_rounded,
        );
      case TransactionStatus.completed:
        return _StatusData(
          color: Colors.green,
          icon: Icons.check_circle_rounded,
        );
      case TransactionStatus.rejected:
        return _StatusData(
          color: Colors.red,
          icon: Icons.cancel_rounded,
        );
    }
  }
}

class QuickStatusChip extends StatelessWidget {
  final Transaction transaction;
  final bool compact;

  const QuickStatusChip({
    super.key,
    required this.transaction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusIndicator(
      transaction: transaction,
      isCurrentUserCreator: transaction.isLent,
      compact: compact,
    );
  }
}

class _StatusData {
  final Color color;
  final IconData icon;

  _StatusData({
    required this.color,
    required this.icon,
  });
}