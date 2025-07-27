import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';

enum TransactionFilter { 
  all, 
  lent, 
  borrowed,
}

class PendingTransactionsPage extends StatefulWidget {
  const PendingTransactionsPage({super.key});

  @override
  State<PendingTransactionsPage> createState() => _PendingTransactionsPageState();
}

class _PendingTransactionsPageState extends State<PendingTransactionsPage> {
  final ScrollController _scrollController = ScrollController();
  TransactionFilter _selectedFilter = TransactionFilter.all;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: Column(
              children: [
                _buildStatsSection(theme, state),
                _buildFilterSection(theme),
                Expanded(
                  child: _buildTransactionsList(state, theme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Pending Transactions',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () {
                if (state is TransactionLoaded) {
                  showSearch(
                    context: context,
                    delegate: TransactionSearchDelegate(
                      transactions: state.pendingTransactions,
                      searchType: 'pending',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search, size: 20),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SizedBox.shrink();
    }

    final pendingTransactions = state.pendingTransactions;

    if (pendingTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalLent = 0;
    double totalBorrowed = 0;
    int lentCount = 0;
    int borrowedCount = 0;

    for (final transaction in pendingTransactions) {
      if (transaction.isLent) {
        totalLent += transaction.amount;
        lentCount++;
      } else {
        totalBorrowed += transaction.amount;
        borrowedCount++;
      }
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
          if (lentCount > 0 || borrowedCount > 0) ...[
            Row(
              children: [
                if (lentCount > 0)
                  Expanded(
                    child: _SummaryItem(
                      title: 'Lent',
                      amount: totalLent,
                      count: lentCount,
                      color: Colors.green,
                    ),
                  ),
                if (lentCount > 0 && borrowedCount > 0)
                  Container(
                    width: 1,
                    height: 32,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                if (borrowedCount > 0)
                  Expanded(
                    child: _SummaryItem(
                      title: 'Borrowed',
                      amount: totalBorrowed,
                      count: borrowedCount,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // CHANGE 4: Add filter section
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

  // CHANGE 4: Add filtered transactions method
  List<Transaction> _getFilteredTransactions(TransactionLoaded state) {
    final pendingTransactions = state.pendingTransactions;

    List<Transaction> filteredTransactions;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        filteredTransactions = pendingTransactions;
        break;
      case TransactionFilter.lent:
        filteredTransactions = pendingTransactions
            .where((t) => t.isLent)
            .toList();
        break;
      case TransactionFilter.borrowed:
        filteredTransactions = pendingTransactions
            .where((t) => t.isBorrowed)
            .toList();
        break;
    }

    return filteredTransactions
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'All Caught Up!';
        subtitle = 'No pending transactions require your attention.';
        break;
      case TransactionFilter.lent:
        message = 'No Pending Lending';
        subtitle = 'No pending lending transactions found.';
        break;
      case TransactionFilter.borrowed:
        message = 'No Pending Borrowing';
        subtitle = 'No pending borrowing transactions found.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
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
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Transactions'),
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
  final int count;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.count,
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
            color: color,
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
        Text(
          '$count transactions',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
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