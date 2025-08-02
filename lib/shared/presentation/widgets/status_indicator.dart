import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

class StatusIndicator extends StatelessWidget {
  final Transaction transaction;
  final bool isCurrentUserCreator;
  final bool showActionHint;

  const StatusIndicator({
    super.key,
    required this.transaction,
    required this.isCurrentUserCreator,
    this.showActionHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(), 
                color: _getStatusColor(), 
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusTitle(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          if (showActionHint) ...[
            const SizedBox(height: 4),
            Text(
              TransactionDisplayHelper.getActionRequired(transaction, isCurrentUserCreator),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return Icons.hourglass_empty;
      case TransactionStatus.verified:
        return Icons.verified;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusTitle() {
    return TransactionDisplayHelper.getStatusDescription(
      transaction.status, 
      isCurrentUserCreator,
    );
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
    final theme = Theme.of(context);
    final color = _getStatusColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 3 : 4,
            height: compact ? 3 : 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(compact ? 1.5 : 2),
            ),
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            TransactionDisplayHelper.getSimpleStatusText(transaction.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
    }
  }
}