import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/confirmation_dialog.dart';
import 'package:udharoo/shared/presentation/widgets/status_indicator.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    final dynamicPadding = screenWidth < 360 ? 12.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final isProcessing = state.isTransactionProcessing(transaction.transactionId);
          
          return Padding(
            padding: EdgeInsets.all(dynamicPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTransactionIndicator(theme),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.otherParty.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getTransactionDescription(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _getTransactionColor(theme),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              Flexible(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs. ${TransactionDisplayHelper.formatAmount(transaction.amount)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: _getTransactionColor(theme),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(height: 2),
                                    QuickStatusChip(
                                      transaction: transaction,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (transaction.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transaction.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getFormattedDate(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (isProcessing)
                                _buildProcessingIndicator(theme)
                              else
                                _buildTransactionTypeIcon(theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_shouldShowActionButtons() && !isProcessing) ...[
                  const SizedBox(height: 12),
                  _buildCompactActionButtons(context, theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionIndicator(ThemeData theme) {
    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        color: _getTransactionColor(theme),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTransactionTypeIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getTransactionColor(theme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTransactionColor(theme).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Icon(
        transaction.isLent ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        color: _getTransactionColor(theme),
        size: 16,
      ),
    );
  }

  Widget _buildProcessingIndicator(ThemeData theme) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, ThemeData theme) {
    final cubit = context.read<TransactionCubit>();
    final buttons = <Widget>[];

    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      buttons.addAll([
        Expanded(
          child: _CompactActionButton(
            label: 'Confirm',
            icon: Icons.verified_rounded,
            color: Colors.green,
            onPressed: () => _handleVerifyTransaction(context, cubit),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactActionButton(
            label: 'Decline',
            icon: Icons.cancel_rounded,
            color: Colors.red,
            onPressed: () => _handleRejectTransaction(context, cubit),
          ),
        ),
      ]);
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      buttons.add(
        Expanded(
          child: _CompactActionButton(
            label: 'Mark as Paid',
            icon: Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
            onPressed: () => _handleCompleteTransaction(context, cubit),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(children: buttons),
    );
  }

  Future<void> _handleVerifyTransaction(BuildContext context, TransactionCubit cubit) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      data: ConfirmationDialogData.forTransactionAction(
        ConfirmationDialogType.verify,
        transaction.otherParty.name,
        transaction.amount,
      ),
    );

    if (confirmed) {
      cubit.verifyTransaction(transaction.transactionId);
    }
  }

  Future<void> _handleCompleteTransaction(BuildContext context, TransactionCubit cubit) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      data: ConfirmationDialogData.forTransactionAction(
        ConfirmationDialogType.complete,
        transaction.otherParty.name,
        transaction.amount,
      ),
    );

    if (confirmed) {
      cubit.completeTransaction(transaction.transactionId);
    }
  }

  Future<void> _handleRejectTransaction(BuildContext context, TransactionCubit cubit) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      data: ConfirmationDialogData.forTransactionAction(
        ConfirmationDialogType.reject,
        transaction.otherParty.name,
        transaction.amount,
      ),
    );

    if (confirmed) {
      cubit.rejectTransaction(transaction.transactionId);
    }
  }

  Color _getTransactionColor(ThemeData theme) {
    return transaction.isLent ? Colors.green : Colors.orange;
  }

  String _getTransactionDescription() {
    return TransactionDisplayHelper.getTransactionAction(transaction.type);
  }

  String _getFormattedDate() {
    final date = transaction.createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  bool _shouldShowActionButtons() {
    return (transaction.isPending && !_isCreatedByCurrentUser()) ||
           (transaction.isVerified && _canCompleteTransaction());
  }

  bool _isCreatedByCurrentUser() {
    return transaction.isLent;
  }

  bool _canCompleteTransaction() {
    return transaction.isVerified && transaction.isLent;
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}