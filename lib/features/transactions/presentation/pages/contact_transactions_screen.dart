import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

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
  double _totalLending = 0.0;
  double _totalBorrowing = 0.0;
  double _netAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadContactTransactions();
  }

  void _loadContactTransactions() {
    context.read<TransactionCubit>().getContactTransactions(widget.contact.phone);
  }

  void _calculateTotals(List<Transaction> transactions) {
    double lending = 0.0;
    double borrowing = 0.0;

    for (final transaction in transactions) {
      if (transaction.status.isCompleted) {
        if (transaction.type == TransactionType.lending) {
          lending += transaction.amount;
        } else {
          borrowing += transaction.amount;
        }
      }
    }

    setState(() {
      _totalLending = lending;
      _totalBorrowing = borrowing;
      _netAmount = lending - borrowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case ContactTransactionsLoaded():
            setState(() {
              _transactions = state.transactions;
            });
            _calculateTotals(state.transactions);
          case TransactionVerified():
            CustomToast.show(
              context,
              message: 'Transaction verified successfully',
              isSuccess: true,
            );
            _loadContactTransactions();
          case TransactionCompleted():
            CustomToast.show(
              context,
              message: 'Transaction completed successfully',
              isSuccess: true,
            );
            _loadContactTransactions();
          case TransactionDeleted():
            CustomToast.show(
              context,
              message: 'Transaction deleted successfully',
              isSuccess: true,
            );
            _loadContactTransactions();
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
          title: Text(widget.contact.name),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {
                context.push('/transaction-form', extra: {
                  'scannedContactPhone': widget.contact.phone,
                  'scannedContactName': widget.contact.name,
                  'scannedContactEmail': widget.contact.email,
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildContactHeader(),
            _buildSummaryCards(),
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
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (widget.contact.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Lending',
                  'NPR ${_totalLending.toStringAsFixed(2)}',
                  Colors.green,
                  Icons.trending_up,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Borrowing',
                  'NPR ${_totalBorrowing.toStringAsFixed(2)}',
                  Colors.orange,
                  Icons.trending_down,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _netAmount >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_netAmount >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Net Amount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NPR ${_netAmount.abs().toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _netAmount >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _netAmount >= 0 
                      ? '${widget.contact.name} owes you'
                      : 'You owe ${widget.contact.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _netAmount >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final theme = Theme.of(context);
    
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
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
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first transaction with ${widget.contact.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    context.push('/transaction-form', extra: {
                      'scannedContactPhone': widget.contact.phone,
                      'scannedContactName': widget.contact.name,
                      'scannedContactEmail': widget.contact.email,
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
                  context.push('/transaction-detail/${transaction.id}');
                },
                onVerify: transaction.canBeVerified
                    ? () => _verifyTransaction(transaction)
                    : null,
                onComplete: transaction.canBeCompleted
                    ? () => _completeTransaction(transaction)
                    : null,
                onDelete: transaction.isPending
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
    context.read<TransactionCubit>().verifyTransaction(
      transaction.id,
      'current-user-id', //TODO: Replace with actual current user ID
    );
  }

  void _completeTransaction(Transaction transaction) {
    context.read<TransactionCubit>().completeTransaction(transaction.id);
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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
}