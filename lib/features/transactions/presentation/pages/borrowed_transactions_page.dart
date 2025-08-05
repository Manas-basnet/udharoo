import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

enum BorrowedTransactionFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

class BorrowedTransactionsPage extends StatefulWidget {
  const BorrowedTransactionsPage({super.key});

  @override
  State<BorrowedTransactionsPage> createState() => _BorrowedTransactionsPageState();
}

class _BorrowedTransactionsPageState extends State<BorrowedTransactionsPage> {
  final ScrollController _scrollController = ScrollController();
  BorrowedTransactionFilter _selectedFilter = BorrowedTransactionFilter.all;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final horizontalPadding = _getResponsiveHorizontalPadding(screenWidth);
    final expandedHeight = _calculateExpandedHeight(screenHeight, topPadding);

    return BlocConsumer<TransactionCubit, TransactionState>(
      listener: (context, state) {
        _handleStateChanges(context, state);
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionCubit>().loadTransactions();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(
                    theme, 
                    state, 
                    expandedHeight, 
                    horizontalPadding,
                  ),
                  _buildSummaryCards(theme, state),
                  _buildFilterSection(theme, horizontalPadding, state),
                  _buildTransactionsSliver(state, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, TransactionState state) {
    if (state.hasSuccess) {
      CustomToast.show(
        context,
        message: state.successMessage!,
        isSuccess: true,
      );
      context.read<TransactionCubit>().clearSuccess();
    }
    
    if (state.hasError) {
      CustomToast.show(
        context,
        message: state.errorMessage!,
        isSuccess: false,
      );
      context.read<TransactionCubit>().clearError();
    }
  }

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    return 20.0;
  }

  double _calculateExpandedHeight(double screenHeight, double topPadding) {
    final baseHeight = kToolbarHeight;
    return baseHeight;
  }

  Widget _buildSliverAppBar(
    ThemeData theme, 
    TransactionState state, 
    double expandedHeight,
    double horizontalPadding,
  ) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        'Money I Borrowed',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        _buildActionButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          theme: theme,
          onPressed: () {
            final borrowedTransactions = state.transactions
                .where((t) => t.isBorrowed)
                .toList();
            if (borrowedTransactions.isNotEmpty) {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: borrowedTransactions,
                  searchType: 'borrowed',
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.trending_up_rounded,
          tooltip: 'Lent',
          theme: theme,
          onPressed: () => context.pushReplacement(Routes.lentTransactions),
        ),
        SizedBox(width: horizontalPadding),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    Color backgroundColor;
    
    switch (tooltip) {
      case 'Search':
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.9);
        break;
      case 'Lent':
        backgroundColor = Colors.green.withValues(alpha: 0.9);
        break;
      default:
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.9);
    }
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, TransactionState state) {
    final borrowedTransactions = state.transactions.where((t) => t.isBorrowed).toList();
    
    final activeBorrowedAmount = borrowedTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final needsResponseAmount = borrowedTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = borrowedTransactions
        .where((t) => t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'You owe them',
                amount: activeBorrowedAmount,
                color: Colors.orange,
                icon: Icons.trending_down_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = BorrowedTransactionFilter.active;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Needs Response',
                amount: needsResponseAmount,
                color: Colors.orange,
                icon: Icons.hourglass_empty_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = BorrowedTransactionFilter.needsResponse;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Paid Back',
                amount: completedAmount,
                color: Colors.blue,
                icon: Icons.check_circle_outline,
                onTap: () {
                  setState(() {
                    _selectedFilter = BorrowedTransactionFilter.completed;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme, double horizontalPadding, TransactionState state) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterSliverDelegate(
        theme: theme,
        horizontalPadding: horizontalPadding,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', BorrowedTransactionFilter.all, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Needs Response', BorrowedTransactionFilter.needsResponse, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Active', BorrowedTransactionFilter.active, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', BorrowedTransactionFilter.completed, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BorrowedTransactionFilter filter, ThemeData theme, TransactionState state) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange,
              Colors.orange.withValues(alpha: 0.8),
            ],
          ) : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.orange
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected 
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSliver(TransactionState state, ThemeData theme) {
    if (state.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasError && !state.hasTransactions) {
      return SliverFillRemaining(
        child: _buildErrorState(state.errorMessage!, theme),
      );
    }

    final filteredTransactions = _getFilteredTransactions(state);

    if (filteredTransactions.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = filteredTransactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => context.push(
                  Routes.transactionDetail,
                  extra: transaction,
                ),
                child: TransactionListItem(transaction: transaction),
              ),
            );
          },
          childCount: filteredTransactions.length,
        ),
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(TransactionState state) {
    final borrowedTransactions = state.transactions.where((t) => t.isBorrowed).toList();

    List<Transaction> filteredTransactions;

    switch (_selectedFilter) {
      case BorrowedTransactionFilter.all:
        filteredTransactions = borrowedTransactions;
        break;
      case BorrowedTransactionFilter.needsResponse:
        filteredTransactions = borrowedTransactions
            .where((t) => t.isPending)
            .toList();
        break;
      case BorrowedTransactionFilter.active:
        filteredTransactions = borrowedTransactions
            .where((t) => t.isVerified)
            .toList();
        break;
      case BorrowedTransactionFilter.completed:
        filteredTransactions = borrowedTransactions
            .where((t) => t.isCompleted)
            .toList();
        break;
    }

    return filteredTransactions
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case BorrowedTransactionFilter.all:
        message = 'No Borrowing Records';
        subtitle = 'Money you borrow from others will appear here';
        icon = Icons.trending_down_rounded;
        break;
      case BorrowedTransactionFilter.needsResponse:
        message = 'All Caught Up!';
        subtitle = 'No borrowing transactions need your response';
        icon = Icons.check_circle_outline;
        break;
      case BorrowedTransactionFilter.active:
        message = 'No Active Borrowing';
        subtitle = 'Active borrowing transactions will appear here';
        icon = Icons.verified_outlined;
        break;
      case BorrowedTransactionFilter.completed:
        message = 'No Completed Borrowing';
        subtitle = 'Money you\'ve paid back will appear here';
        icon = Icons.done_all_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  children: [
                    const TextSpan(text: 'Rs. '),
                    TextSpan(text: TransactionDisplayHelper.formatAmount(amount)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme;
  final double horizontalPadding;

  _FilterSliverDelegate({
    required this.child, 
    required this.theme,
    required this.horizontalPadding,
  });

  @override
  double get minExtent => 56.0;

  @override
  double get maxExtent => 56.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}