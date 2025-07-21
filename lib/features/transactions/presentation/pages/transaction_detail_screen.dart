import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (transaction.isVerified)
            IconButton(
              onPressed: () => _showMarkAsDoneDialog(context),
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Mark as Done',
            ),
        ],
      ),
      body: BlocListener<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state is TransactionUpdated) {
            CustomToast.show(
              context,
              message: 'Transaction marked as completed!',
              isSuccess: true,
            );
            Navigator.pop(context);
          } else if (state is TransactionError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionCard(theme),
              const SizedBox(height: 24),
              _buildDetailsSection(theme),
              const SizedBox(height: 24),
              if (transaction.isPending) _buildPendingActions(context, theme),
              if (transaction.isVerified) _buildVerifiedActions(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ThemeData theme) {
    final isLending = transaction.isLending;
    final color = isLending ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isLending ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '₹${transaction.amount.toStringAsFixed(0)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLending ? 'You Lent' : 'You Borrowed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLending 
                ? 'to ${transaction.toUserName ?? 'Unknown'}'
                : 'from ${transaction.fromUserName ?? 'Unknown'}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (transaction.status) {
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending Verification';
        statusIcon = Icons.hourglass_empty;
        break;
      case TransactionStatus.verified:
        statusColor = Colors.green;
        statusText = 'Verified';
        statusIcon = Icons.verified;
        break;
      case TransactionStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      
      case TransactionStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                theme,
                'Transaction ID',
                transaction.id,
                Icons.tag,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                theme,
                'Created',
                _formatDateTime(transaction.createdAt),
                Icons.calendar_today,
              ),
              if (transaction.updatedAt != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  theme,
                  'Last Updated',
                  _formatDateTime(transaction.updatedAt!),
                  Icons.update,
                ),
              ],
              if (transaction.dueDate != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  theme,
                  'Due Date',
                  _formatDate(transaction.dueDate!),
                  Icons.schedule,
                  isOverdue: transaction.isOverdue,
                ),
              ],
              const SizedBox(height: 16),
              _buildDetailRow(
                theme,
                transaction.isLending ? 'Lent to' : 'Borrowed from',
                transaction.isLending 
                    ? transaction.toUserName ?? 'Unknown'
                    : transaction.fromUserName ?? 'Unknown',
                Icons.person,
              ),
              if ((transaction.isLending ? transaction.toUserPhone : transaction.fromUserPhone) != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  theme,
                  'Phone Number',
                  transaction.isLending 
                      ? transaction.toUserPhone!
                      : transaction.fromUserPhone!,
                  Icons.phone,
                ),
              ],
              if (transaction.description != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  theme,
                  'Description',
                  transaction.description!,
                  Icons.description,
                  isMultiLine: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    bool isOverdue = false,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOverdue 
                ? Colors.red.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isOverdue ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isOverdue ? Colors.red : null,
                ),
                maxLines: isMultiLine ? null : 1,
                overflow: isMultiLine ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This transaction is waiting for verification',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateTransactionStatus(
                        context,
                        TransactionStatus.rejected,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateTransactionStatus(
                        context,
                        TransactionStatus.verified,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Transaction',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.isLending
                          ? 'Mark as done when the money is returned'
                          : 'Mark as done when you have returned the money',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showMarkAsDoneDialog(context),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark as Done'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateTransactionStatus(BuildContext context, TransactionStatus status) {
    context.read<TransactionCubit>().updateTransactionStatus(
      transaction.id,
      status,
    );
  }

  void _showMarkAsDoneDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Complete Transaction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.isLending
                  ? 'Are you sure you want to mark this transaction as completed? This means the money has been returned to you.'
                  : 'Are you sure you want to mark this transaction as completed? This means you have returned the money.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will move the transaction to your completed transactions.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: Implement mark as done functionality
              // This would require adding a new status or field to track completed transactions
              CustomToast.show(
                context,
                message: 'Transaction marked as completed!',
                isSuccess: true,
              );
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mark as Done'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}