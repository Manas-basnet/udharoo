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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountSection(theme),
            const SizedBox(height: 24),
            _buildInfoSection(theme),
            const SizedBox(height: 24),
            _buildTimelineSection(theme),
            const SizedBox(height: 24),
            _buildDeviceSection(theme),
            const SizedBox(height: 24),
            if (_shouldShowActions()) _buildActionSection(context, theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${transaction.isLent ? '+' : '-'}Rs. ${_formatAmount(transaction.amount)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _getTransactionColor(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transaction.isLent 
                ? 'You lent to ${transaction.otherParty.name}'
                : 'You borrowed from ${transaction.otherParty.name}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(theme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getStatusColor(theme).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getStatusText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID', transaction.transactionId, theme),
          _buildInfoRow('Contact', transaction.otherParty.name, theme),
          _buildInfoRow('Description', transaction.description, theme),
          _buildInfoRow('Type', transaction.isLent ? 'Lent' : 'Borrowed', theme),
          _buildInfoRow('Amount', 'Rs. ${_formatAmount(transaction.amount)}', theme),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem('Created', _formatDateTime(transaction.createdAt), theme),
          if (transaction.verifiedAt != null)
            _buildTimelineItem('Verified', _formatDateTime(transaction.verifiedAt!), theme),
          if (transaction.completedAt != null)
            _buildTimelineItem('Completed', _formatDateTime(transaction.completedAt!), theme),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDeviceInfo(theme),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(ThemeData theme) {
    final deviceInfos = <String>[];
    
    if (transaction.createdFromDevice != null) {
      deviceInfos.add('Created from: ${transaction.getDeviceDisplayName(transaction.createdFromDevice)}');
    }
    
    final verifiedDevice = transaction.getDeviceForAction(TransactionStatus.verified);
    if (verifiedDevice != null) {
      deviceInfos.add('Verified from: ${transaction.getDeviceDisplayName(verifiedDevice)}');
    }
    
    final completedDevice = transaction.getDeviceForAction(TransactionStatus.completed);
    if (completedDevice != null) {
      deviceInfos.add('Completed from: ${transaction.getDeviceDisplayName(completedDevice)}');
    }

    if (deviceInfos.isEmpty) {
      return Text(
        'No device information available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: deviceInfos.map((info) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          info,
          style: theme.textTheme.bodyMedium,
        ),
      )).toList(),
    );
  }

  Widget _buildActionSection(BuildContext context, ThemeData theme) {
    final buttons = _getActionButtons(context, theme);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: buttons,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getActionButtons(BuildContext context, ThemeData theme) {
    final cubit = context.read<TransactionCubit>();
    final buttons = <Widget>[];

    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      buttons.addAll([
        Expanded(
          child: _ActionButton(
            label: 'Verify',
            color: Colors.green,
            onPressed: () {
              cubit.verifyTransaction(transaction.transactionId);
              CustomToast.show(context, message: 'Transaction verified', isSuccess: true);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Reject',
            color: Colors.red,
            onPressed: () => _showRejectDialog(context, cubit),
          ),
        ),
      ]);
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      buttons.add(
        Expanded(
          child: _ActionButton(
            label: 'Mark Complete',
            color: theme.colorScheme.primary,
            onPressed: () {
              cubit.completeTransaction(transaction.transactionId);
              CustomToast.show(context, message: 'Transaction completed', isSuccess: true);
            },
          ),
        ),
      );
    }

    return buttons;
  }

  // Helper methods
  Color _getTransactionColor(ThemeData theme) {
    return transaction.isLent 
        ? theme.colorScheme.primary 
        : theme.colorScheme.error;
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
        return 'Pending';
      case TransactionStatus.verified:
        return 'Verified';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  bool _shouldShowActions() {
    return (transaction.isPending && !_isCreatedByCurrentUser()) ||
           (transaction.isVerified && _canCompleteTransaction());
  }

  bool _isCreatedByCurrentUser() {
    return transaction.isLent;
  }

  bool _canCompleteTransaction() {
    return transaction.isVerified;
  }

  void _showRejectDialog(BuildContext context, TransactionCubit cubit) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Reject Transaction'),
        content: const Text('Are you sure you want to reject this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.rejectTransaction(transaction.transactionId);
              Navigator.of(dialogContext).pop();
              CustomToast.show(context, message: 'Transaction rejected', isSuccess: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}