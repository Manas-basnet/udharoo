import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';

class TransactionSearchDelegate extends SearchDelegate<Transaction?> {
  final List<Transaction> transactions;

  TransactionSearchDelegate({required this.transactions, required String searchType});

  @override
  String get searchFieldLabel => 'Search transactions...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return _buildNoResultsState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return GestureDetector(
          onTap: () {
            close(context, transaction);
            context.push(
              Routes.transactionDetail,
              extra: transaction,
            );
          },
          child: TransactionListItem(transaction: transaction),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
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
            child: Icon(
              Icons.search,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Search by contact name, description, or amount',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchSuggestions(theme),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off,
              size: 40,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try searching with different keywords or check your spelling',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(ThemeData theme) {
    final suggestions = [
      'Recent transactions',
      'Large amounts',
      'Pending status',
      'Last month',
    ];

    return Column(
      children: [
        Text(
          'Try searching for:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  List<Transaction> _getFilteredTransactions() {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    
    return transactions.where((transaction) {
      // Search by contact name
      if (transaction.otherParty.name.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by description
      if (transaction.description.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by amount
      if (transaction.amount.toString().contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by status
      final statusText = _getStatusText(transaction.status).toLowerCase();
      if (statusText.contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by type
      final typeText = transaction.isLent ? 'lent' : 'borrowed';
      if (typeText.contains(lowercaseQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingVerification:
        return 'pending';
      case TransactionStatus.verified:
        return 'verified';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.rejected:
        return 'rejected';
    }
  }
}