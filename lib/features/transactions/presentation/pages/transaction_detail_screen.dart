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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    final horizontalPadding = screenWidth * 0.04;
    final verticalSpacing = screenHeight * 0.015;
    final cardSpacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildResponsiveAppBar(theme, horizontalPadding),
          
          SliverPadding(
            padding: EdgeInsets.all(horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMainTransactionCard(theme, screenWidth, verticalSpacing),
                
                SizedBox(height: cardSpacing),
                
                _buildContactCard(theme, screenWidth, verticalSpacing),
                
                SizedBox(height: cardSpacing),
                
                _buildTransactionDetailsCard(theme, screenWidth, verticalSpacing),
                
                if (_hasTimeline()) ...[
                  SizedBox(height: cardSpacing),
                  _buildTimelineCard(theme, screenWidth, verticalSpacing),
                ],
                
                if (_hasDeviceInfo()) ...[
                  SizedBox(height: cardSpacing),
                  _buildDeviceInfoCard(theme, screenWidth, verticalSpacing),
                ],
                
                SizedBox(height: cardSpacing * 2),
              ]),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: _shouldShowActions() 
          ? _buildBottomActionBar(context, theme, horizontalPadding)
          : null,
    );
  }

  Widget _buildResponsiveAppBar(ThemeData theme, double horizontalPadding) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 120,
      title: Text(
        'Transaction Details',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding, 
              kToolbarHeight + 16, 
              horizontalPadding, 
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getTransactionColor(theme).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTransactionColor(theme).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        transaction.isLent ? Icons.trending_up : Icons.trending_down,
                        color: _getTransactionColor(theme),
                        size: 14,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Text(
                        '${transaction.isLent ? 'Lent to' : 'Borrowed from'} ${transaction.otherParty.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    _buildStatusBadge(theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(theme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(theme).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStatusColor(theme),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(theme),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTransactionCard(ThemeData theme, double screenWidth, double verticalSpacing) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getTransactionColor(theme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: _getTransactionColor(theme).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              transaction.isLent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: _getTransactionColor(theme),
              size: 36,
            ),
          ),
          
          SizedBox(height: verticalSpacing),
          
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs. ${_formatAmount(transaction.amount)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _getTransactionColor(theme),
                fontSize: (screenWidth * 0.08).clamp(24.0, 36.0),
              ),
            ),
          ),
          
          SizedBox(height: verticalSpacing * 0.5),
          
          if (transaction.description.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                transaction.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme, double screenWidth, double verticalSpacing) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: verticalSpacing),
          
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              
              SizedBox(width: screenWidth * 0.04),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.otherParty.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: verticalSpacing * 0.25),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            transaction.otherParty.phoneNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTransactionColor(theme).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTransactionColor(theme).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  transaction.isLent ? 'Lent' : 'Borrowed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getTransactionColor(theme),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsCard(ThemeData theme, double screenWidth, double verticalSpacing) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
            'Transaction Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: verticalSpacing),
          
          _buildDetailRow(
            Icons.tag_rounded,
            'Transaction ID',
            transaction.transactionId,
            theme,
            verticalSpacing,
          ),
          
          SizedBox(height: verticalSpacing * 0.75),
          
          _buildDetailRow(
            Icons.schedule_rounded,
            'Created',
            _formatDateTime(transaction.createdAt),
            theme,
            verticalSpacing,
          ),
          
          if (transaction.verifiedAt != null) ...[
            SizedBox(height: verticalSpacing * 0.75),
            _buildDetailRow(
              Icons.verified_rounded,
              'Verified',
              _formatDateTime(transaction.verifiedAt!),
              theme,
              verticalSpacing,
            ),
          ],
          
          if (transaction.completedAt != null) ...[
            SizedBox(height: verticalSpacing * 0.75),
            _buildDetailRow(
              Icons.check_circle_rounded,
              'Completed',
              _formatDateTime(transaction.completedAt!),
              theme,
              verticalSpacing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme, double verticalSpacing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(ThemeData theme, double screenWidth, double verticalSpacing) {
    final events = <Map<String, dynamic>>[];
    
    events.add({
      'title': 'Transaction Created',
      'time': transaction.createdAt,
      'icon': Icons.add_circle_outline_rounded,
      'color': Colors.blue,
    });
    
    if (transaction.verifiedAt != null) {
      events.add({
        'title': 'Transaction Verified',
        'time': transaction.verifiedAt!,
        'icon': Icons.verified_rounded,
        'color': Colors.green,
      });
    }
    
    if (transaction.completedAt != null) {
      events.add({
        'title': 'Transaction Completed',
        'time': transaction.completedAt!,
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
      });
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: verticalSpacing),
          
          ...events.asMap().entries.map((entry) {
            final isLast = entry.key == events.length - 1;
            final event = entry.value;
            return _buildTimelineItem(
              event['title'],
              _formatDateTime(event['time']),
              event['icon'],
              event['color'],
              theme,
              verticalSpacing,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title, 
    String time, 
    IconData icon, 
    Color color, 
    ThemeData theme, 
    double verticalSpacing,
    {bool isLast = false}
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard(ThemeData theme, double screenWidth, double verticalSpacing) {
    final deviceInfos = <Map<String, String>>[];
    
    if (transaction.createdFromDevice != null) {
      deviceInfos.add({
        'label': 'Created from',
        'value': transaction.getDeviceDisplayName(transaction.createdFromDevice),
      });
    }
    
    final verifiedDevice = transaction.getDeviceForAction(TransactionStatus.verified);
    if (verifiedDevice != null) {
      deviceInfos.add({
        'label': 'Verified from',
        'value': transaction.getDeviceDisplayName(verifiedDevice),
      });
    }
    
    final completedDevice = transaction.getDeviceForAction(TransactionStatus.completed);
    if (completedDevice != null) {
      deviceInfos.add({
        'label': 'Completed from',
        'value': transaction.getDeviceDisplayName(completedDevice),
      });
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
          Row(
            children: [
              Icon(
                Icons.smartphone_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Device Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          SizedBox(height: verticalSpacing),
          
          ...deviceInfos.map((info) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      children: [
                        TextSpan(
                          text: '${info['label']}: ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: info['value']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, ThemeData theme, double horizontalPadding) {
    final cubit = context.read<TransactionCubit>();

    Widget? actionContent;

    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      actionContent = Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                cubit.verifyTransaction(transaction.transactionId);
                CustomToast.show(context, message: 'Transaction verified', isSuccess: true);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Verify'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(context, cubit),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      actionContent = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            cubit.completeTransaction(transaction.transactionId);
            CustomToast.show(context, message: 'Transaction completed', isSuccess: true);
          },
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text('Mark as Completed'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: actionContent ?? const SizedBox.shrink(),
      ),
    );
  }

  bool _hasTimeline() {
    int eventCount = 1;
    if (transaction.verifiedAt != null) eventCount++;
    if (transaction.completedAt != null) eventCount++;
    return eventCount > 1;
  }

  bool _hasDeviceInfo() {
    return transaction.createdFromDevice != null ||
           transaction.getDeviceForAction(TransactionStatus.verified) != null ||
           transaction.getDeviceForAction(TransactionStatus.completed) != null;
  }

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
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
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
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  bool _shouldShowActions() {
    return (transaction.isPending && !_isCreatedByCurrentUser()) ||
           (transaction.isVerified && _canCompleteTransaction());
  }

  bool _isCreatedByCurrentUser() {
    return transaction.isLent;
  }

  bool _canCompleteTransaction() {
    return transaction.isVerified && transaction.isLent;
  }

  Future<void> _showRejectDialog(BuildContext context, TransactionCubit cubit) async {
    final theme = Theme.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.rejectTransaction(transaction.transactionId);
    }
  }
}