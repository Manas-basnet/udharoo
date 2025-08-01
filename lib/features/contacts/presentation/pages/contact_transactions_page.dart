import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

enum ContactTransactionFilter { 
  all, 
  lent, 
  borrowed,
  pending,
  completed,
}

class ContactTransactionsPage extends StatefulWidget {
  final String contactUserId;

  const ContactTransactionsPage({
    super.key,
    required this.contactUserId,
  });

  @override
  State<ContactTransactionsPage> createState() => _ContactTransactionsPageState();
}

class _ContactTransactionsPageState extends State<ContactTransactionsPage> {
  ContactTransactionFilter _selectedFilter = ContactTransactionFilter.all;
  Contact? _contact;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final horizontalPadding = _getResponsiveHorizontalPadding(screenWidth);

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
                  _buildSliverAppBar(theme, horizontalPadding, transactionState),
                  _buildContactProfile(theme, horizontalPadding),
                  if (transactionState is ContactTransactionsLoaded && transactionState.transactions.isNotEmpty)
                    _buildQuickStats(theme, horizontalPadding, transactionState.transactions),
                  _buildFilterSection(theme, horizontalPadding, transactionState),
                  _buildTransactionsSliver(transactionState, theme, horizontalPadding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 840) return 24.0;
    return 32.0;
  }

  Widget _buildSliverAppBar(ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
      actions: [
        _buildActionButton(
          icon: Icons.add_rounded,
          tooltip: 'New Transaction',
          theme: theme,
          onPressed: () => _createNewTransaction(context),
        ),
        SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.analytics_outlined,
          tooltip: 'Analytics',
          theme: theme,
          onPressed: () {
            // TODO: Implement contact analytics
          },
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
      case 'New Transaction':
        backgroundColor = theme.colorScheme.primary;
        break;
      case 'Analytics':
        backgroundColor = Colors.orange;
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

  Widget _buildContactProfile(ThemeData theme, double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _contact!.displayName.isNotEmpty 
                      ? _contact!.displayName[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _contact!.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _contact!.phoneNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  if (_contact!.email != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _contact!.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, double horizontalPadding, List<Transaction> transactions) {
    final totalLent = _calculateTotalLent(transactions);
    final totalBorrowed = _calculateTotalBorrowed(transactions);
    final netBalance = totalLent - totalBorrowed;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Overview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Lent',
                    value: 'Rs. ${_formatAmount(totalLent)}',
                    color: Colors.green,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Borrowed',
                    value: 'Rs. ${_formatAmount(totalBorrowed)}',
                    color: Colors.red,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Net',
                    value: '${netBalance >= 0 ? '+' : '-'}Rs. ${_formatAmount(netBalance.abs())}',
                    color: netBalance >= 0 ? Colors.green : Colors.red,
                    icon: netBalance >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  ),
                ),
              ],
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
                _buildFilterChip('All', ContactTransactionFilter.all, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Lent', ContactTransactionFilter.lent, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Borrowed', ContactTransactionFilter.borrowed, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', ContactTransactionFilter.pending, theme, state),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', ContactTransactionFilter.completed, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ContactTransactionFilter filter, ThemeData theme, ContactTransactionsState state) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 13,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = filteredTransactions[index];
          return GestureDetector(
            onTap: () => _navigateToTransactionDetail(transaction),
            child: TransactionListItem(transaction: transaction),
          );
        },
        childCount: filteredTransactions.length,
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    List<Transaction> filtered;

    switch (_selectedFilter) {
      case ContactTransactionFilter.all:
        filtered = transactions;
        break;
      case ContactTransactionFilter.lent:
        filtered = transactions.where((t) => t.isLent).toList();
        break;
      case ContactTransactionFilter.borrowed:
        filtered = transactions.where((t) => t.isBorrowed).toList();
        break;
      case ContactTransactionFilter.pending:
        filtered = transactions.where((t) => t.isPending).toList();
        break;
      case ContactTransactionFilter.completed:
        filtered = transactions.where((t) => t.isCompleted).toList();
        break;
    }

    return filtered..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case ContactTransactionFilter.all:
        message = 'No Transactions Yet';
        subtitle = 'Start your first transaction with ${_contact!.displayName}';
        icon = Icons.receipt_long_outlined;
        break;
      case ContactTransactionFilter.lent:
        message = 'No Lending Records';
        subtitle = 'Money you lend to ${_contact!.displayName} will appear here';
        icon = Icons.trending_up;
        break;
      case ContactTransactionFilter.borrowed:
        message = 'No Borrowing Records';
        subtitle = 'Money you borrow from ${_contact!.displayName} will appear here';
        icon = Icons.trending_down;
        break;
      case ContactTransactionFilter.pending:
        message = 'No Pending Transactions';
        subtitle = 'All transactions with ${_contact!.displayName} are up to date';
        icon = Icons.check_circle_outline;
        break;
      case ContactTransactionFilter.completed:
        message = 'No Completed Transactions';
        subtitle = 'Completed transactions with ${_contact!.displayName} will appear here';
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createNewTransaction(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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

  double _calculateTotalLent(List<Transaction> transactions) {
    return transactions
        .where((t) => t.isLent)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalBorrowed(List<Transaction> transactions) {
    return transactions
        .where((t) => t.isBorrowed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _formatAmount(double amount) {
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _createNewTransaction(BuildContext context) {
    context.go(
      Routes.transactionForm,
      extra: {
        'prefilledContact': _contact,
      },
    );
  }

  void _navigateToTransactionDetail(Transaction transaction) {
    context.go(
      Routes.transactionDetail,
      extra: transaction,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

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