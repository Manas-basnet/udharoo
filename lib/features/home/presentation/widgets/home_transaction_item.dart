import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/confirmation_dialog.dart';

class HomeTransactionItem extends StatelessWidget {
  final Transaction transaction;

  const HomeTransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => context.go(
        Routes.transactionDetail,
        extra: transaction,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            final isProcessing = state.isTransactionProcessing(transaction.transactionId);
            
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getTransactionColor(theme).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getTransactionColor(theme).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        transaction.isLent ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: _getTransactionColor(theme),
                        size: 18,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  transaction.otherParty.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${_formatAmount(transaction.amount)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _getTransactionColor(theme),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getFormattedDate(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(theme).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
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
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_shouldShowActionButtons() && !isProcessing) ...[
                  const SizedBox(height: 8),
                  _buildActionButtons(context, theme),
                ],
                
                if (isProcessing) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Processing...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final cubit = context.read<TransactionCubit>();
    
    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Verify',
              icon: Icons.check_rounded,
              color: Colors.green,
              onPressed: () => _handleVerifyTransaction(context, cubit),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Reject',
              icon: Icons.close_rounded,
              color: Colors.red,
              onPressed: () => _handleRejectTransaction(context, cubit),
            ),
          ),
        ],
      );
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      return _ActionButton(
        label: 'Mark Complete',
        icon: Icons.check_circle_rounded,
        color: theme.colorScheme.primary,
        onPressed: () => _handleCompleteTransaction(context, cubit),
      );
    }
    
    return const SizedBox.shrink();
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

  String _formatAmount(double amount) {
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: color.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        icon: Icon(icon, size: 12),
        label: Text(label),
      ),
    );
  }
}