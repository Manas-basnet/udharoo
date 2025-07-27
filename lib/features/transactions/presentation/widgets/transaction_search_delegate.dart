import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';

class TransactionSearchDelegate extends SearchDelegate<Transaction?> {
  final List<Transaction> transactions;
  final String searchType;

  TransactionSearchDelegate({
    required this.transactions,
    required this.searchType,
  });

  @override
  String get searchFieldLabel => _getSearchHint();

  String _getSearchHint() {
    switch (searchType) {
      case 'pending':
        return 'Search pending transactions...';
      case 'completed':
        return 'Search completed transactions...';
      case 'rejected':
        return 'Search rejected transactions...';
      default:
        return 'Search transactions...';
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          icon: const Icon(Icons.clear, size: 20),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back, size: 20),
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

    return Column(
      children: [
        _buildSearchResultsHeader(context, filteredTransactions.length),
        Expanded(
          child: ListView.builder(
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
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$count result${count == 1 ? '' : 's'} found',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (searchType != 'all') ...[
            Text(
              ' in $searchType',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Search ${_getSearchTypeText()}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search by contact name, phone number, description, or amount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSearchSuggestions(context,theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No ${_getSearchTypeText().toLowerCase()} match your search for "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try different keywords or check your spelling',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context, ThemeData theme) {
    final suggestions = _getSuggestions();

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
          children: suggestions.map((suggestion) => GestureDetector(
            onTap: () {
              query = suggestion;
              showResults(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                suggestion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _getSearchTypeText() {
    switch (searchType) {
      case 'pending':
        return 'Pending Transactions';
      case 'completed':
        return 'Completed Transactions';
      case 'rejected':
        return 'Rejected Transactions';
      default:
        return 'Transactions';
    }
  }

  List<String> _getSuggestions() {
    switch (searchType) {
      case 'pending':
        return ['verification', 'today', 'recent'];
      case 'completed':
        return ['last month', 'large amounts', 'recent'];
      case 'rejected':
        return ['rejected today', 'this week'];
      default:
        return ['contact name', 'phone number', 'amount', 'description'];
    }
  }

  List<Transaction> _getFilteredTransactions() {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    
    return transactions.where((transaction) {
      // Search by contact name
      if (transaction.otherParty.name.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by phone number
      if (transaction.otherParty.phoneNumber.toLowerCase().contains(lowercaseQuery)) {
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
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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