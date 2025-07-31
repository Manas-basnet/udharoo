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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final topPadding = mediaQuery.padding.top;

    final expandedHeight = _calculateExpandedHeight(screenHeight, topPadding);
    final horizontalPadding = screenWidth * 0.04;
    final verticalSpacing = screenHeight * 0.01;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, state) {
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
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildResponsiveSliverAppBar(
                  theme, 
                  state, 
                  expandedHeight, 
                  horizontalPadding,
                  verticalSpacing,
                ),
                _buildFilterSliver(theme, horizontalPadding),
                _buildTransactionsSliver(state, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateExpandedHeight(double screenHeight, double topPadding) {
    final baseHeight = kToolbarHeight + topPadding;
    final additionalHeight = screenHeight * 0.17;
    return baseHeight + additionalHeight;
  }

  Widget _buildResponsiveSliverAppBar(
    ThemeData theme, 
    TransactionState state, 
    double expandedHeight,
    double horizontalPadding,
    double verticalSpacing,
  ) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      title: Text(
        'Pending',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (state.hasTransactions) {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: state.pendingTransactions,
                  searchType: 'pending',
                ),
              );
            }
          },
          icon: const Icon(Icons.search_rounded, size: 22),
          tooltip: 'Search',
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: kToolbarHeight + verticalSpacing),
                
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: horizontalPadding * 0.75),
                            Expanded(
                              child: Text(
                                'Transactions awaiting settlement',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: verticalSpacing * 2),
                        
                        Flexible(
                          child: _buildResponsiveSummary(theme, state),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveSummary(ThemeData theme, TransactionState state) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (lentCount > 0)
                  Expanded(
                    child: _ResponsiveSummaryItem(
                      title: 'Lent',
                      amount: totalLent,
                      count: lentCount,
                      color: Colors.green,
                      constraints: constraints,
                    ),
                  ),
                if (lentCount > 0 && borrowedCount > 0)
                  Container(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                if (borrowedCount > 0)
                  Expanded(
                    child: _ResponsiveSummaryItem(
                      title: 'Borrowed',
                      amount: totalBorrowed,
                      count: borrowedCount,
                      color: Colors.red,
                      constraints: constraints,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSliver(ThemeData theme, double horizontalPadding) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ResponsiveFilterSliverDelegate(
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
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', TransactionFilter.all, theme),
                  SizedBox(width: horizontalPadding * 0.5),
                  _buildFilterChip('Lent', TransactionFilter.lent, theme),
                  SizedBox(width: horizontalPadding * 0.5),
                  _buildFilterChip('Borrowed', TransactionFilter.borrowed, theme),
                ],
              ),
            ),
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
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

class _ResponsiveSummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final int count;
  final Color color;
  final BoxConstraints constraints;

  const _ResponsiveSummaryItem({
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final titleFontSize = (constraints.maxWidth * 0.08).clamp(12.0, 16.0);
    final amountFontSize = (constraints.maxWidth * 0.12).clamp(14.0, 20.0);
    final countFontSize = (constraints.maxWidth * 0.06).clamp(10.0, 12.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: titleFontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenWidth * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs. ${_formatAmount(amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: amountFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count transactions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: countFontSize,
              ),
              overflow: TextOverflow.ellipsis,
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

class _ResponsiveFilterSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme;
  final double horizontalPadding;

  _ResponsiveFilterSliverDelegate({
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
    if (oldDelegate is! _ResponsiveFilterSliverDelegate) return true;
    
    return oldDelegate.theme.brightness != theme.brightness ||
           oldDelegate.theme.colorScheme != theme.colorScheme ||
           oldDelegate.horizontalPadding != horizontalPadding ||
           oldDelegate.child != child;
  }
}