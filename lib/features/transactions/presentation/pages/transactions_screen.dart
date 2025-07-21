import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Lent', 'Borrowed', 'Pending', 'Verified'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  
  List<Transaction> _currentTransactions = [];
  Map<String, double> _currentSummary = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadTransactions();
    _loadSummary();
  }

  void _loadTransactions() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<TransactionCubit>().getTransactions(
        userId: authState.user.uid,
        type: _getTransactionTypeFromFilter(),
        status: _getTransactionStatusFromFilter(),
      );
    }
  }

  void _loadSummary() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<TransactionCubit>().getTransactionSummary(authState.user.uid);
    }
  }

  TransactionType? _getTransactionTypeFromFilter() {
    switch (selectedFilter) {
      case 'Lent':
        return TransactionType.lend;
      case 'Borrowed':
        return TransactionType.borrow;
      default:
        return null;
    }
  }

  TransactionStatus? _getTransactionStatusFromFilter() {
    switch (selectedFilter) {
      case 'Pending':
        return TransactionStatus.pending;
      case 'Verified':
        return TransactionStatus.verified;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocListener<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is TransactionUpdated) {
            CustomToast.show(
              context,
              message: 'Transaction updated successfully!',
              isSuccess: true,
            );
            _loadInitialData();
          } else if (state is TransactionLoaded) {
            setState(() {
              _currentTransactions = state.transactions;
              _isLoading = false;
            });
          } else if (state is TransactionSearchResults) {
            setState(() {
              _currentTransactions = state.transactions;
              _isLoading = false;
            });
          } else if (state is TransactionSummaryLoaded) {
            setState(() {
              _currentSummary = state.summary;
            });
          } else if (state is TransactionLoading || state is TransactionSearching) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(theme, colorScheme),
            SliverToBoxAdapter(
              child: _buildSummaryCards(),
            ),
            _buildTransactionsList(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    final height = MediaQuery.sizeOf(context).height;
    return SliverAppBar(
      expandedHeight: height * 0.256,
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - kToolbarHeight) / (140 - kToolbarHeight);
          final isExpanded = expandRatio > 0.1;

          return FlexibleSpaceBar(
            background: Container(
              color: colorScheme.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AnimatedOpacity(
                    opacity: isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Transactions',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner_outlined),
                                  onPressed: _showQrOptions,
                                  tooltip: 'QR Options',
                                  style: IconButton.styleFrom(
                                    foregroundColor: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_outlined),
                                  onPressed: _loadInitialData,
                                  tooltip: 'Refresh',
                                  style: IconButton.styleFrom(
                                    foregroundColor: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            if (value.isNotEmpty) {
                              _performSearch();
                            } else {
                              _loadTransactions();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name or description...',
                            prefixIcon: const Icon(Icons.search_outlined),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _loadTransactions();
                                    },
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: filters.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = filters[index];
                              final isSelected = selectedFilter == filter;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedFilter = filter);
                                  _loadTransactions();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected 
                                          ? colorScheme.primary 
                                          : colorScheme.outline.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? colorScheme.onPrimary 
                                          : colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_currentSummary.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildSummaryCardsContent(_currentSummary);
  }

  Widget _buildSummaryCardsContent(Map<String, double> summary) {
    final totalLent = summary['totalLent'] ?? 0.0;
    final totalBorrowed = summary['totalBorrowed'] ?? 0.0;
    final netBalance = summary['netBalance'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Lent',
              amount: totalLent,
              color: Colors.green,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Borrowed',
              amount: totalBorrowed,
              color: Colors.orange,
              icon: Icons.trending_down,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Net Balance',
              amount: netBalance,
              color: netBalance >= 0 ? Colors.green : Colors.red,
              icon: netBalance >= 0 ? Icons.account_balance_wallet : Icons.money_off,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
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
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.abs().toStringAsFixed(0)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final screenSize = MediaQuery.sizeOf(context);
    
    if (_isLoading && _currentTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: screenSize.height * 0.4,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading transactions...'),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_currentTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(screenSize),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = _currentTransactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionCard(
                transaction: transaction,
                onTap: () => _openTransactionDetail(transaction),
                onStatusUpdate: (status) {
                  context.read<TransactionCubit>().updateTransactionStatus(
                    transaction.id,
                    status,
                  );
                },
              ),
            );
          },
          childCount: _currentTransactions.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size screenSize) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: screenSize.height * 0.5,
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No transactions found' 
                  : 'No transactions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Create your first transaction to get started',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _showCreateTransactionOptions,
                icon: const Icon(Icons.add),
                label: const Text('Create Transaction'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "finished_transactions_fab",
          onPressed: () => context.push(Routes.finishedTransactions),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 2,
          mini: true,
          child: const Icon(Icons.task_alt),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: "transactions_fab",
          onPressed: _showCreateTransactionOptions,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: const Icon(Icons.add),
          label: const Text('New'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  void _openTransactionDetail(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (dialogContext) => BlocProvider.value(
          value: context.read<TransactionCubit>(),
          child: TransactionDetailScreen(transaction: transaction),
        ),
      ),
    ).then((_) => _loadInitialData());
  }

  void _performSearch() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<TransactionCubit>().searchTransactions(
        userId: authState.user.uid,
        query: _searchQuery,
        type: _getTransactionTypeFromFilter(),
        status: _getTransactionStatusFromFilter(),
      );
    }
  }

  void _showQrOptions() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code Options',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan or generate QR codes for quick transactions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildBottomSheetAction(
                      context,
                      icon: Icons.qr_code_scanner,
                      title: 'Scan QR',
                      subtitle: 'Scan someone\'s QR',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.qrScanner);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBottomSheetAction(
                      context,
                      icon: Icons.qr_code,
                      title: 'My QR',
                      subtitle: 'Show your QR code',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.qrGenerator);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTransactionOptions() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Transaction',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the type of transaction you want to create',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildBottomSheetAction(
                      context,
                      icon: Icons.trending_up,
                      title: 'Lend Money',
                      subtitle: 'You are lending',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.transactionForm);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBottomSheetAction(
                      context,
                      icon: Icons.trending_down,
                      title: 'Borrow Money',
                      subtitle: 'You are borrowing',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.transactionForm);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final Function(TransactionStatus) onStatusUpdate;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getTransactionColor().withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTransactionColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTransactionIcon(),
                    color: _getTransactionColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getPersonName(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${transaction.amount.toStringAsFixed(0)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getTransactionColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(transaction.createdAt),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          _buildStatusBadge(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (transaction.description != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
            
            if (transaction.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusUpdate(TransactionStatus.rejected),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onStatusUpdate(TransactionStatus.verified),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTransactionColor() {
    if (transaction.isLending) return Colors.green;
    return Colors.orange;
  }

  IconData _getTransactionIcon() {
    if (transaction.isLending) return Icons.trending_up;
    return Icons.trending_down;
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.completed:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.verified:
        return 'Verified';
      case TransactionStatus.rejected:
        return 'Rejected';
      case TransactionStatus.completed:
        return 'Completed';
    }
  }

  String _getPersonName() {
    if (transaction.isLending) {
      return transaction.toUserName ?? 'Unknown Person';
    } else {
      return transaction.fromUserName ?? 'Unknown Person';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}