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

class RejectedTransactionsPage extends StatefulWidget {
  const RejectedTransactionsPage({super.key});

  @override
  State<RejectedTransactionsPage> createState() => _RejectedTransactionsPageState();
}

class _RejectedTransactionsPageState extends State<RejectedTransactionsPage> {
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
                _buildSliverAppBar(
                  theme, 
                  state, 
                  expandedHeight, 
                  horizontalPadding,
                ),
                _buildSummaryCards(theme, state),
                _buildAnalysisSection(theme, horizontalPadding),
                _buildFilterSection(theme, horizontalPadding, state),
                _buildTransactionsSliver(state, theme),
              ],
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
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        'Rejected Transactions',
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
            if (state.hasTransactions) {
              final rejectedTransactions = state.transactions
                  .where((t) => t.isRejected)
                  .toList();
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: rejectedTransactions,
                  searchType: 'rejected',
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.done_all_rounded,
          tooltip: 'Completed',
          theme: theme,
          onPressed: () => context.push(Routes.completedTransactions),
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
      case 'Completed':
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
    final rejectedTransactions = state.transactions
        .where((t) => t.isRejected)
        .toList();
    
    double totalLent = 0;
    double totalBorrowed = 0;
    
    for (final transaction in rejectedTransactions) {
      if (transaction.isLent) {
        totalLent += transaction.amount;
      } else {
        totalBorrowed += transaction.amount;
      }
    }

    final netAmount = totalLent - totalBorrowed;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withValues(alpha: 0.05),
              Colors.red.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Lent',
                amount: totalLent,
                color: Colors.green,
                icon: Icons.trending_up_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _SummaryCard(
                title: 'Total Borrowed',
                amount: totalBorrowed,
                color: Colors.red,
                icon: Icons.trending_down_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _SummaryCard(
                title: 'Net Balance',
                amount: netAmount.abs(),
                color: netAmount >= 0 ? Colors.green : Colors.red,
                icon: netAmount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                isNet: true,
                netPrefix: netAmount >= 0 ? '+' : '-',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(ThemeData theme, double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: _AnalysisButton(
                icon: Icons.date_range_rounded,
                label: 'Date Range',
                onTap: () {
                  // TODO: Implement date range picker
                },
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnalysisButton(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () {
                  // TODO: Implement analytics view
                },
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnalysisButton(
                icon: Icons.delete_outline_rounded,
                label: 'Clear All',
                onTap: () {
                  // TODO: Implement clear all rejected
                },
                theme: theme,
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
            color: theme.colorScheme.surface,
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
                _buildFilterChip('All', TransactionFilter.all, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Lent', TransactionFilter.lent, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Borrowed', TransactionFilter.borrowed, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionFilter filter, ThemeData theme, TransactionState state) {
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
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ) : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
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
  }

  List<Transaction> _getFilteredTransactions(TransactionState state) {
    final rejectedTransactions = state.transactions
        .where((t) => t.isRejected)
        .toList();

    List<Transaction> filteredTransactions;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        filteredTransactions = rejectedTransactions;
        break;
      case TransactionFilter.lent:
        filteredTransactions = rejectedTransactions
            .where((t) => t.isLent)
            .toList();
        break;
      case TransactionFilter.borrowed:
        filteredTransactions = rejectedTransactions
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
    IconData icon;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'No Rejected Transactions';
        subtitle = 'Great! You don\'t have any rejected transactions';
        icon = Icons.thumb_up_outlined;
        break;
      case TransactionFilter.lent:
        message = 'No Rejected Lending';
        subtitle = 'No rejected lending transactions found';
        icon = Icons.trending_up;
        break;
      case TransactionFilter.borrowed:
        message = 'No Rejected Borrowing';
        subtitle = 'No rejected borrowing transactions found';
        icon = Icons.trending_down;
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
  final bool isNet;
  final String? netPrefix;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.isNet = false,
    this.netPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
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
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                children: [
                  if (isNet && netPrefix != null)
                    TextSpan(
                      text: netPrefix,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  const TextSpan(text: 'Rs. '),
                  TextSpan(text: _formatAmount(amount)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class _AnalysisButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _AnalysisButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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