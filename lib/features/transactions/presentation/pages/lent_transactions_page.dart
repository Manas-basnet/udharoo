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

enum LentTransactionFilter { 
  all, 
  awaitingResponse,
  active, 
  completed,
}

enum MultiSelectAction {
  completeAll,
  deleteAll,
}

class LentTransactionsPage extends StatefulWidget {
  const LentTransactionsPage({super.key});

  @override
  State<LentTransactionsPage> createState() => _LentTransactionsPageState();
}

class _LentTransactionsPageState extends State<LentTransactionsPage> {
  final ScrollController _scrollController = ScrollController();
  LentTransactionFilter _selectedFilter = LentTransactionFilter.all;
  
  bool _isMultiSelectMode = false;
  Set<String> _selectedTransactionIds = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _enterMultiSelectMode(String transactionId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTransactionIds = {transactionId};
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTransactionIds.clear();
    });
  }

  void _toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _selectAllTransactions(List<Transaction> transactions) {
    setState(() {
      _selectedTransactionIds = Set.from(
        transactions.map((t) => t.transactionId)
      );
    });
  }

  MultiSelectAction? _getAvailableAction(List<Transaction> allTransactions) {
    if (_selectedTransactionIds.isEmpty) return null;
    
    final selectedTransactions = allTransactions
        .where((t) => _selectedTransactionIds.contains(t.transactionId))
        .toList();
    
    if (selectedTransactions.isEmpty) return null;

    final allNeedCompletion = selectedTransactions.every((t) => 
      t.isVerified && t.isLent
    );

    if (allNeedCompletion) {
      return MultiSelectAction.completeAll;
    } else {
      return MultiSelectAction.deleteAll;
    }
  }

  String _getActionText(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.completeAll:
        return 'Mark All Complete';
      case MultiSelectAction.deleteAll:
        return 'Delete All';
    }
  }

  IconData _getActionIcon(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.completeAll:
        return Icons.check_circle_rounded;
      case MultiSelectAction.deleteAll:
        return Icons.delete_rounded;
    }
  }

  Color _getActionColor(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.completeAll:
        return Colors.blue;
      case MultiSelectAction.deleteAll:
        return Colors.red;
    }
  }

  void _handleMultiSelectAction(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.completeAll:
        CustomToast.show(
          context,
          message: 'Marking ${_selectedTransactionIds.length} transactions as complete...',
          isSuccess: true,
        );
        _exitMultiSelectMode();
        break;
      case MultiSelectAction.deleteAll:
        _showDeleteConfirmationDialog();
        break;
    }
  }

  void _showDeleteConfirmationDialog() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transactions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedTransactionIds.length} selected transactions? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              CustomToast.show(
                context,
                message: 'Deleting ${_selectedTransactionIds.length} transactions...',
                isSuccess: true,
              );
              _exitMultiSelectMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                  _isMultiSelectMode
                      ? _buildMultiSelectAppBar(theme, horizontalPadding, state)
                      : _buildSliverAppBar(
                          theme, 
                          state, 
                          expandedHeight, 
                          horizontalPadding,
                        ),
                  if (!_isMultiSelectMode) _buildSummaryCards(theme, state),
                  _buildFilterSection(theme, horizontalPadding, state),
                  _buildTransactionsSliver(state, theme),
                ],
              ),
            ),
            bottomNavigationBar: _isMultiSelectMode
                ? _buildMultiSelectBottomBar(theme, state)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectAppBar(ThemeData theme, double horizontalPadding, TransactionState state) {
    return SliverAppBar(
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        '${_selectedTransactionIds.length} selected',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            final filteredTransactions = _getFilteredTransactions(state);
            _selectAllTransactions(filteredTransactions);
          },
          icon: const Icon(
            Icons.select_all_rounded,
            color: Colors.white,
          ),
          tooltip: 'Select All',
        ),
        IconButton(
          onPressed: _exitMultiSelectMode,
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
          ),
          tooltip: 'Cancel',
        ),
        SizedBox(width: horizontalPadding),
      ],
    );
  }

  Widget _buildMultiSelectBottomBar(ThemeData theme, TransactionState state) {
    final availableAction = _getAvailableAction(state.transactions);
    
    if (availableAction == null) {
      return const SizedBox.shrink();
    }

    final actionColor = _getActionColor(availableAction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleMultiSelectAction(availableAction),
            icon: Icon(_getActionIcon(availableAction), size: 18),
            label: Text(_getActionText(availableAction)),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
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
        'Money I Lent',
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
            final lentTransactions = state.transactions
                .where((t) => t.isLent)
                .toList();
            if (lentTransactions.isNotEmpty) {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions: lentTransactions,
                  searchType: 'lent',
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.trending_down_rounded,
          tooltip: 'Borrowed',
          theme: theme,
          onPressed: () => context.pushReplacement(Routes.borrowedTransactions),
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
      case 'Borrowed':
        backgroundColor = Colors.orange.withValues(alpha: 0.9);
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
    final lentTransactions = state.transactions.where((t) => t.isLent).toList();
    
    final activeLentAmount = lentTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final awaitingResponseAmount = lentTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = lentTransactions
        .where((t) => t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'They owe you',
                amount: activeLentAmount,
                color: Colors.green,
                icon: Icons.trending_up_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = LentTransactionFilter.active;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Awaiting Response',
                amount: awaitingResponseAmount,
                color: Colors.orange,
                icon: Icons.hourglass_empty_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = LentTransactionFilter.awaitingResponse;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Received',
                amount: completedAmount,
                color: Colors.blue,
                icon: Icons.check_circle_outline,
                onTap: () {
                  setState(() {
                    _selectedFilter = LentTransactionFilter.completed;
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
                _buildFilterChip('All', LentTransactionFilter.all, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Awaiting Response', LentTransactionFilter.awaitingResponse, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Active', LentTransactionFilter.active, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', LentTransactionFilter.completed, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LentTransactionFilter filter, ThemeData theme, TransactionState state) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        if (!_isMultiSelectMode) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.green.withValues(alpha: 0.8),
            ],
          ) : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.green
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
            final isSelected = _selectedTransactionIds.contains(transaction.transactionId);
            
            return GestureDetector(
              onTap: () {
                if (_isMultiSelectMode) {
                  _toggleTransactionSelection(transaction.transactionId);
                } else {
                  context.push(Routes.transactionDetail, extra: transaction);
                }
              },
              onLongPress: () {
                if (!_isMultiSelectMode) {
                  _enterMultiSelectMode(transaction.transactionId);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: _isMultiSelectMode
                        ? Border.all(
                            color: isSelected
                                ? Colors.green
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      TransactionListItem(transaction: transaction),
                      if (_isMultiSelectMode)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green
                                  : theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: filteredTransactions.length,
        ),
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(TransactionState state) {
    final lentTransactions = state.transactions.where((t) => t.isLent).toList();

    List<Transaction> filteredTransactions;

    switch (_selectedFilter) {
      case LentTransactionFilter.all:
        filteredTransactions = lentTransactions;
        break;
      case LentTransactionFilter.awaitingResponse:
        filteredTransactions = lentTransactions
            .where((t) => t.isPending)
            .toList();
        break;
      case LentTransactionFilter.active:
        filteredTransactions = lentTransactions
            .where((t) => t.isVerified)
            .toList();
        break;
      case LentTransactionFilter.completed:
        filteredTransactions = lentTransactions
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
      case LentTransactionFilter.all:
        message = 'No Lending Records';
        subtitle = 'Money you lend to others will appear here';
        icon = Icons.trending_up_rounded;
        break;
      case LentTransactionFilter.awaitingResponse:
        message = 'All Caught Up!';
        subtitle = 'No lending transactions are awaiting response';
        icon = Icons.check_circle_outline;
        break;
      case LentTransactionFilter.active:
        message = 'No Active Lending';
        subtitle = 'Active lending transactions will appear here';
        icon = Icons.verified_outlined;
        break;
      case LentTransactionFilter.completed:
        message = 'No Completed Lending';
        subtitle = 'Money you\'ve received back will appear here';
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