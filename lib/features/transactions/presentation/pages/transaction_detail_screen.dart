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
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTransactionHeader(context, theme),
            const SizedBox(height: 12),
            _buildTransactionInfo(context, theme),
            const SizedBox(height: 12),
            _buildDeviceInfo(context, theme),
            const SizedBox(height: 12),
            _buildActivityTimeline(context, theme),
            const SizedBox(height: 12),
            if (_shouldShowActions()) _buildActionButtons(context, theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getTransactionColor(theme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getTransactionIcon(),
              color: _getTransactionColor(theme),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${transaction.isLent ? '+' : '-'}Rs. ${transaction.amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: _getTransactionColor(theme),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(theme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            'Transaction Info',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Transaction ID',
            transaction.transactionId,
            theme,
          ),
          _buildInfoRow(
            transaction.isLent ? 'Borrower' : 'Lender',
            transaction.otherParty.name,
            theme,
          ),
          _buildInfoRow(
            'Description',
            transaction.description,
            theme,
          ),
          _buildInfoRow(
            'Created',
            _formatDateTime(transaction.createdAt),
            theme,
          ),
          if (transaction.verifiedAt != null)
            _buildInfoRow(
              'Verified',
              _formatDateTime(transaction.verifiedAt!),
              theme,
            ),
          if (transaction.completedAt != null)
            _buildInfoRow(
              'Completed',
              _formatDateTime(transaction.completedAt!),
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            'Device Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeviceInfoSection(theme),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSection(ThemeData theme) {
    final deviceInfos = <String>[];
    
    // Created from device
    if (transaction.createdFromDevice != null) {
      final deviceName = transaction.getDeviceDisplayName(transaction.createdFromDevice);
      deviceInfos.add('Created From Device: $deviceName');
    }
    
    // Verified from device
    final verifiedDevice = transaction.getDeviceForAction(TransactionStatus.verified);
    if (verifiedDevice != null) {
      final deviceName = transaction.getDeviceDisplayName(verifiedDevice);
      deviceInfos.add('Verified From Device: $deviceName');
    }
    
    // Completed from device
    final completedDevice = transaction.getDeviceForAction(TransactionStatus.completed);
    if (completedDevice != null) {
      final deviceName = transaction.getDeviceDisplayName(completedDevice);
      deviceInfos.add('Completed From Device: $deviceName');
    }
    
    // Rejected from device
    final rejectedDevice = transaction.getDeviceForAction(TransactionStatus.rejected);
    if (rejectedDevice != null) {
      final deviceName = transaction.getDeviceDisplayName(rejectedDevice);
      deviceInfos.add('Rejected From Device: $deviceName');
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
        child: Row(
          children: [
            Icon(
              Icons.phone_android,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                info,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActivityTimeline(BuildContext context, ThemeData theme) {
    if (transaction.activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            'Activity Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...transaction.activities.map((activity) => _buildActivityItem(activity, theme)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(TransactionActivity activity, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(theme, activity.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.action),
              size: 16,
              color: _getStatusColor(theme, activity.action),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTitle(activity.action),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(activity.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (activity.deviceInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'From ${transaction.getDeviceDisplayName(activity.deviceInfo)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _getActionButtons(context, theme),
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
            label: 'Mark as Complete',
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

  IconData _getTransactionIcon() {
    return transaction.isLent 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;
  }

  Color _getStatusColor(ThemeData theme, [TransactionStatus? status]) {
    status ??= transaction.status;
    switch (status) {
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

  IconData _getActivityIcon(TransactionStatus action) {
    switch (action) {
      case TransactionStatus.pendingVerification:
        return Icons.schedule;
      case TransactionStatus.verified:
        return Icons.verified;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getActivityTitle(TransactionStatus action) {
    switch (action) {
      case TransactionStatus.pendingVerification:
        return 'Created';
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
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}