import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';

class CompletedTransactionsPage extends StatefulWidget {
  const CompletedTransactionsPage({super.key});

  @override
  State<CompletedTransactionsPage> createState() => _CompletedTransactionsPageState();
}

class _CompletedTransactionsPageState extends State<CompletedTransactionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, state),
                _buildStatsSection(theme, state),
                _buildTransactionsList(state, theme),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: Colors.green,
              elevation: 4,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, TransactionState state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        title: Text(
          'Completed Transactions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (state is TransactionLoaded) {
              final completedTransactions = state.transactions
                  .where((t) => t.isCompleted)
                  .toList();
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: completedTransactions,
                ),
              );
            }
          },
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final completedTransactions = state.transactions
        .where((t) => t.isCompleted)
        .toList();

    if (completedTransactions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
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

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Transactions',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${completedTransactions.length} transactions completed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    title: 'Total Lent',
                    amount: totalLent,
                    count: lentCount,
                    color: theme.colorScheme.primary,
                    icon: Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.green.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _SummaryItem(
                    title: 'Total Borrowed',
                    amount: totalBorrowed,
                    count: borrowedCount,
                    color: theme.colorScheme.error,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(TransactionState state, ThemeData theme) {
    switch (state) {
      case TransactionLoading():
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );

      case TransactionLoaded():
        final completedTransactions = state.transactions
            .where((t) => t.isCompleted)
            .toList()
          ..sort((a, b) {
            if (a.completedAt == null && b.completedAt == null) return 0;
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });

        if (completedTransactions.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(theme),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final transaction = completedTransactions[index];
              return GestureDetector(
                onTap: () => context.push(
                  Routes.transactionDetail,
                  extra: transaction,
                ),
                child: TransactionListItem(transaction: transaction),
              );
            },
            childCount: completedTransactions.length,
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Completed Transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Transactions you mark as completed will appear here. This helps you keep track of your financial history.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Transactions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              context.read<TransactionCubit>().loadTransactions();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${_formatAmount(amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
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