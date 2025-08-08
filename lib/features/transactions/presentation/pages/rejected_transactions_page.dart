import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';
import 'package:udharoo/shared/presentation/pages/transactions/base_transaction_page.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_action_button.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_filter_chip.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_summary_card.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum RejectedTransactionFilter { 
  all, 
  lent, 
  borrowed,
}

class RejectedTransactionsPage extends StatefulWidget {
  const RejectedTransactionsPage({super.key});

  @override
  State<RejectedTransactionsPage> createState() => _RejectedTransactionsPageState();
}

class _RejectedTransactionsPageState extends BaseTransactionPage<RejectedTransactionsPage> {
  RejectedTransactionFilter _selectedFilter = RejectedTransactionFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
  }

  @override
  String get pageTitle => 'Declined Transactions';

  @override
  Color get primaryColor => Colors.red;

  @override
  Color get multiSelectColor => Colors.red.withValues(alpha: 0.9);

  @override
  bool get isMainPage => false;

  @override
  TransactionPageData getPageData(BuildContext context) {
    final state = context.watch<TransactionCubit>().state;
    
    final allRejectedTransactions = state.transactions.where((t) => t.isRejected).toList();
    final filteredTransactions = _getFilteredTransactions(allRejectedTransactions);
    
    return TransactionPageData(
      allTransactions: allRejectedTransactions,
      filteredTransactions: filteredTransactions,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      hasTransactions: allRejectedTransactions.isNotEmpty,
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> rejectedTransactions) {
    switch (_selectedFilter) {
      case RejectedTransactionFilter.all:
        return rejectedTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case RejectedTransactionFilter.lent:
        return rejectedTransactions.where((t) => t.isLent).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case RejectedTransactionFilter.borrowed:
        return rejectedTransactions.where((t) => t.isBorrowed).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  List<Widget> buildAppBarActions(BuildContext context, ThemeData theme, double horizontalPadding) {
    final pageData = getPageData(context);
    
    return [
      TransactionActionButton(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        type: ActionButtonType.search,
        onPressed: () {
          if (pageData.allTransactions.isNotEmpty) {
            showSearch(
              context: context,
              delegate: TransactionSearchDelegate(
                transactions: pageData.allTransactions,
                searchType: 'declined',
              ),
            );
          }
        },
      ),
    ];
  }

  @override
  List<Widget>? buildSummaryCards(BuildContext context, ThemeData theme) {
    final pageData = getPageData(context);
    
    final rejectedLentAmount = pageData.allTransactions
        .where((t) => t.isLent)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final rejectedBorrowedAmount = pageData.allTransactions
        .where((t) => t.isBorrowed)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final totalRejectedAmount = pageData.allTransactions
        .fold(0.0, (sum, t) => sum + t.amount);

    return [
      TransactionSummaryCard(
        title: 'They declined your lending',
        amount: rejectedLentAmount,
        color: Colors.green,
        icon: Icons.trending_up_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = RejectedTransactionFilter.lent;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'You declined their lending',
        amount: rejectedBorrowedAmount,
        color: Colors.orange,
        icon: Icons.trending_down_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = RejectedTransactionFilter.borrowed;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Total Declined',
        amount: totalRejectedAmount,
        color: Colors.red,
        icon: Icons.cancel_outlined,
        onTap: () {
          setState(() {
            _selectedFilter = RejectedTransactionFilter.all;
          });
        },
      ),
    ];
  }

  @override
  List<Widget> buildFilterChips(BuildContext context, ThemeData theme) {
    final pageData = getPageData(context);
    final rejectedTransactions = pageData.allTransactions;
    
    final lentCount = rejectedTransactions.where((t) => t.isLent).length;
    final borrowedCount = rejectedTransactions.where((t) => t.isBorrowed).length;

    return [
      TransactionFilterChip(
        label: 'All',
        isSelected: _selectedFilter == RejectedTransactionFilter.all,
        colorType: FilterChipColor.red,
        onTap: () => setState(() => _selectedFilter = RejectedTransactionFilter.all),
      ),
      TransactionFilterChip(
        label: 'Lent',
        isSelected: _selectedFilter == RejectedTransactionFilter.lent,
        colorType: FilterChipColor.red,
        badgeCount: lentCount > 0 ? lentCount : null,
        onTap: () => setState(() => _selectedFilter = RejectedTransactionFilter.lent),
      ),
      TransactionFilterChip(
        label: 'Borrowed',
        isSelected: _selectedFilter == RejectedTransactionFilter.borrowed,
        colorType: FilterChipColor.red,
        badgeCount: borrowedCount > 0 ? borrowedCount : null,
        onTap: () => setState(() => _selectedFilter = RejectedTransactionFilter.borrowed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case RejectedTransactionFilter.all:
        message = 'No Declined Transactions';
        subtitle = 'Great! You don\'t have any declined transactions';
        icon = Icons.thumb_up_outlined;
        break;
      case RejectedTransactionFilter.lent:
        message = 'No Declined Lending';
        subtitle = 'No declined lending transactions found';
        icon = Icons.trending_up;
        break;
      case RejectedTransactionFilter.borrowed:
        message = 'No Declined Borrowing';
        subtitle = 'No declined borrowing transactions found';
        icon = Icons.trending_down;
        break;
    }

    return TransactionEmptyState(
      message: message,
      subtitle: subtitle,
      icon: icon,
      actionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'All clear - no declined transactions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onRefresh() {
    context.read<TransactionCubit>().loadTransactions();
  }

  @override
  void handleMultiSelectAction(MultiSelectAction action) {
    final cubit = context.read<TransactionCubit>();
    final transactionIds = selectedTransactionIds.toList();

    switch (action) {
      case MultiSelectAction.deleteAll:
        cubit.bulkDeleteTransactions(transactionIds);
        break;
      case MultiSelectAction.verifyAll:
      case MultiSelectAction.completeAll:
        break;
    }
  }

  @override
  MultiSelectAction? getAvailableAction(List<Transaction> allTransactions) {
    if (selectedTransactionIds.isEmpty) return null;

    final selectedTransactions = allTransactions
        .where((t) => selectedTransactionIds.contains(t.transactionId))
        .toList();

    final allRejected = selectedTransactions.every((t) => t.isRejected);
    
    if (allRejected) {
      return MultiSelectAction.deleteAll;
    }

    return null;
  }
}