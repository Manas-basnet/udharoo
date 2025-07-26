import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_stats.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_list/transaction_list_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_stats/transaction_stats_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/received_transaction_requests/received_transaction_requests_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/completion_requests/completion_requests_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_summary_widget.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  TransactionStatus? _selectedStatus;
  TransactionType? _selectedType;
  TransactionStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final listCubit = context.read<TransactionListCubit>();
    final statsCubit = context.read<TransactionStatsCubit>();
    
    listCubit.loadTransactions();
    statsCubit.loadTransactionStats();
    
    _refreshTransactions();
    context.read<ReceivedTransactionRequestsCubit>().loadReceivedTransactionRequests();
    context.read<CompletionRequestsCubit>().loadCompletionRequests();
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      return authState.user.uid;
    }
    return null;
  }

  Widget _buildSliverContent(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async => _refreshTransactions(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 470,
            floating: true,
            pinned: true,
            snap: false,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Container(
                color: theme.colorScheme.surface,
                child: _buildExpandedHeader(theme),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    _buildStatusChips(theme),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            actions: [
              BlocBuilder<ReceivedTransactionRequestsCubit, ReceivedTransactionRequestsState>(
                builder: (context, state) {
                  final count = state is ReceivedTransactionRequestsLoaded ? state.requests.length : 0;
                  
                  if (count > 0) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: () => context.push(Routes.receivedTransactionRequests),
                            icon: const Icon(Icons.verified_user),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<CompletionRequestsCubit, CompletionRequestsState>(
                builder: (context, state) {
                  final count = state is CompletionRequestsLoaded ? state.requests.length : 0;
                  
                  if (count > 0) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: () => context.push(Routes.completionRequests),
                            icon: const Icon(Icons.pending_actions),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              foregroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              IconButton(
                onPressed: () => context.push(Routes.finishedTransactions),
                icon: const Icon(Icons.history),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  foregroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          _buildSliverTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Transactions',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      context.push(Routes.qrScanner);
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _showFilterDialog();
                    },
                    icon: Stack(
                      children: [
                        const Icon(Icons.tune),
                        if (_selectedType != null)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedType != null 
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      foregroundColor: _selectedType != null 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          BlocBuilder<TransactionStatsCubit, TransactionStatsState>(
            builder: (context, state) {
              if (state is TransactionStatsLoaded) {
                _stats = state.stats;
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    TransactionSummaryWidget(
                      stats: state.stats,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    TransactionQuickStats(
                      stats: state.stats,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stats exclude completed transactions. View completed transactions in history.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _refreshTransactions() {
    context.read<TransactionListCubit>().refreshTransactions(
      status: _selectedStatus,
      type: _selectedType,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    context.read<TransactionStatsCubit>().loadTransactionStats();
    context.read<ReceivedTransactionRequestsCubit>().loadReceivedTransactionRequests();
    context.read<CompletionRequestsCubit>().loadCompletionRequests();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        context.read<TransactionListCubit>().loadTransactions(
          status: _selectedStatus,
          type: _selectedType,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
      }
    });
  }

  void _onStatusFilterChanged(TransactionStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<TransactionListCubit>().loadTransactions(
      status: _selectedStatus,
      type: _selectedType,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionListCubit, TransactionListState>(
          listener: (context, state) {
            switch (state) {
              case TransactionListUpdated():
                CustomToast.show(
                  context,
                  message: 'Transaction updated successfully',
                  isSuccess: true,
                );
              case TransactionListDeleted():
                CustomToast.show(
                  context,
                  message: 'Transaction deleted successfully',
                  isSuccess: true,
                );
              case TransactionListError():
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
              default:
                break;
            }
          },
        ),
        BlocListener<TransactionStatsCubit, TransactionStatsState>(
          listener: (context, state) {
            if (state is TransactionStatsError) {
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
        ),
        BlocListener<CompletionRequestsCubit, CompletionRequestsState>(
          listener: (context, state) {
            switch (state) {
              case CompletionRequestSent():
                CustomToast.show(
                  context,
                  message: 'Completion request sent successfully',
                  isSuccess: true,
                );
                _refreshTransactions();
              case CompletionRequestsError():
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
              default:
                break;
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: _buildSliverContent(theme),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "transactions_fab",
          onPressed: () {
            context.push(Routes.transactionForm);
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatusChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatusChip(
            null,
            'All Active',
            _getStatusCount(null),
            theme,
          ),
          const SizedBox(width: 12),
          _buildStatusChip(
            TransactionStatus.pending,
            'Pending',
            _getStatusCount(TransactionStatus.pending),
            theme,
          ),
          const SizedBox(width: 12),
          _buildStatusChip(
            TransactionStatus.verified,
            'Verified',
            _getStatusCount(TransactionStatus.verified),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    TransactionStatus? status,
    String label,
    int count,
    ThemeData theme,
  ) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => _onStatusFilterChanged(selected ? status : null),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                    : theme.colorScheme.primary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      checkmarkColor: theme.colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
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

  int _getStatusCount(TransactionStatus? status) {
    if (_stats == null) return 0;
    
    switch (status) {
      case null:
        return _stats!.totalTransactions;
      case TransactionStatus.pending:
        return _stats!.pendingTransactions;
      case TransactionStatus.verified:
        return _stats!.verifiedTransactions;
      case TransactionStatus.completed:
        return _stats!.completedTransactions;
      case TransactionStatus.cancelled:
        return 0;
    }
  }

  Widget _buildSliverTransactionsList() {
    return BlocBuilder<TransactionListCubit, TransactionListState>(
      builder: (context, state) {
        if (state is TransactionListLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TransactionListLoaded) {
          if (state.transactions.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyStateContent(),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = state.transactions[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    index == 0 ? 20 : 0,
                    20,
                    index == state.transactions.length - 1 ? 100 : 12,
                  ),
                  child: TransactionCard(
                    transaction: transaction,
                    onTap: () {
                      context.push(Routes.transactionDetailGen(transaction.id));
                    },
                    onVerify: transaction.canBeVerified
                        ? () => _verifyTransaction(transaction)
                        : null,
                    onComplete: TransactionUtils.canUserComplete(transaction, _getCurrentUserId() ?? '')
                        ? () => _completeTransaction(transaction)
                        : null,
                    onDelete: transaction.creatorId == _getCurrentUserId() && !transaction.isVerified
                                        ? () => _deleteTransaction(transaction)
                                        : null,
                    onRequestCompletion: TransactionUtils.canUserRequestCompletion(transaction, _getCurrentUserId() ?? '')
                        ? () => _requestCompletion(transaction)
                        : null,
                  ),
                );
              },
              childCount: state.transactions.length,
            ),
          );
        }

        return SliverFillRemaining(
          child: _buildEmptyStateContent(),
        );
      },
    );
  }

  Widget _buildEmptyStateContent() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedStatus != null
                    ? Icons.search_off
                    : Icons.receipt_long_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != null
                  ? 'No matching transactions'
                  : 'No active transactions yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != null
                  ? 'Try adjusting your search or filters'
                  : 'Create your first transaction to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _selectedStatus == null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  context.push(Routes.transactionForm);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Transaction'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TransactionType?>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...TransactionType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
              });
              Navigator.of(dialogContext).pop();
              context.read<TransactionListCubit>().loadTransactions(
                status: _selectedStatus,
                type: _selectedType,
                searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              );
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransactionListCubit>().loadTransactions(
                status: _selectedStatus,
                type: _selectedType,
                searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _verifyTransaction(Transaction transaction) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null) {
      context.read<TransactionListCubit>().verifyTransaction(
        transaction.id,
        currentUserId,
      );
    } else {
      CustomToast.show(
        context,
        message: 'Please sign in to verify transactions',
        isSuccess: false,
      );
    }
  }

  void _completeTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to mark this transaction as completed?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will move the transaction to completed status and remove it from active transactions.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransactionListCubit>().completeTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only unverified transactions can be deleted.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransactionListCubit>().deleteTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _requestCompletion(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a completion request for this transaction?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction: ${transaction.contactName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Amount: ${transaction.formattedAmount}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The lender will be notified and can approve the completion request.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final currentUserId = _getCurrentUserId();
              if (currentUserId != null) {
                context.read<CompletionRequestsCubit>().requestCompletion(transaction.id, currentUserId);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}