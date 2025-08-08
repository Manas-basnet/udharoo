import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_search_delegate.dart';
import 'package:udharoo/shared/presentation/pages/transactions/base_transaction_page.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_action_button.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_filter_chip.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_summary_card.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum LentTransactionFilter { 
  all, 
  awaitingResponse,
  active, 
  completed,
}

class LentTransactionsPage extends StatefulWidget {
  const LentTransactionsPage({super.key});

  @override
  State<LentTransactionsPage> createState() => _LentTransactionsPageState();
}

class _LentTransactionsPageState extends BaseTransactionPage<LentTransactionsPage> {
  LentTransactionFilter _selectedFilter = LentTransactionFilter.all;

  @override
  String get pageTitle => 'Money I Lent';

  @override
  Color get primaryColor => Colors.green;

  @override
  Color get multiSelectColor => Colors.green.withValues(alpha: 0.9);

  @override
  bool get isMainPage => false;

  @override
  TransactionPageData getPageData(BuildContext context) {
    final state = context.watch<TransactionCubit>().state;
    
    final allLentTransactions = state.transactions.where((t) => t.isLent).toList();
    final filteredTransactions = _getFilteredTransactions(allLentTransactions);
    
    return TransactionPageData(
      allTransactions: allLentTransactions,
      filteredTransactions: filteredTransactions,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      hasTransactions: allLentTransactions.isNotEmpty,
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> lentTransactions) {
    switch (_selectedFilter) {
      case LentTransactionFilter.all:
        return lentTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LentTransactionFilter.awaitingResponse:
        return lentTransactions.where((t) => t.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LentTransactionFilter.active:
        return lentTransactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LentTransactionFilter.completed:
        return lentTransactions.where((t) => t.isCompleted).toList()
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
                searchType: 'lent',
              ),
            );
          }
        },
      ),
      const SizedBox(width: 8),
      TransactionActionButton(
        icon: Icons.trending_down_rounded,
        tooltip: 'Borrowed',
        type: ActionButtonType.borrowed,
        onPressed: () => context.pushReplacement(Routes.borrowedTransactions),
      ),
    ];
  }

  @override
  List<Widget>? buildSummaryCards(BuildContext context, ThemeData theme) {
    final pageData = getPageData(context);
    
    final activeLentAmount = pageData.allTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final awaitingResponseAmount = pageData.allTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = pageData.allTransactions
        .where((t) => t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);

    return [
      TransactionSummaryCard(
        title: 'They owe you',
        amount: activeLentAmount,
        color: Colors.green,
        icon: Icons.trending_up_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = LentTransactionFilter.active;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Awaiting Response',
        amount: awaitingResponseAmount,
        color: Colors.orange,
        icon: Icons.hourglass_empty_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = LentTransactionFilter.awaitingResponse;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Received',
        amount: completedAmount,
        color: Colors.blue,
        icon: Icons.check_circle_outline,
        onTap: () {
          setState(() {
            _selectedFilter = LentTransactionFilter.completed;
          });
        },
      ),
    ];
  }

  @override
  List<Widget> buildFilterChips(BuildContext context, ThemeData theme) {
    return [
      TransactionFilterChip(
        label: 'All',
        isSelected: _selectedFilter == LentTransactionFilter.all,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = LentTransactionFilter.all),
      ),
      TransactionFilterChip(
        label: 'Awaiting Response',
        isSelected: _selectedFilter == LentTransactionFilter.awaitingResponse,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = LentTransactionFilter.awaitingResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == LentTransactionFilter.active,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = LentTransactionFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == LentTransactionFilter.completed,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = LentTransactionFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case LentTransactionFilter.all:
        message = 'No Lending Records';
        subtitle = 'Money you lend to others will appear here';
        icon = Icons.trending_up_rounded;
        break;
      case LentTransactionFilter.awaitingResponse:
        message = 'All Caught Up!';
        subtitle = 'No lending transactions are awaiting response';
        icon = Icons.check_circle_outline;
        break;
      case LentTransactionFilter.active:
        message = 'No Active Lending';
        subtitle = 'Active lending transactions will appear here';
        icon = Icons.verified_outlined;
        break;
      case LentTransactionFilter.completed:
        message = 'No Completed Lending';
        subtitle = 'Money you\'ve received back will appear here';
        icon = Icons.done_all_rounded;
        break;
    }

    return TransactionEmptyState(
      message: message,
      subtitle: subtitle,
      icon: icon,
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
      case MultiSelectAction.completeAll:
        cubit.bulkCompleteTransactions(transactionIds);
        break;
      case MultiSelectAction.deleteAll:
        cubit.bulkDeleteTransactions(transactionIds);
        break;
      case MultiSelectAction.verifyAll:
        cubit.bulkVerifyTransactions(transactionIds);
        break;
    }
  }
}