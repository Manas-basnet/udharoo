import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

enum TransactionFilter { 
  all, 
  lent, 
  borrowed,
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final ScrollController _scrollController = ScrollController();
  
  TransactionFilter _selectedFilter = TransactionFilter.all;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionActionSuccess():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: true,
            );
            context.read<TransactionCubit>().resetActionState();
            break;
          case TransactionError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
            break;
          default:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme, state),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: Column(
              children: [
                _buildSummarySection(theme, state),
                _buildFilterSection(theme),
                Expanded(
                  child: _buildTransactionsList(state, theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, TransactionState state) {
    return AppBar(
      title: Text(
        'Transactions',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            if (state is TransactionLoaded) {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: state.transactions,
                  searchType: 'all',
                ),
              );
            }
          },
          icon: const Icon(Icons.search, size: 20),
        ),
        IconButton(
          onPressed: () => context.push(Routes.pendingTransactions),
          icon: const Icon(Icons.schedule, size: 20),
        ),
        IconButton(
          onPressed: () => context.push(Routes.completedTransactions),
          icon: const Icon(Icons.check_circle_outline, size: 20),
        ),
        IconButton(
          onPressed: () => context.push(Routes.rejectedTransactions),
          icon: const Icon(Icons.cancel_outlined, size: 20),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SizedBox.shrink();
    }

    double totalLent = 0;
    double totalBorrowed = 0;
    int pendingCount = state.pendingTransactions.length;
    
    for (final transaction in state.lentTransactions) {
      totalLent += transaction.amount;
    }
    
    for (final transaction in state.borrowedTransactions) {
      totalBorrowed += transaction.amount;
    }

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
        children: [
          // Breakdown
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Lent',
                  amount: totalLent,
                  color: Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _SummaryItem(
                  title: 'Borrowed',
                  amount: totalBorrowed,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
          if (pendingCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$pendingCount pending verification',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip('All', TransactionFilter.all, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Lent', TransactionFilter.lent, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Borrowed', TransactionFilter.borrowed, theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionFilter filter, ThemeData theme) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(TransactionState state, ThemeData theme) {
    switch (state) {
      case TransactionLoading():
        return const Center(child: CircularProgressIndicator());

      case TransactionLoaded():
        final filteredTransactions = _getFilteredTransactions(state);

        if (filteredTransactions.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];
            return GestureDetector(
              onTap: () => context.push(
                Routes.transactionDetail,
                extra: transaction,
              ),
              child: TransactionListItem(transaction: transaction),
            );
          },
        );

      case TransactionError():
        return _buildErrorState(state.message, theme);

      default:
        return _buildEmptyState(theme);
    }
  }

  List<Transaction> _getFilteredTransactions(TransactionLoaded state) {
    List<Transaction> transactions;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        transactions = [...state.lentTransactions, ...state.borrowedTransactions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TransactionFilter.lent:
        transactions = state.lentTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TransactionFilter.borrowed:
        transactions = state.borrowedTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return transactions;
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'No transactions yet';
        subtitle = 'Create your first transaction to get started';
        break;
      case TransactionFilter.lent:
        message = 'No lending records';
        subtitle = 'Money you lend will appear here';
        break;
      case TransactionFilter.borrowed:
        message = 'No borrowing records';
        subtitle = 'Money you borrow will appear here';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                context.read<TransactionCubit>().loadTransactions();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${_formatAmount(amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
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
}