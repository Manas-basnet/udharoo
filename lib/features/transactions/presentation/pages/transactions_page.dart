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
          body: RefreshIndicator(
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
          ),
        );
      },
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
      expandedHeight: 160,
      leadingWidth: 200,
      leading: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Transactions',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      titleSpacing: 0,
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
          icon: const Icon(Icons.search_rounded, size: 22),
          tooltip: 'Search',
        ),
        _buildPendingIconWithBadge(state, theme),
        IconButton(
          onPressed: () => context.push(Routes.completedTransactions),
          icon: const Icon(Icons.done_all_rounded, size: 22),
          tooltip: 'Completed',
        ),
        IconButton(
          onPressed: () => context.push(Routes.rejectedTransactions),
          icon: const Icon(Icons.cancel_rounded, size: 22),
          tooltip: 'Rejected',
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
                Text(
                  'Manage your money flows',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                if (state is TransactionLoaded) _buildSummaryInAppBar(theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryInAppBar(ThemeData theme, TransactionLoaded state) {
    double totalLent = 0;
    double totalBorrowed = 0;
    
    for (final transaction in state.lentTransactions) {
      totalLent += transaction.amount;
    }
    
    for (final transaction in state.borrowedTransactions) {
      totalBorrowed += transaction.amount;
    }

    return Column(
      children: [
        // Main breakdown
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
      ],
    );
  }

  Widget _buildPendingIconWithBadge(TransactionState state, ThemeData theme) {
    int pendingCount = 0;
    if (state is TransactionLoaded) {
      pendingCount = state.pendingTransactions.length;
    }

    return Stack(
      children: [
        IconButton(
          onPressed: () => context.push(Routes.pendingTransactions),
          icon: const Icon(Icons.pending_actions_rounded, size: 22),
          tooltip: 'Pending',
        ),
        if (pendingCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                pendingCount > 99 ? '99+' : pendingCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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