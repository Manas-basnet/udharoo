import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTransactionColor(theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTransactionIcon(),
                    color: _getTransactionColor(theme),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.otherParty.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.isLent ? '+' : '-'}Rs. ${transaction.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getTransactionColor(theme),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(theme).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(theme),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getFormattedDate(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (_shouldShowActionButtons()) ..._buildActionButtons(context, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionColor(ThemeData theme) {
    return transaction.isLent 
        ? theme.colorScheme.primary 
        : theme.colorScheme.error;
  }

  IconData _getTransactionIcon() {
    return transaction.isLent 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;
  }

  Color _getStatusColor(ThemeData theme) {
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

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.pendingVerification:
        return 'PENDING';
      case TransactionStatus.verified:
        return 'VERIFIED';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }

  String _getFormattedDate() {
    final date = transaction.createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool _shouldShowActionButtons() {
    // Show action buttons for pending transactions that the user didn't create
    // or for verified transactions that can be completed
    return (transaction.isPending && !_isCreatedByCurrentUser()) ||
           (transaction.isVerified && _canCompleteTransaction());
  }

  bool _isCreatedByCurrentUser() {
    // This would need to be passed from the parent or accessed via a service
    // For now, we'll assume it's determined by the transaction type
    return transaction.isLent;
  }

  bool _canCompleteTransaction() {
    // Lent transactions can be marked as completed by the lender
    // Borrowed transactions can be marked as completed by the borrower
    return transaction.isVerified;
  }

  List<Widget> _buildActionButtons(BuildContext context, ThemeData theme) {
    final cubit = context.read<TransactionCubit>();
    
    final buttons = <Widget>[];

    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      // Borrower can verify or reject
      buttons.addAll([
        _ActionButton(
          label: 'Verify',
          color: Colors.green,
          onPressed: () {
            cubit.verifyTransaction(transaction.transactionId);
            CustomToast.show(context, message: 'Transaction verified', isSuccess: true);
          },
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: 'Reject',
          color: Colors.red,
          onPressed: () => _showRejectDialog(context, cubit),
        ),
      ]);
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      // Either party can mark as completed
      buttons.add(
        _ActionButton(
          label: 'Complete',
          color: theme.colorScheme.primary,
          onPressed: () {
            cubit.completeTransaction(transaction.transactionId);
            CustomToast.show(context, message: 'Transaction completed', isSuccess: true);
          },
        ),
      );
    }

    return buttons;
  }

  void _showRejectDialog(BuildContext context, TransactionCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Transaction'),
        content: const Text('Are you sure you want to reject this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.rejectTransaction(transaction.transactionId);
              Navigator.of(dialogContext).pop();
              CustomToast.show(context, message: 'Transaction rejected', isSuccess: true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}