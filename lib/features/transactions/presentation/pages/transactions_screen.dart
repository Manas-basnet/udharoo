import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  TransactionStatus? _selectedStatus;
  TransactionType? _selectedType;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final cubit = context.read<TransactionCubit>();
    cubit.getTransactions(refresh: true);
    cubit.getTransactionStats();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = TransactionStatus.pending;
          break;
        case 2:
          _selectedStatus = TransactionStatus.verified;
          break;
        case 3:
          _selectedStatus = TransactionStatus.completed;
          break;
      }
    });
    _refreshTransactions();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<TransactionCubit>().state;
      if (state is TransactionsLoaded && state.hasMore) {
        context.read<TransactionCubit>().getTransactions(
          status: _selectedStatus,
          type: _selectedType,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
      }
    }
  }

  void _refreshTransactions() {
    context.read<TransactionCubit>().getTransactions(
      status: _selectedStatus,
      type: _selectedType,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      refresh: true,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _refreshTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionStatsLoaded():
            setState(() {
              _stats = state.stats;
            });
          case TransactionVerified():
            CustomToast.show(
              context,
              message: 'Transaction verified successfully',
              isSuccess: true,
            );
            _refreshTransactions();
          case TransactionCompleted():
            CustomToast.show(
              context,
              message: 'Transaction completed successfully',
              isSuccess: true,
            );
            _refreshTransactions();
          case TransactionDeleted():
            CustomToast.show(
              context,
              message: 'Transaction deleted successfully',
              isSuccess: true,
            );
            _refreshTransactions();
          case TransactionError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Navigate to QR scanner
                                context.push('/qr-scanner');
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
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
                              icon: const Icon(Icons.filter_list),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (_stats != null) ...[
                      const SizedBox(height: 20),
                      _buildStatsCards(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search),
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
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelMedium,
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Pending'),
                        Tab(text: 'Verified'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsList(),
                    _buildTransactionsList(),
                    _buildTransactionsList(),
                    _buildTransactionsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "transactions_fab",
          onPressed: () {
            context.push('/transaction-form');
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Lending',
            'NPR ${(_stats!['totalLending'] as double).toStringAsFixed(2)}',
            Colors.green,
            Icons.trending_up,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Borrowing',
            'NPR ${(_stats!['totalBorrowing'] as double).toStringAsFixed(2)}',
            Colors.orange,
            Icons.trending_down,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading && state is! TransactionsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionsLoaded) {
          if (state.transactions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshTransactions(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.transactions.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final transaction = state.transactions[index];
                return TransactionCard(
                  transaction: transaction,
                  onTap: () {
                    context.push('/transaction-detail/${transaction.id}');
                  },
                  onVerify: transaction.canBeVerified
                      ? () => _verifyTransaction(transaction)
                      : null,
                  onComplete: transaction.canBeCompleted
                      ? () => _completeTransaction(transaction)
                      : null,
                  onDelete: transaction.isPending
                      ? () => _deleteTransaction(transaction)
                      : null,
                );
              },
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No transactions found'
                : 'No transactions yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Create your first transaction to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TransactionType?>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
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
              Navigator.of(context).pop();
              _refreshTransactions();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshTransactions();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _verifyTransaction(Transaction transaction) {
    context.read<TransactionCubit>().verifyTransaction(
      transaction.id,
      'current-user-id', // TODO: Replace with actual current user ID
    );
  }

  void _completeTransaction(Transaction transaction) {
    context.read<TransactionCubit>().completeTransaction(transaction.id);
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TransactionCubit>().deleteTransaction(transaction.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}