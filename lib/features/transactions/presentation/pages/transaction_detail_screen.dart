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
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with amount and status
                  _buildHeaderSection(theme),
                  
                  // Transaction details
                  _buildDetailsSection(theme),
                  
                  // Timeline
                  _buildTimelineSection(theme),
                  
                  // Device info
                  _buildDeviceSection(theme),
                ],
              ),
            ),
          ),
          
          // Action buttons (if needed)
          if (_shouldShowActions()) _buildActionButtons(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Amount
          Text(
            '${transaction.isLent ? '+' : '-'}Rs. ${_formatAmount(transaction.amount)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _getTransactionColor(theme),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Contact and type
          Text(
            transaction.isLent 
                ? 'Lent to ${transaction.otherParty.name}'
                : 'Borrowed from ${transaction.otherParty.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(theme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getStatusColor(theme).withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              _getStatusText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildDetailItem('Transaction ID', transaction.transactionId, theme),
          _buildDetailItem('Contact Name', transaction.otherParty.name, theme),
          _buildDetailItem('Phone Number', transaction.otherParty.phoneNumber, theme),
          _buildDetailItem('Description', transaction.description, theme),
          _buildDetailItem('Created', _formatDateTime(transaction.createdAt), theme, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    final events = <Map<String, dynamic>>[];
    
    events.add({
      'title': 'Created',
      'time': transaction.createdAt,
      'icon': Icons.add_circle_outline,
      'color': Colors.blue,
    });
    
    if (transaction.verifiedAt != null) {
      events.add({
        'title': 'Verified',
        'time': transaction.verifiedAt!,
        'icon': Icons.verified,
        'color': Colors.green,
      });
    }
    
    if (transaction.completedAt != null) {
      events.add({
        'title': 'Completed',
        'time': transaction.completedAt!,
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    if (events.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _buildTimelineItem(
            event['title'],
            _formatDateTime(event['time']),
            event['icon'],
            event['color'],
            theme,
          )),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(ThemeData theme) {
    final deviceInfos = <String>[];
    
    if (transaction.createdFromDevice != null) {
      deviceInfos.add('Created from ${transaction.getDeviceDisplayName(transaction.createdFromDevice)}');
    }
    
    final verifiedDevice = transaction.getDeviceForAction(TransactionStatus.verified);
    if (verifiedDevice != null) {
      deviceInfos.add('Verified from ${transaction.getDeviceDisplayName(verifiedDevice)}');
    }
    
    final completedDevice = transaction.getDeviceForAction(TransactionStatus.completed);
    if (completedDevice != null) {
      deviceInfos.add('Completed from ${transaction.getDeviceDisplayName(completedDevice)}');
    }

    if (deviceInfos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ...deviceInfos.map((info) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              info,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(children: buttons),
    );
  }

  Widget _buildDetailItem(String label, String value, ThemeData theme, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getTransactionColor(ThemeData theme) {
    return transaction.isLent ? Colors.green : Colors.red;
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Reject Transaction',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to reject this transaction?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              cubit.rejectTransaction(transaction.transactionId);
              Navigator.of(dialogContext).pop();
              CustomToast.show(context, message: 'Transaction rejected', isSuccess: true);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
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
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}