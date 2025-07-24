import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';

class TransactionStatusChip extends StatelessWidget {
  final TransactionStatus status;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const TransactionStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = TransactionUtils.getStatusColor(status);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              TransactionUtils.getStatusIcon(status),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTypeChip extends StatelessWidget {
  final TransactionType type;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const TransactionTypeChip({
    super.key,
    required this.type,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = TransactionUtils.getTypeColor(type);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              TransactionUtils.getTypeIcon(type),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            type.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}