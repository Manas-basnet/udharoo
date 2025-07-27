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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final topPadding = mediaQuery.padding.top;

    final expandedHeight = _calculateExpandedHeight(screenHeight, topPadding);
    final horizontalPadding = screenWidth * 0.04;
    final verticalSpacing = screenHeight * 0.01;

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
                _buildResponsiveSliverAppBar(
                  theme, 
                  state, 
                  expandedHeight, 
                  horizontalPadding,
                  verticalSpacing,
                  topPadding,
                ),
                _buildFilterSliver(theme, horizontalPadding),
                _buildTransactionsSliver(state, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateExpandedHeight(double screenHeight, double topPadding) {
    // Base height + responsive calculation
    final baseHeight = kToolbarHeight + topPadding;
    final additionalHeight = screenHeight * 0.08; // 8% of screen height
    return baseHeight + additionalHeight;
  }

  Widget _buildResponsiveSliverAppBar(
    ThemeData theme, 
    TransactionState state, 
    double expandedHeight,
    double horizontalPadding,
    double verticalSpacing,
    double topPadding,
  ) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      leading: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              'Transactions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      leadingWidth: double.infinity,
      actions: _buildAppBarActions(state, theme),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for the toolbar
                SizedBox(height: kToolbarHeight + verticalSpacing),
                
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

  List<Widget> _buildAppBarActions(TransactionState state, ThemeData theme) {
    return [
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
      SizedBox(width: MediaQuery.of(context).size.width * 0.02), // 2% spacing
    ];
  }

  Widget _buildResponsiveSummary(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SizedBox.shrink();
    }

    double totalLent = 0;
    double totalBorrowed = 0;
    
    for (final transaction in state.lentTransactions) {
      totalLent += transaction.amount;
    }
    
    for (final transaction in state.borrowedTransactions) {
      totalBorrowed += transaction.amount;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ResponsiveSummaryItem(
                    title: 'Lent',
                    amount: totalLent,
                    color: Colors.green,
                    constraints: constraints,
                  ),
                ),
                Container(
                  width: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _ResponsiveSummaryItem(
                    title: 'Borrowed',
                    amount: totalBorrowed,
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

  Widget _buildPendingIconWithBadge(TransactionState state, ThemeData theme) {
    int pendingCount = 0;
    if (state is TransactionLoaded) {
      pendingCount = state.pendingTransactions.length;
    }

    return Stack(
      clipBehavior: Clip.none,
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
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1,
                ),
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

  Widget _buildFilterSliver(ThemeData theme, double horizontalPadding) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ResponsiveFilterSliverDelegate(
        theme: theme,
        horizontalPadding: horizontalPadding,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: SafeArea(
            top: true,
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
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

class _ResponsiveSummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final BoxConstraints constraints;

  const _ResponsiveSummaryItem({
    required this.title,
    required this.amount,
    required this.color,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font sizes based on available width
    final titleFontSize = (constraints.maxWidth * 0.08).clamp(12.0, 16.0);
    final amountFontSize = (constraints.maxWidth * 0.12).clamp(14.0, 20.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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