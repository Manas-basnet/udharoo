import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  TransactionFilter _selectedFilter = TransactionFilter.all;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, state) {
          switch (state) {
            case TransactionCreated():
              CustomToast.show(
                context,
                message: 'Transaction created successfully',
                isSuccess: true,
              );
              context.read<TransactionCubit>().resetActionState();
              break;
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
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, state),
                _buildFilterChips(theme),
                _buildTransactionsList(state, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, TransactionState state) {
    return SliverAppBar(
      expandedHeight: _isSearchExpanded ? 400 : 320,
      floating: true,
      pinned: true,
      snap: false,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      elevation: 0,
      leading: Container(),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          color: theme.colorScheme.surface,
          child: _buildExpandedHeader(theme, state),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isSearchExpanded = !_isSearchExpanded;
              if (!_isSearchExpanded) {
                _searchController.clear();
              }
            });
          },
          icon: Icon(_isSearchExpanded ? Icons.search_off : Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: _isSearchExpanded 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            foregroundColor: _isSearchExpanded 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
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
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildExpandedHeader(ThemeData theme, TransactionState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your lending and borrowing',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Transaction Summary Cards
          _buildSummaryCards(theme, state),
          
          const SizedBox(height: 20),
          
          // Search Bar (only when expanded)
          if (_isSearchExpanded) ...[
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, description, or amount...',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          _buildQuickActions(theme),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, TransactionState state) {
    if (state is! TransactionLoaded) {
      return const SizedBox.shrink();
    }
    
    double totalLent = 0;
    double totalBorrowed = 0;
    
    for (final transaction in state.transactions) {
      if (transaction.isLent) {
        totalLent += transaction.amount;
      } else {
        totalBorrowed += transaction.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Lent',
            amount: totalLent,
            color: theme.colorScheme.primary,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Borrowed',
            amount: totalBorrowed,
            color: theme.colorScheme.error,
            icon: Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: 'Completed',
            subtitle: 'View completed transactions',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onTap: () => context.push(Routes.completedTransactions),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'Rejected',
            subtitle: 'View rejected transactions',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onTap: () => context.push(Routes.rejectedTransactions),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
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

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((transaction) {
        return transaction.otherParty.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.amount.toString().contains(_searchQuery);
      }).toList();
    }

    return transactions;
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No transactions found';
      icon = Icons.search_off;
    } else {
      switch (_selectedFilter) {
        case TransactionFilter.all:
          message = 'No transactions yet';
          icon = Icons.receipt_long;
          break;
        case TransactionFilter.pending:
          message = 'No pending transactions';
          icon = Icons.schedule;
          break;
        case TransactionFilter.verified:
          message = 'No verified transactions';
          icon = Icons.verified;
          break;
        case TransactionFilter.lent:
          message = 'No money lent yet';
          icon = Icons.arrow_upward;
          break;
        case TransactionFilter.borrowed:
          message = 'No money borrowed yet';
          icon = Icons.arrow_downward;
          break;
      }
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
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_searchQuery.isEmpty && _selectedFilter == TransactionFilter.all) ...[
            const SizedBox(height: 8),
            Text(
              'Create your first transaction to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
          const SizedBox(height: 16),
          Text(
            'Error loading transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(
                'Rs. ${amount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}