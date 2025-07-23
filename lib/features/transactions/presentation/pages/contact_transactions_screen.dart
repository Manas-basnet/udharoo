import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ContactTransactionsScreenArguments {
  final String contactName;
  final String contactPhone;

  ContactTransactionsScreenArguments({
    required this.contactName,
    required this.contactPhone,
  });
}

class ContactTransactionsScreen extends StatefulWidget {
  final String contactName;
  final String contactPhone;

  const ContactTransactionsScreen({
    super.key,
    required this.contactName,
    required this.contactPhone,
  });

  @override
  State<ContactTransactionsScreen> createState() => _ContactTransactionsScreenState();
}

class _ContactTransactionsScreenState extends State<ContactTransactionsScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Lent', 'Borrowed', 'Pending', 'Verified'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  List<Transaction> _contactTransactions = [];
  Map<String, double> _contactSummary = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContactTransactions();
  }

  void _loadContactTransactions() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      context.read<TransactionCubit>().searchTransactions(
        userId: authState.user.uid,
        query: _searchQuery.isNotEmpty ? _searchQuery : widget.contactPhone,
        type: _getTransactionTypeFromFilter(),
        status: _getTransactionStatusFromFilter(),
      );
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
      body: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is TransactionSearchResults) {
            setState(() {
              _contactTransactions = state.transactions.where((transaction) {
                return (transaction.fromUserPhone == widget.contactPhone ||
                        transaction.toUserPhone == widget.contactPhone);
              }).toList();
              _isLoading = false;
            });
            _calculateContactSummary();
          } else if (state is TransactionSearching) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(theme, colorScheme),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildContactHeader(),
                    _buildSummaryCards(),
                  ],
                ),
              ),
              _buildTransactionsList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - kToolbarHeight) / (120 - kToolbarHeight);
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
                        Text(
                          'Transactions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _loadContactTransactions();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            prefixIcon: const Icon(Icons.search_outlined),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _loadContactTransactions();
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
                                  _loadContactTransactions();
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

  Widget _buildContactHeader() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.contactName.isNotEmpty 
                    ? widget.contactName[0].toUpperCase()
                    : 'U',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
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
                  widget.contactName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contactPhone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_contactTransactions.length} transactions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_contactSummary.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final totalLent = _contactSummary['totalLent'] ?? 0.0;
    final totalBorrowed = _contactSummary['totalBorrowed'] ?? 0.0;
    final netBalance = _contactSummary['netBalance'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              title: 'Net',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
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
            style: theme.textTheme.bodyMedium?.copyWith(
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
    
    if (_isLoading && _contactTransactions.isEmpty) {
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
    
    if (_contactTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(screenSize),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = _contactTransactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ContactTransactionCard(
                transaction: transaction,
                contactName: widget.contactName,
                onTap: () => _openTransactionDetail(transaction),
              ),
            );
          },
          childCount: _contactTransactions.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size screenSize) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: screenSize.height * 0.4,
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
              'No transactions found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t made any transactions with ${widget.contactName} yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTransactionDetail(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<TransactionCubit>(),
          child: TransactionDetailScreen(transaction: transaction),
        ),
      ),
    ).then((_) => _loadContactTransactions());
  }

  void _calculateContactSummary() {
    double totalLent = 0.0;
    double totalBorrowed = 0.0;

    for (final transaction in _contactTransactions) {
      if (transaction.status == TransactionStatus.verified) {
        if (transaction.isLending) {
          totalLent += transaction.amount;
        } else {
          totalBorrowed += transaction.amount;
        }
      }
    }

    setState(() {
      _contactSummary = {
        'totalLent': totalLent,
        'totalBorrowed': totalBorrowed,
        'netBalance': totalLent - totalBorrowed,
      };
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ContactTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String contactName;
  final VoidCallback onTap;

  const _ContactTransactionCard({
    required this.transaction,
    required this.contactName,
    required this.onTap,
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
                              transaction.isLending ? 'Lent to $contactName' : 'Borrowed from $contactName',
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
        color: _getStatusColor()?.withOpacity(0.1),
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

  Color? _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.verified:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.completed:
        Colors.blue;
    }
    return null;
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