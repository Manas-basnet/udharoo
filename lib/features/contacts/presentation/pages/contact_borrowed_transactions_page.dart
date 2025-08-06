import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

enum ContactBorrowedFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

enum MultiSelectAction {
  verifyAll,
  deleteAll,
}

class ContactBorrowedTransactionsPage extends StatefulWidget {
  final String contactUserId;

  const ContactBorrowedTransactionsPage({
    super.key,
    required this.contactUserId,
  });

  @override
  State<ContactBorrowedTransactionsPage> createState() => _ContactBorrowedTransactionsPageState();
}

class _ContactBorrowedTransactionsPageState extends State<ContactBorrowedTransactionsPage> {
  ContactBorrowedFilter _selectedFilter = ContactBorrowedFilter.all;
  Contact? _contact;
  
  bool _isMultiSelectMode = false;
  Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContactAndTransactions();
    });
  }

  void _loadContactAndTransactions() {
    context.read<ContactCubit>().getContactByUserId(widget.contactUserId).then((contact) {
      if (mounted) {
        setState(() {
          _contact = contact;
        });
        context.read<ContactTransactionsCubit>().loadContactTransactions(widget.contactUserId);
      }
    });
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

    final allNeedVerification = selectedTransactions.every((t) => 
      t.isPending && t.isBorrowed
    );

    if (allNeedVerification) {
      return MultiSelectAction.verifyAll;
    } else {
      return MultiSelectAction.deleteAll;
    }
  }

  String _getActionText(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return 'Verify All';
      case MultiSelectAction.deleteAll:
        return 'Delete All';
    }
  }

  IconData _getActionIcon(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return Icons.verified_rounded;
      case MultiSelectAction.deleteAll:
        return Icons.delete_rounded;
    }
  }

  Color _getActionColor(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return Colors.green;
      case MultiSelectAction.deleteAll:
        return Colors.red;
    }
  }

  void _handleMultiSelectAction(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        CustomToast.show(
          context,
          message: 'Verifying ${_selectedTransactionIds.length} transactions...',
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<ContactTransactionsCubit, ContactTransactionsState>(
          listener: (context, state) {
            if (state is ContactTransactionsError) {
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
          builder: (context, transactionState) {
            if (_contact == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ContactTransactionsCubit>().refreshTransactions(widget.contactUserId);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _isMultiSelectMode
                      ? _buildMultiSelectAppBar(theme, horizontalPadding, transactionState)
                      : _buildSliverAppBar(theme, horizontalPadding, expandedHeight, transactionState),
                  if (transactionState is ContactTransactionsLoaded && !_isMultiSelectMode)
                    _buildQuickStats(theme, horizontalPadding, _getBorrowedTransactions(transactionState.transactions)),
                  _buildFilterSection(theme, horizontalPadding, transactionState),
                  _buildTransactionsSliver(transactionState, theme, horizontalPadding),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _isMultiSelectMode
            ? _buildMultiSelectBottomBar(theme, context.read<ContactTransactionsCubit>().state)
            : null,
      ),
    );
  }

  Widget _buildMultiSelectAppBar(ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
    return SliverAppBar(
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
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
            if (state is ContactTransactionsLoaded) {
              final filteredTransactions = _getFilteredTransactions(state.transactions);
              _selectAllTransactions(filteredTransactions);
            }
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

  Widget _buildMultiSelectBottomBar(ThemeData theme, ContactTransactionsState state) {
    final transactions = state is ContactTransactionsLoaded ? state.transactions : <Transaction>[];
    final availableAction = _getAvailableAction(transactions);
    
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

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    return 20.0;
  }

  double _calculateExpandedHeight(double screenHeight, double topPadding) {
    final additionalHeight = (screenHeight * 0.16);
    return additionalHeight;
  }

  Widget _buildSliverAppBar(ThemeData theme, double horizontalPadding, double expandedHeight, ContactTransactionsState state) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
      actions: [
        _buildActionButton(
          icon: Icons.trending_up_rounded,
          tooltip: 'Lent',
          theme: theme,
          onPressed: () => context.pushReplacement(Routes.contactLentTransactionsF(widget.contactUserId)),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.analytics_outlined,
          tooltip: 'All Transactions',
          theme: theme,
          onPressed: () => context.pushReplacement(Routes.contactTransactionsF(widget.contactUserId)),
        ),
        SizedBox(width: horizontalPadding),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.trending_down_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Money I Borrowed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'from ${_contact!.displayName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
      case 'Lent':
        backgroundColor = Colors.green;
        break;
      case 'All Transactions':
        backgroundColor = theme.colorScheme.primary;
        break;
      default:
        backgroundColor = theme.colorScheme.primary;
    }
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
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

  Widget _buildQuickStats(ThemeData theme, double horizontalPadding, List<Transaction> borrowedTransactions) {
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
              child: _StatCard(
                title: 'You owe them',
                value: 'Rs. ${TransactionDisplayHelper.formatAmount(activeBorrowedAmount)}',
                color: Colors.orange,
                icon: Icons.trending_down_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = ContactBorrowedFilter.active;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _StatCard(
                title: 'Needs Response',
                value: 'Rs. ${TransactionDisplayHelper.formatAmount(needsResponseAmount)}',
                color: Colors.amber,
                icon: Icons.hourglass_empty_rounded,
                onTap: () {
                  setState(() {
                    _selectedFilter = ContactBorrowedFilter.needsResponse;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Paid Back',
                value: 'Rs. ${TransactionDisplayHelper.formatAmount(completedAmount)}',
                color: Colors.blue,
                icon: Icons.check_circle_outline,
                onTap: () {
                  setState(() {
                    _selectedFilter = ContactBorrowedFilter.completed;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
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
                _buildFilterChip('All', ContactBorrowedFilter.all, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Needs Response', ContactBorrowedFilter.needsResponse, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Active', ContactBorrowedFilter.active, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', ContactBorrowedFilter.completed, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ContactBorrowedFilter filter, ThemeData theme, ContactTransactionsState state) {
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

  Widget _buildTransactionsSliver(ContactTransactionsState state, ThemeData theme, double horizontalPadding) {
    if (state is ContactTransactionsLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is ContactTransactionsError) {
      return SliverFillRemaining(
        child: _buildErrorState(state.message, theme),
      );
    }

    final transactions = state is ContactTransactionsLoaded ? state.transactions : <Transaction>[];
    final filteredTransactions = _getFilteredTransactions(transactions);

    if (filteredTransactions.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
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
                  _navigateToTransactionDetail(transaction);
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
                                ? Colors.orange
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
                                  ? Colors.orange
                                  : theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
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

  List<Transaction> _getBorrowedTransactions(List<Transaction> transactions) {
    return transactions.where((t) => t.isBorrowed).toList();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final borrowedTransactions = _getBorrowedTransactions(transactions);

    List<Transaction> filtered;

    switch (_selectedFilter) {
      case ContactBorrowedFilter.all:
        filtered = borrowedTransactions;
        break;
      case ContactBorrowedFilter.needsResponse:
        filtered = borrowedTransactions.where((t) => t.isPending).toList();
        break;
      case ContactBorrowedFilter.active:
        filtered = borrowedTransactions.where((t) => t.isVerified).toList();
        break;
      case ContactBorrowedFilter.completed:
        filtered = borrowedTransactions.where((t) => t.isCompleted).toList();
        break;
    }

    return filtered..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case ContactBorrowedFilter.all:
        message = 'No borrowing records';
        subtitle = 'Money you borrow from ${_contact!.displayName} will appear here';
        break;
      case ContactBorrowedFilter.needsResponse:
        message = 'No transactions need your response';
        subtitle = 'All borrowing from ${_contact!.displayName} has been responded to';
        break;
      case ContactBorrowedFilter.active:
        message = 'No active borrowing';
        subtitle = 'Active borrowing from ${_contact!.displayName} will appear here';
        break;
      case ContactBorrowedFilter.completed:
        message = 'No completed borrowing';
        subtitle = 'Money paid back to ${_contact!.displayName} will appear here';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_down_rounded,
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
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                context.read<ContactTransactionsCubit>().refreshTransactions(widget.contactUserId);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTransactionDetail(Transaction transaction) {
    context.push(
      Routes.contactTransactionsDetail,
      extra: transaction,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap
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
          borderRadius: BorderRadius.circular(8),
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
              size: 16,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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