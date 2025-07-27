import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';

class CompletedTransactionsPage extends StatefulWidget {
  const CompletedTransactionsPage({super.key});

  @override
  State<CompletedTransactionsPage> createState() => _CompletedTransactionsPageState();
}

class _CompletedTransactionsPageState extends State<CompletedTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Completed Transactions'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchSection(theme),
          Expanded(
            child: BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                return _buildTransactionsList(state, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search completed transactions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildTransactionsList(TransactionState state, ThemeData theme) {
    switch (state) {
      case TransactionLoading():
        return const Center(child: CircularProgressIndicator());

      case TransactionLoaded():
        final completedTransactions = _getFilteredCompletedTransactions(state);

        if (completedTransactions.isEmpty) {
          return _buildEmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TransactionCubit>().loadTransactions();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: completedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = completedTransactions[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<TransactionCubit>(),
                      child: TransactionDetailScreen(transaction: transaction),
                    ),
                  ),
                ),
                child: TransactionListItem(transaction: transaction),
              );
            },
          ),
        );

      case TransactionError():
        return _buildErrorState(state.message, theme);

      default:
        return _buildEmptyState(theme);
    }
  }

  List<Transaction> _getFilteredCompletedTransactions(TransactionLoaded state) {
    var completedTransactions = state.transactions
        .where((transaction) => transaction.isCompleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      completedTransactions = completedTransactions.where((transaction) {
        return transaction.otherParty.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.amount.toString().contains(_searchQuery);
      }).toList();
    }

    // Sort by completion date (most recent first)
    completedTransactions.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) return 0;
      if (a.completedAt == null) return 1;
      if (b.completedAt == null) return -1;
      return b.completedAt!.compareTo(a.completedAt!);
    });

    return completedTransactions;
  }

  Widget _buildEmptyState(ThemeData theme) {
    final message = _searchQuery.isNotEmpty 
        ? 'No completed transactions found'
        : 'No completed transactions yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Completed transactions will appear here',
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