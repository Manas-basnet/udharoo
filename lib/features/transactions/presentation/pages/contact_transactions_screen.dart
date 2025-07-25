import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_summary_widget.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ContactTransactionsScreenArguments {
  final String contactName;
  final String contactPhone;

  const ContactTransactionsScreenArguments({
    required this.contactName,
    required this.contactPhone,
  });
}

class ContactTransactionsScreen extends StatefulWidget {
  final TransactionContact contact;

  const ContactTransactionsScreen({
    super.key,
    required this.contact,
  });

  @override
  State<ContactTransactionsScreen> createState() => _ContactTransactionsScreenState();
}

class _ContactTransactionsScreenState extends State<ContactTransactionsScreen> {
  List<Transaction> _transactions = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadContactTransactions();
  }

  void _loadContactTransactions() {
    context.read<ContactTransactionsCubit>().loadContactTransactions(widget.contact.phone);
  }

  void _calculateTotals(List<Transaction> transactions) {
    final activeTransactions = transactions.where((t) => t.status != TransactionStatus.completed).toList();
    final summary = TransactionUtils.calculateTransactionSummary(activeTransactions);
    
    setState(() {
      _stats = {
        'totalLending': summary['totalLending'],
        'totalBorrowing': summary['totalBorrowing'],
        'netAmount': summary['netAmount'],
      };
    });
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
    
    return BlocListener<ContactTransactionsCubit, ContactTransactionsState>(
      listener: (context, state) {
        switch (state) {
          case ContactTransactionsLoaded():
            setState(() {
              _transactions = state.transactions.where((t) => t.status != TransactionStatus.completed).toList();
            });
            _calculateTotals(state.transactions);
          case ContactTransactionUpdated():
            CustomToast.show(
              context,
              message: 'Transaction updated successfully',
              isSuccess: true,
            );
            _loadContactTransactions();
          case ContactTransactionDeleted():
            CustomToast.show(
              context,
              message: 'Transaction deleted successfully',
              isSuccess: true,
            );
            _loadContactTransactions();
          case ContactTransactionsError():
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
          title: Text(widget.contact.name),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {
                context.push(Routes.transactionForm, extra: {
                  'scannedContactPhone': widget.contact.phone,
                  'scannedContactName': widget.contact.name,
                  'scannedContactEmail': widget.contact.email,
                }).then((_) {
                  _loadContactTransactions();
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildContactHeader(),
            if (_stats.isNotEmpty) _buildSummarySection(),
            Expanded(
              child: _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.contact.name[0].toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contact.phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (widget.contact.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.contact.transactionCount}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                widget.contact.transactionCount == 1 ? 'Transaction' : 'Transactions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final netAmount = _stats['netAmount'] as double? ?? 0.0;
    
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          TransactionSummaryWidget(
            stats: _stats,
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: netAmount >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (netAmount >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Net Amount (Active)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NPR ${netAmount.abs().toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: netAmount >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  netAmount >= 0 
                      ? '${widget.contact.name} owes you'
                      : 'You owe ${widget.contact.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: netAmount >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Excludes completed transactions',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final theme = Theme.of(context);
    
    return BlocBuilder<ContactTransactionsCubit, ContactTransactionsState>(
      builder: (context, state) {
        if (state is ContactTransactionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active transactions found',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first transaction with ${widget.contact.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    context.push(Routes.transactionForm, extra: {
                      'scannedContactPhone': widget.contact.phone,
                      'scannedContactName': widget.contact.name,
                      'scannedContactEmail': widget.contact.email,
                    }).then((_) {
                      _loadContactTransactions();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Transaction'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadContactTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return TransactionCard(
                transaction: transaction,
                onTap: () {
                  context.push(Routes.transactionDetailGen(transaction.id));
                },
                onVerify: transaction.canBeVerified
                    ? () => _verifyTransaction(transaction)
                    : null,
                onComplete: TransactionUtils.canUserComplete(transaction, _getCurrentUserId() ?? '')
                    ? () => _completeTransaction(transaction)
                    : null,
                onDelete: transaction.isPending && transaction.createdBy == _getCurrentUserId()
                    ? () => _deleteTransaction(transaction)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _verifyTransaction(Transaction transaction) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null) {
      context.read<ContactTransactionsCubit>().verifyTransaction(
        transaction.id,
        currentUserId,
      );
    } else {
      CustomToast.show(
        context,
        message: 'Please sign in to verify transactions',
        isSuccess: false,
      );
    }
  }

  void _completeTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to mark this transaction as completed?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
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
                      'This will move the transaction to completed status and remove it from active transactions.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ContactTransactionsCubit>().completeTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ContactTransactionsCubit>().deleteTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}