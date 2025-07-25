import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_detail/transaction_detail_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_status_chip.dart';
import 'package:udharoo/features/transactions/presentation/widgets/verification_dialog.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  void _loadTransaction() {
    context.read<TransactionDetailCubit>().loadTransaction(widget.transactionId);
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      return authState.user.uid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionDetailCubit, TransactionDetailState>(
      listener: (context, state) {
        switch (state) {
          case TransactionDetailVerified():
            setState(() {
              _isVerifying = false;
            });
            CustomToast.show(
              context,
              message: 'Transaction verified successfully',
              isSuccess: true,
            );
            _loadTransaction();
          case TransactionDetailCompleted():
            CustomToast.show(
              context,
              message: 'Transaction completed successfully',
              isSuccess: true,
            );
            context.pop();
          case TransactionDetailUpdated():
            CustomToast.show(
              context,
              message: 'Transaction updated successfully',
              isSuccess: true,
            );
            _loadTransaction();
          case TransactionDetailDeleted():
            CustomToast.show(
              context,
              message: 'Transaction deleted successfully',
              isSuccess: true,
            );
            context.pop();
          case TransactionDetailError():
            setState(() {
              _isVerifying = false;
            });
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Transaction Details'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
              builder: (context, state) {
                if (state is TransactionDetailLoaded) {
                  final authState = context.read<AuthSessionCubit>().state;
                  if (authState is AuthSessionAuthenticated) {
                    final currentUserId = authState.user.uid;
                    final transaction = state.transaction;
                    final isCreator = transaction.createdBy == currentUserId;
                    
                    return PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, transaction, isCreator),
                      itemBuilder: (context) => [
                        if (isCreator && transaction.isPending) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
          builder: (context, state) {
            if (state is TransactionDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionDetailLoaded) {
              return _buildTransactionDetail(state.transaction);
            }

            return _buildErrorState();
          },
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(Transaction transaction) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TransactionUtils.getTypeColor(transaction.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    TransactionUtils.getTypeIcon(transaction.type),
                    size: 48,
                    color: TransactionUtils.getTypeColor(transaction.type),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TransactionTypeChip(
                  type: transaction.type,
                  showIcon: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  transaction.formattedAmount,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TransactionUtils.getTypeColor(transaction.type),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TransactionStatusChip(
                  status: transaction.status,
                  showIcon: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection('Contact Information', [
            _buildInfoRow(Icons.person, 'Name', transaction.contactName),
            if (transaction.contactPhone != null)
              _buildInfoRow(Icons.phone, 'Phone', transaction.contactPhone!)
            else
              _buildInfoRow(Icons.phone_disabled, 'Phone', 'Not provided', textColor: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            if (transaction.contactEmail != null)
              _buildInfoRow(Icons.email, 'Email', transaction.contactEmail!),
          ]),
          
          const SizedBox(height: 16),
          
          _buildInfoSection('Transaction Details', [
            _buildInfoRow(Icons.access_time, 'Created', TransactionUtils.formatDateTime(transaction.createdAt)),
            if (transaction.updatedAt != transaction.createdAt)
              _buildInfoRow(Icons.update, 'Updated', TransactionUtils.formatDateTime(transaction.updatedAt)),
            if (transaction.dueDate != null)
              _buildInfoRow(
                Icons.event,
                'Due Date',
                TransactionUtils.formatSimpleDate(transaction.dueDate!),
                textColor: TransactionUtils.isDueDatePassed(transaction.dueDate!) ? Colors.red : null,
              ),
            if (transaction.description != null)
              _buildInfoRow(Icons.note, 'Description', transaction.description!),
          ]),
          
          const SizedBox(height: 16),
          
          _buildInfoSection('Verification Status', [
            _buildInfoRow(
              transaction.verificationRequired ? Icons.verified_user : Icons.check_circle_outline,
              'Verification Required',
              transaction.verificationRequired ? 'Yes' : 'No',
              textColor: transaction.verificationRequired ? Colors.orange : Colors.green,
            ),
            if (transaction.verificationRequired) ...[
              _buildInfoRow(
                transaction.isVerified ? Icons.check_circle : Icons.pending,
                'Verification Status',
                transaction.isVerified ? 'Verified' : 'Pending',
                textColor: transaction.isVerified ? Colors.green : Colors.orange,
              ),
              if (transaction.isVerified && transaction.verifiedBy != null)
                _buildInfoRow(Icons.person_outline, 'Verified By', transaction.verifiedBy!),
              if (transaction.contactPhone != null)
                _buildInfoRow(
                  Icons.phone_android,
                  'Verification Method',
                  'Phone-based verification',
                  textColor: Colors.blue,
                )
              else
                _buildInfoRow(
                  Icons.warning_amber,
                  'Verification Method',
                  'Contact-only verification',
                  textColor: Colors.orange,
                ),
            ] else ...[
              _buildInfoRow(
                Icons.info_outline,
                'Transaction Type',
                'Simple transaction (no verification needed)',
                textColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ]),
          
          const SizedBox(height: 24),
          
          _buildActionButtons(transaction),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? textColor}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor ?? theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: textColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Transaction transaction) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }
    
    final canVerify = TransactionUtils.canUserVerify(transaction, currentUserId);
    final canComplete = TransactionUtils.canUserComplete(transaction, currentUserId);
    
    if (transaction.isCompleted || transaction.status == TransactionStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (canVerify) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This transaction requires your verification as the recipient.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
              builder: (context, state) {
                final isVerifying = state is TransactionDetailVerifying;
                
                return FilledButton.icon(
                  onPressed: isVerifying ? null : () => _showVerificationDialog(transaction),
                  icon: isVerifying 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_user),
                  label: Text(isVerifying ? 'Verifying...' : 'Verify Transaction'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (canComplete) ...[
          if (transaction.verificationRequired && !transaction.isVerified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This transaction must be verified before it can be completed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(
            width: double.infinity,
            height: 52,
            child: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
              builder: (context, state) {
                final isCompleting = state is TransactionDetailCompleting;
                final isDisabled = transaction.verificationRequired && !transaction.isVerified;
                
                return FilledButton.icon(
                  onPressed: (isCompleting || isDisabled) ? null : () => _completeTransaction(transaction),
                  icon: isCompleting 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(isCompleting 
                      ? 'Completing...' 
                      : TransactionUtils.getCompletionButtonText(transaction, currentUserId)),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDisabled 
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction not found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadTransaction,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Transaction transaction, bool isCreator) {
    switch (action) {
      case 'edit':
        if (isCreator) {
          context.push(Routes.transactionForm, extra: transaction).then((result) {
            if (result is Transaction) {
              _loadTransaction();
            }
          });
        }
        break;
      case 'delete':
        if (isCreator) {
          _showDeleteDialog(transaction);
        }
        break;
      case 'share':
        _shareTransaction(transaction);
        break;
    }
  }

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransactionDetailCubit>().deleteTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(Transaction transaction) {
    setState(() {
      _isVerifying = true;
    });

    TransactionVerificationDialog.show(
      context,
      transaction: transaction,
      onVerify: () => _verifyTransaction(transaction),
      onCancel: () {
        setState(() {
          _isVerifying = false;
        });
        Navigator.of(context).pop();
      },
      isLoading: _isVerifying,
    );
  }

  void _verifyTransaction(Transaction transaction) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null) {
      context.read<TransactionDetailCubit>().verifyTransaction(
        transaction.id,
        currentUserId,
      );
    }
    Navigator.of(context).pop();
  }

  void _completeTransaction(Transaction transaction) {
    context.read<TransactionDetailCubit>().completeTransaction(transaction.id);
  }

  void _shareTransaction(Transaction transaction) {
    final summary = TransactionUtils.getTransactionSummary(transaction);
    
    CustomToast.show(
      context,
      message: 'Share: $summary',
      isSuccess: true,
    );
  }
}