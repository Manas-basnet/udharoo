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
import 'package:udharoo/shared/utils/transaction_display_helper.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum TransactionFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends BaseTransactionPage<TransactionsPage> {
  TransactionFilter _selectedFilter = TransactionFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
  }

  @override
  String get pageTitle => 'My Transactions';

  @override
  List<Transaction> get allTransactions {
    final state = context.watch<TransactionCubit>().state;
    return state.transactions;
  }

  @override
  List<Transaction> get filteredTransactions {
    final state = context.watch<TransactionCubit>().state;
    
    switch (_selectedFilter) {
      case TransactionFilter.all:
        return [...state.lentTransactions, ...state.borrowedTransactions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TransactionFilter.needsResponse:
        return state.pendingTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TransactionFilter.active:
        return state.transactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TransactionFilter.completed:
        return state.completedTransactions
          ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
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
    final state = context.watch<TransactionCubit>().state;
    return state.hasTransactions;
  }

  @override
  Color get primaryColor => Theme.of(context).colorScheme.primary;

  @override
  Color get multiSelectColor => Theme.of(context).colorScheme.primary.withValues(alpha: 0.9);

  @override
  List<Widget> buildAppBarActions(BuildContext context, ThemeData theme, double horizontalPadding) {
    final state = context.watch<TransactionCubit>().state;
    
    return [
      TransactionActionButton(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        type: ActionButtonType.search,
        onPressed: () {
          if (state.hasTransactions) {
            showSearch(
              context: context,
              delegate: TransactionSearchDelegate(
                transactions: state.transactions,
                searchType: 'all',
              ),
            );
          }
        },
      ),
      const SizedBox(width: 8),
      TransactionActionButton(
        icon: Icons.delete_forever,
        tooltip: 'Rejected Transactions',
        type: ActionButtonType.rejected,
        onPressed: () => context.push(Routes.rejectedTransactions),
      ),
    ];
  }

  @override
  List<Widget>? buildSummaryCards(BuildContext context, ThemeData theme) {
    final state = context.watch<TransactionCubit>().state;
    final netBalance = state.netActiveBalance;

    return [
      TransactionSummaryCard(
        title: 'They owe you',
        amount: state.totalActiveTheyOweYou,
        color: Colors.green,
        icon: Icons.trending_up_rounded,
        onTap: () => context.push(Routes.lentTransactions),
      ),
      TransactionSummaryCard(
        title: 'You owe them',
        amount: state.totalActiveYouOweThem,
        color: Colors.orange,
        icon: Icons.trending_down_rounded,
        onTap: () => context.push(Routes.borrowedTransactions),
      ),
      TransactionSummaryCard(
        title: TransactionDisplayHelper.getBalanceLabel(netBalance),
        amount: netBalance.abs(),
        color: netBalance >= 0 ? Colors.green : Colors.orange,
        icon: netBalance >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
        isNet: true,
        netPrefix: netBalance >= 0 ? '+' : '-',
      ),
    ];
  }

  @override
  List<Widget> buildFilterChips(BuildContext context, ThemeData theme) {
    final state = context.watch<TransactionCubit>().state;
    
    return [
      TransactionFilterChip(
        label: 'All',
        isSelected: _selectedFilter == TransactionFilter.all,
        onTap: () => setState(() => _selectedFilter = TransactionFilter.all),
      ),
      TransactionFilterChip(
        label: 'Needs Response',
        isSelected: _selectedFilter == TransactionFilter.needsResponse,
        badgeCount: state.pendingTransactions.length,
        onTap: () => setState(() => _selectedFilter = TransactionFilter.needsResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == TransactionFilter.active,
        onTap: () => setState(() => _selectedFilter = TransactionFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == TransactionFilter.completed,
        onTap: () => setState(() => _selectedFilter = TransactionFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        message = 'No transactions yet';
        subtitle = 'Your transactions will appear here';
        icon = Icons.receipt_long_outlined;
        break;
      case TransactionFilter.needsResponse:
        message = 'All caught up! ✨';
        subtitle = 'No transactions need your attention';
        icon = Icons.check_circle_outline;
        break;
      case TransactionFilter.active:
        message = 'No active transactions';
        subtitle = 'Active transactions waiting for payment will appear here';
        icon = Icons.verified_outlined;
        break;
      case TransactionFilter.completed:
        message = 'No completed transactions';
        subtitle = 'Completed transactions will appear here';
        icon = Icons.history_rounded;
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
    // Implement specific action handling
    switch (action) {
      case MultiSelectAction.verifyAll:
        // Handle verify all
        break;
      case MultiSelectAction.completeAll:
        // Handle complete all
        break;
      case MultiSelectAction.deleteAll:
        // Handle delete all
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