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

class CompletedTransactionsPage extends StatefulWidget {
  const CompletedTransactionsPage({super.key});

  @override
  State<CompletedTransactionsPage> createState() => _CompletedTransactionsPageState();
}

class _CompletedTransactionsPageState extends State<CompletedTransactionsPage> {
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
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(theme, state),
                _buildFilterSliver(theme),
                _buildTransactionsSliver(state, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, TransactionState state) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: 190,
      title: Text(
        'Completed',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      titleSpacing: 0,
      actions: [
        BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () {
                if (state is TransactionLoaded) {
                  final completedTransactions = state.transactions
                      .where((t) => t.isCompleted)
                      .toList();
                  showSearch(
                    context: context,
                    delegate: TransactionSearchDelegate(
                      transactions: completedTransactions,
                      searchType: 'completed',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search_rounded, size: 22),
              tooltip: 'Search',
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'All settled transactions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary section in expanded appbar
                if (state is TransactionLoaded) _buildSummaryInAppBar(theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryInAppBar(ThemeData theme, TransactionLoaded state) {
    final completedTransactions = state.transactions
        .where((t) => t.isCompleted)
        .toList();

    if (completedTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalLent = 0;
    double totalBorrowed = 0;
    int lentCount = 0;
    int borrowedCount = 0;

    for (final transaction in completedTransactions) {
      if (transaction.isLent) {
        totalLent += transaction.amount;
        lentCount++;
      } else {
        totalBorrowed += transaction.amount;
        borrowedCount++;
      }
    }

    return Column(
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
    );
  }

  Widget _buildFilterSliver(ThemeData theme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterSliverDelegate(
        minHeight: 56.0,
        maxHeight: 56.0,
        theme: theme,
        child: Container(
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
        ),
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

  Widget _buildTransactionsSliver(TransactionState state, ThemeData theme) {
    switch (state) {
      case TransactionLoading():
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );

      case TransactionLoaded():
        final filteredTransactions = _getFilteredTransactions(state);

        if (filteredTransactions.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(theme),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final transaction = filteredTransactions[index];
              return GestureDetector(
                onTap: () => context.push(
                  Routes.transactionDetail,
                  extra: transaction,
                ),
                child: TransactionListItem(transaction: transaction),
              );
            },
            childCount: filteredTransactions.length,
          ),
        );

      case TransactionError():
        return SliverFillRemaining(
          child: _buildErrorState(state.message, theme),
        );

      default:
        return SliverFillRemaining(
          child: _buildEmptyState(theme),
        );
    }
  }

  List<Transaction> _getFilteredTransactions(TransactionLoaded state) {
    final completedTransactions = state.transactions
        .where((t) => t.isCompleted)
        .toList();

    List<Transaction> filteredTransactions;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        filteredTransactions = completedTransactions;
        break;
      case TransactionFilter.lent:
        filteredTransactions = completedTransactions
            .where((t) => t.isLent)
            .toList();
        break;
      case TransactionFilter.borrowed:
        filteredTransactions = completedTransactions
            .where((t) => t.isBorrowed)
            .toList();
        break;
    }

    return filteredTransactions
      ..sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'No Completed Transactions';
        subtitle = 'Transactions you mark as completed will appear here.';
        break;
      case TransactionFilter.lent:
        message = 'No Completed Lending';
        subtitle = 'Completed lending transactions will appear here.';
        break;
      case TransactionFilter.borrowed:
        message = 'No Completed Borrowing';
        subtitle = 'Completed borrowing transactions will appear here.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
              Icons.error_outline_rounded,
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

// Custom delegate for pinned filter section
class _FilterSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  final ThemeData theme;

  _FilterSliverDelegate({
    required this.child, 
    required this.minHeight, 
    required this.maxHeight,
    required this.theme,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxHeight,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is! _FilterSliverDelegate) return true;
    
    return oldDelegate.minHeight != minHeight ||
           oldDelegate.maxHeight != maxHeight ||
           oldDelegate.theme.brightness != theme.brightness ||
           oldDelegate.theme.colorScheme != theme.colorScheme ||
           oldDelegate.child != child;
  }
}