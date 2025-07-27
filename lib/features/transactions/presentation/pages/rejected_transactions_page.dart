import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_detail_screen.dart';

class RejectedTransactionsPage extends StatefulWidget {
  const RejectedTransactionsPage({super.key});

  @override
  State<RejectedTransactionsPage> createState() => _RejectedTransactionsPageState();
}

class _RejectedTransactionsPageState extends State<RejectedTransactionsPage> {
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
        title: const Text('Rejected Transactions'),
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
          hintText: 'Search rejected transactions...',
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
        final rejectedTransactions = _getFilteredRejectedTransactions(state);

        if (rejectedTransactions.isEmpty) {
          return _buildEmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TransactionCubit>().loadTransactions();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rejectedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = rejectedTransactions[index];
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

  List<Transaction> _getFilteredRejectedTransactions(TransactionLoaded state) {
    var rejectedTransactions = state.transactions
        .where((transaction) => transaction.isRejected)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      rejectedTransactions = rejectedTransactions.where((transaction) {
        return transaction.otherParty.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.amount.toString().contains(_searchQuery);
      }).toList();
    }

    // Sort by creation date (most recent first)
    rejectedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return rejectedTransactions;
  }

  Widget _buildEmptyState(ThemeData theme) {
    final message = _searchQuery.isNotEmpty 
        ? 'No rejected transactions found'
        : 'No rejected transactions';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cancel_outlined,
              size: 40,
              color: Colors.red,
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
              'Rejected transactions will appear here',
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