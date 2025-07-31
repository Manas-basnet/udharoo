import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/confirmation_dialog.dart';

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
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final isProcessing = state.isTransactionProcessing(transaction.transactionId);
          
          return Padding(
            padding: const EdgeInsets.all(20), 
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getTransactionColor(theme),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    
                    const SizedBox(width: 20), 
                    
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${_formatAmount(transaction.amount)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _getTransactionColor(theme),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 6), 
                          
                          Row(
                            children: [
                              Text(
                                transaction.otherParty.phoneNumber,
                                style: theme.textTheme.bodyMedium?.copyWith( 
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (transaction.description.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: theme.textTheme.bodyMedium?.copyWith( 
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    transaction.description,
                                    style: theme.textTheme.bodyMedium?.copyWith( 
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Text(
                                _getFormattedDate(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12, 
                                ),
                              ),
                              
                              const SizedBox(width: 10),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), 
                                decoration: BoxDecoration(
                                  color: _getStatusColor(theme).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
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
                              
                              const Spacer(),
                              
                              if (isProcessing)
                                _buildProcessingIndicator(theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_shouldShowActionButtons() && !isProcessing) ...[
                  const SizedBox(height: 16), 
                  _buildExpandedActionButtons(context, theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessingIndicator(ThemeData theme) {
    return SizedBox(
      width: 22, 
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildExpandedActionButtons(BuildContext context, ThemeData theme) {
    final cubit = context.read<TransactionCubit>();
    final buttons = <Widget>[];

    if (transaction.isPending && !_isCreatedByCurrentUser()) {
      buttons.addAll([
        Expanded(
          child: _ExpandedActionButton(
            label: 'Verify',
            icon: Icons.verified_rounded,
            color: Colors.green,
            onPressed: () => _handleVerifyTransaction(context, cubit),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ExpandedActionButton(
            label: 'Reject',
            icon: Icons.cancel_rounded,
            color: Colors.red,
            onPressed: () => _handleRejectTransaction(context, cubit),
          ),
        ),
      ]);
    } else if (transaction.isVerified && _canCompleteTransaction()) {
      buttons.add(
        Expanded(
          child: _ExpandedActionButton(
            label: 'Mark Complete',
            icon: Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
            onPressed: () => _handleCompleteTransaction(context, cubit),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
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

class _ExpandedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ExpandedActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}