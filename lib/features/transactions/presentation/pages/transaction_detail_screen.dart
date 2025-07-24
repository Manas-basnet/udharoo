import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
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
  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  void _loadTransaction() {
    context.read<TransactionCubit>().getTransactionById(widget.transactionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionVerified():
            CustomToast.show(
              context,
              message: 'Transaction verified successfully',
              isSuccess: true,
            );
            _loadTransaction();
          case TransactionCompleted():
            CustomToast.show(
              context,
              message: 'Transaction completed successfully',
              isSuccess: true,
            );
            _loadTransaction();
          case TransactionUpdated():
            CustomToast.show(
              context,
              message: 'Transaction updated successfully',
              isSuccess: true,
            );
            _loadTransaction();
          case TransactionDeleted():
            CustomToast.show(
              context,
              message: 'Transaction deleted successfully',
              isSuccess: true,
            );
            context.pop();
          case TransactionError():
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
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state is TransactionDetailLoaded) {
                  return PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, state.transaction),
                    itemBuilder: (context) => [
                      if (state.transaction.isPending) ...[
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
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
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
                    color: _getTypeColor(transaction.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(transaction.type),
                    size: 48,
                    color: _getTypeColor(transaction.type),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  transaction.type.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  transaction.formattedAmount,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _getTypeColor(transaction.type),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(transaction.status),
                        size: 16,
                        color: _getStatusColor(transaction.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction.status.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection('Contact Information', [
            _buildInfoRow(Icons.person, 'Name', transaction.contactName),
            _buildInfoRow(Icons.phone, 'Phone', transaction.contactPhone),
            if (transaction.contactEmail != null)
              _buildInfoRow(Icons.email, 'Email', transaction.contactEmail!),
          ]),
          
          const SizedBox(height: 16),
          
          _buildInfoSection('Transaction Details', [
            _buildInfoRow(Icons.access_time, 'Created', _formatDateTime(transaction.createdAt)),
            if (transaction.updatedAt != transaction.createdAt)
              _buildInfoRow(Icons.update, 'Updated', _formatDateTime(transaction.updatedAt)),
            if (transaction.dueDate != null)
              _buildInfoRow(
                Icons.event,
                'Due Date',
                _formatDate(transaction.dueDate!),
                textColor: _isDueDatePassed(transaction.dueDate!) ? Colors.red : null,
              ),
            if (transaction.description != null)
              _buildInfoRow(Icons.note, 'Description', transaction.description!),
          ]),
          
          if (transaction.verificationRequired || transaction.isVerified) ...[
            const SizedBox(height: 16),
            
            _buildInfoSection('Verification', [
              _buildInfoRow(
                Icons.verified_user,
                'Verification Required',
                transaction.verificationRequired ? 'Yes' : 'No',
              ),
              if (transaction.isVerified) ...[
                _buildInfoRow(Icons.check_circle, 'Status', 'Verified'),
                if (transaction.verifiedBy != null)
                  _buildInfoRow(Icons.person_outline, 'Verified By', transaction.verifiedBy!),
              ],
            ]),
          ],
          
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
            color: theme.colorScheme.primary,
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
    if (transaction.isCompleted || transaction.status == TransactionStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (transaction.canBeVerified) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _verifyTransaction(transaction),
              icon: const Icon(Icons.verified_user),
              label: const Text('Verify Transaction'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (transaction.canBeCompleted) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _completeTransaction(transaction),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

  void _handleMenuAction(String action, Transaction transaction) {
    switch (action) {
      case 'edit':
        context.push('/transaction-form', extra: transaction);
        break;
      case 'delete':
        _showDeleteDialog(transaction);
        break;
      case 'share':
        _shareTransaction(transaction);
        break;
    }
  }

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TransactionCubit>().deleteTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _verifyTransaction(Transaction transaction) {
    context.read<TransactionCubit>().verifyTransaction(
      transaction.id,
      'current-user-id', // TODO: Replace with actual current user ID
    );
  }

  void _completeTransaction(Transaction transaction) {
    context.read<TransactionCubit>().completeTransaction(transaction.id);
  }

  void _shareTransaction(Transaction transaction) {
    // Implement share functionality
    CustomToast.show(
      context,
      message: 'Share functionality coming soon',
      isSuccess: false,
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.lending:
        return Colors.green;
      case TransactionType.borrowing:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.lending:
        return Icons.trending_up;
      case TransactionType.borrowing:
        return Icons.trending_down;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.verified:
        return Icons.verified;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isDueDatePassed(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }
}