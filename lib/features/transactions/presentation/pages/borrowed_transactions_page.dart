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
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum BorrowedTransactionFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

class BorrowedTransactionsPage extends StatefulWidget {
  const BorrowedTransactionsPage({super.key});

  @override
  State<BorrowedTransactionsPage> createState() => _BorrowedTransactionsPageState();
}

class _BorrowedTransactionsPageState extends BaseTransactionPage<BorrowedTransactionsPage> {
  BorrowedTransactionFilter _selectedFilter = BorrowedTransactionFilter.all;

  @override
  String get pageTitle => 'Money I Borrowed';

  @override
  List<Transaction> get allTransactions {
    final state = context.watch<TransactionCubit>().state;
    return state.transactions.where((t) => t.isBorrowed).toList();
  }

  @override
  List<Transaction> get filteredTransactions {
    final borrowedTransactions = allTransactions;

    switch (_selectedFilter) {
      case BorrowedTransactionFilter.all:
        return borrowedTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BorrowedTransactionFilter.needsResponse:
        return borrowedTransactions.where((t) => t.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BorrowedTransactionFilter.active:
        return borrowedTransactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BorrowedTransactionFilter.completed:
        return borrowedTransactions.where((t) => t.isCompleted).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  bool get isLoading {
    final state = context.watch<TransactionCubit>().state;
    return state.isLoading;
  }

  @override
  String? get errorMessage {
    final state = context.watch<TransactionCubit>().state;
    return state.errorMessage;
  }

  @override
  bool get hasTransactions {
    // final state = context.watch<TransactionCubit>().state;
    return allTransactions.isNotEmpty;
  }

  @override
  Color get primaryColor => Colors.orange;

  @override
  Color get multiSelectColor => Colors.orange.withValues(alpha: 0.9);

  @override
  List<Widget> buildAppBarActions(BuildContext context, ThemeData theme, double horizontalPadding) {
    return [
      TransactionActionButton(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        type: ActionButtonType.search,
        onPressed: () {
          if (allTransactions.isNotEmpty) {
            showSearch(
              context: context,
              delegate: TransactionSearchDelegate(
                transactions: allTransactions,
                searchType: 'borrowed',
              ),
            );
          }
        },
      ),
      const SizedBox(width: 8),
      TransactionActionButton(
        icon: Icons.trending_up_rounded,
        tooltip: 'Lent',
        type: ActionButtonType.lent,
        onPressed: () => context.pushReplacement(Routes.lentTransactions),
      ),
    ];
  }

  @override
  List<Widget>? buildSummaryCards(BuildContext context, ThemeData theme) {
    final activeBorrowedAmount = allTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final needsResponseAmount = allTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = allTransactions
        .where((t) => t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);

    return [
      TransactionSummaryCard(
        title: 'You owe them',
        amount: activeBorrowedAmount,
        color: Colors.orange,
        icon: Icons.trending_down_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = BorrowedTransactionFilter.active;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Needs Response',
        amount: needsResponseAmount,
        color: Colors.orange,
        icon: Icons.hourglass_empty_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = BorrowedTransactionFilter.needsResponse;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Paid Back',
        amount: completedAmount,
        color: Colors.blue,
        icon: Icons.check_circle_outline,
        onTap: () {
          setState(() {
            _selectedFilter = BorrowedTransactionFilter.completed;
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
        isSelected: _selectedFilter == BorrowedTransactionFilter.all,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = BorrowedTransactionFilter.all),
      ),
      TransactionFilterChip(
        label: 'Needs Response',
        isSelected: _selectedFilter == BorrowedTransactionFilter.needsResponse,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = BorrowedTransactionFilter.needsResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == BorrowedTransactionFilter.active,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = BorrowedTransactionFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == BorrowedTransactionFilter.completed,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = BorrowedTransactionFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case BorrowedTransactionFilter.all:
        message = 'No Borrowing Records';
        subtitle = 'Money you borrow from others will appear here';
        icon = Icons.trending_down_rounded;
        break;
      case BorrowedTransactionFilter.needsResponse:
        message = 'All Caught Up!';
        subtitle = 'No borrowing transactions need your response';
        icon = Icons.check_circle_outline;
        break;
      case BorrowedTransactionFilter.active:
        message = 'No Active Borrowing';
        subtitle = 'Active borrowing transactions will appear here';
        icon = Icons.verified_outlined;
        break;
      case BorrowedTransactionFilter.completed:
        message = 'No Completed Borrowing';
        subtitle = 'Money you\'ve paid back will appear here';
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
    switch (action) {
      case MultiSelectAction.verifyAll:
        // Handle verifying all pending borrowed transactions
        for (final transactionId in selectedTransactionIds) {
          context.read<TransactionCubit>().verifyTransaction(transactionId);
        }
        break;
      case MultiSelectAction.deleteAll:
        // Handle delete all
        break;
      case MultiSelectAction.completeAll:
        // Not applicable for borrowed transactions (lender marks as complete)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        if (state.hasSuccess) {
          CustomToast.show(
            context,
            message: state.successMessage!,
            isSuccess: true,
          );
          context.read<TransactionCubit>().clearSuccess();
        }
        
        if (state.hasError) {
          CustomToast.show(
            context,
            message: state.errorMessage!,
            isSuccess: false,
          );
          context.read<TransactionCubit>().clearError();
        }
      },
      child: super.build(context),
    );
  }
}