import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_status_chip.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onVerify;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onVerify,
    this.onComplete,
    this.onDelete,
  });

  String? _getCurrentUserId(BuildContext context) {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      return authState.user.uid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _getCurrentUserId(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TransactionUtils.getTypeColor(transaction.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TransactionUtils.getTypeIcon(transaction.type),
                        size: 20,
                        color: TransactionUtils.getTypeColor(transaction.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.contactName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (transaction.contactPhone != null) ...[
                            Text(
                              transaction.contactPhone!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Contact only',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          transaction.formattedAmount,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: TransactionUtils.getTypeColor(transaction.type),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TransactionStatusChip(
                          status: transaction.status,
                          showIcon: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (transaction.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    transaction.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TransactionUtils.formatDate(transaction.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    
                    if (transaction.dueDate != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.event,
                        size: 14,
                        color: TransactionUtils.isDueDatePassed(transaction.dueDate!) 
                            ? Colors.red 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${TransactionUtils.formatDate(transaction.dueDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: TransactionUtils.isDueDatePassed(transaction.dueDate!) 
                              ? Colors.red 
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    if (transaction.verificationRequired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: transaction.isVerified 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              transaction.isVerified 
                                  ? Icons.verified_user
                                  : Icons.verified_user_outlined,
                              size: 12,
                              color: transaction.isVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              transaction.isVerified ? 'Verified' : 'Needs Verification',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: transaction.isVerified ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'No Verification',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (_shouldShowActions(currentUserId)) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(context, currentUserId, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowActions(String? currentUserId) {
    if (currentUserId == null || transaction.isCompleted) return false;
    
    final canVerify = TransactionUtils.canUserVerify(transaction, currentUserId) && onVerify != null;
    final canComplete = TransactionUtils.canUserComplete(transaction, currentUserId) && onComplete != null;
    final canDelete = transaction.isPending && transaction.createdBy == currentUserId && onDelete != null;
    
    return canVerify || canComplete || canDelete;
  }

  Widget _buildActionButtons(BuildContext context, String? currentUserId, ThemeData theme) {
    if (currentUserId == null) return const SizedBox.shrink();
    
    final canVerify = TransactionUtils.canUserVerify(transaction, currentUserId) && onVerify != null;
    final canComplete = TransactionUtils.canUserComplete(transaction, currentUserId) && onComplete != null;
    final canDelete = transaction.isPending && transaction.createdBy == currentUserId && onDelete != null;
    
    return Row(
      children: [
        if (canVerify) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onVerify,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Verify'),
            ),
          ),
          if (canComplete || canDelete) const SizedBox(width: 8),
        ],
        
        if (canComplete) ...[
          Expanded(
            child: FilledButton(
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(TransactionUtils.getCompletionButtonText(transaction, currentUserId)),
            ),
          ),
          if (canDelete) const SizedBox(width: 8),
        ],
        
        if (canDelete) ...[
          if (!canComplete && !canVerify)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
        ],
      ],
    );
  }
}