import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

class TransactionTypeSelector extends StatelessWidget {
  final TransactionType? selectedType;
  final Function(TransactionType) onTypeChanged;
  final bool enabled;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: enabled ? () => onTypeChanged(TransactionType.lent) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: selectedType == TransactionType.lent
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: selectedType == TransactionType.lent
                          ? theme.colorScheme.onPrimary
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lending',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selectedType == TransactionType.lent
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: InkWell(
              onTap: enabled ? () => onTypeChanged(TransactionType.borrowed) : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: selectedType == TransactionType.borrowed
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_down,
                      color: selectedType == TransactionType.borrowed
                          ? theme.colorScheme.onPrimary
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Borrowing',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selectedType == TransactionType.borrowed
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}