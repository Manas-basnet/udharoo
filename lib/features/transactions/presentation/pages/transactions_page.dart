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
  pending, 
  verified, 
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
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
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
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, state),
                _buildSummarySection(theme, state),
                _buildFilterSection(theme),
                _buildTransactionsList(state, theme),
              ],
            ),
          ),
          floatingActionButton: _showScrollToTop
              ? FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 4,
                  child: const Icon(Icons.keyboard_arrow_up),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
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
      leading: Container(),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Transactions',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (state is TransactionLoaded) {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: state.transactions,
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
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.push(Routes.completedTransactions),
          icon: const Icon(Icons.history),
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            foregroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.push(Routes.rejectedTransactions),
          icon: const Icon(Icons.cancel),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    double totalLent = 0;
    double totalBorrowed = 0;
    int pendingCount = 0;
    
    for (final transaction in state.transactions) {
      if (transaction.isLent) {
        totalLent += transaction.amount;
      } else {
        totalBorrowed += transaction.amount;
      }
      if (transaction.isPending) {
        pendingCount++;
      }
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    title: 'Total Lent',
                    amount: totalLent,
                    color: theme.colorScheme.primary,
                    icon: Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _SummaryItem(
                    title: 'Total Borrowed',
                    amount: totalBorrowed,
                    color: theme.colorScheme.error,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            if (pendingCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount pending verification',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('All', TransactionFilter.all, theme),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', TransactionFilter.pending, theme),
            const SizedBox(width: 8),
            _buildFilterChip('Verified', TransactionFilter.verified, theme),
            const SizedBox(width: 8),
            _buildFilterChip('Lent', TransactionFilter.lent, theme),
            const SizedBox(width: 8),
            _buildFilterChip('Borrowed', TransactionFilter.borrowed, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionFilter filter, ThemeData theme) {
    final isSelected = _selectedFilter == filter;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      backgroundColor: theme.colorScheme.surface,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        transactions = state.transactions;
        break;
      case TransactionFilter.pending:
        transactions = state.transactions.where((t) => t.isPending).toList();
        break;
      case TransactionFilter.verified:
        transactions = state.transactions.where((t) => t.isVerified).toList();
        break;
      case TransactionFilter.lent:
        transactions = state.lentTransactions;
        break;
      case TransactionFilter.borrowed:
        transactions = state.borrowedTransactions;
        break;
    }

    return transactions;
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'No transactions yet';
        subtitle = 'Create your first transaction to get started';
        icon = Icons.receipt_long;
        break;
      case TransactionFilter.pending:
        message = 'No pending transactions';
        subtitle = 'All your transactions are up to date';
        icon = Icons.schedule;
        break;
      case TransactionFilter.verified:
        message = 'No verified transactions';
        subtitle = 'Verified transactions will appear here';
        icon = Icons.verified;
        break;
      case TransactionFilter.lent:
        message = 'No lending records';
        subtitle = 'Money you lend will appear here';
        icon = Icons.trending_up;
        break;
      case TransactionFilter.borrowed:
        message = 'No borrowing records';
        subtitle = 'Money you borrow will appear here';
        icon = Icons.trending_down;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),
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
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.amount,
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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