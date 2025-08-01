import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ContactTransactionsPage extends StatefulWidget {
  final Contact contact;

  const ContactTransactionsPage({
    super.key,
    required this.contact,
  });

  @override
  State<ContactTransactionsPage> createState() => _ContactTransactionsPageState();
}

class _ContactTransactionsPageState extends State<ContactTransactionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactTransactionsCubit>().loadContactTransactions(widget.contact.contactUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final horizontalPadding = _getResponsiveHorizontalPadding(screenWidth);

    return Scaffold(
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
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ContactTransactionsCubit>().loadContactTransactions(widget.contact.contactUserId);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, horizontalPadding),
                _buildContactInfoSliver(theme, horizontalPadding),
                if (state is ContactTransactionsLoaded && state.transactions.isNotEmpty)
                  _buildTransactionSummarySliver(theme, horizontalPadding, state.transactions),
                _buildTransactionsSliver(state, theme, horizontalPadding),
              ],
            ),
          );
        },
      ),
    );
  }

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 840) return 24.0;
    return 32.0;
  }

  Widget _buildSliverAppBar(ThemeData theme, double horizontalPadding) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: 120,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 24),
      ),
      title: Text(
        widget.contact.displayName,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _createNewTransaction(context),
          icon: const Icon(Icons.add_rounded, size: 24),
          tooltip: 'New Transaction',
        ),
        SizedBox(width: horizontalPadding),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding + 56,
              kToolbarHeight + 16,
              horizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Transaction history with ${widget.contact.displayName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoSliver(ThemeData theme, double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  widget.contact.displayName.isNotEmpty 
                      ? widget.contact.displayName[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.headlineSmall?.copyWith(
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
                    widget.contact.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contact.phoneNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (widget.contact.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.contact.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
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

  Widget _buildTransactionSummarySliver(ThemeData theme, double horizontalPadding, List<Transaction> transactions) {
    final totalTransactions = transactions.length;
    final totalLent = _calculateTotalLent(transactions);
    final totalBorrowed = _calculateTotalBorrowed(transactions);

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    'Total Transactions',
                    totalTransactions.toString(),
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    'Total Lent',
                    'Rs. ${_formatAmount(totalLent)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    'Total Borrowed',
                    'Rs. ${_formatAmount(totalBorrowed)}',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

    if (transactions.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: GestureDetector(
                onTap: () => _navigateToTransactionDetail(transaction),
                child: TransactionListItem(transaction: transaction),
              ),
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first transaction with ${widget.contact.displayName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _createNewTransaction(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Transaction'),
              style: FilledButton.styleFrom(
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
              size: 64,
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
                context.read<ContactTransactionsCubit>().loadContactTransactions(widget.contact.contactUserId);
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
        'prefilledContact': widget.contact,
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