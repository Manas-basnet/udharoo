import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/pages/transactions/base_contact_transaction_page.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_action_button.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_filter_chip.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_summary_card.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum ContactBorrowedFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

class ContactBorrowedTransactionsPage extends StatefulWidget {
  final String contactUserId;

  const ContactBorrowedTransactionsPage({
    super.key,
    required this.contactUserId,
  });

  @override
  State<ContactBorrowedTransactionsPage> createState() => _ContactBorrowedTransactionsPageState();
}

class _ContactBorrowedTransactionsPageState extends BaseContactTransactionPage<ContactBorrowedTransactionsPage> {
  ContactBorrowedFilter _selectedFilter = ContactBorrowedFilter.all;

  @override
  String get contactUserId => widget.contactUserId;

  @override
  String get pageTitle => 'Money I Borrowed';

  @override
  Color get primaryColor => Colors.orange;

  @override
  Color get multiSelectColor => Colors.orange.withValues(alpha: 0.9);

  @override
  ContactTransactionPageData getContactPageData(BuildContext context) {
    final state = context.watch<ContactTransactionsCubit>().state;
    final allTransactions = state is ContactTransactionsLoaded 
        ? state.transactions.where((t) => t.isBorrowed).toList()
        : <Transaction>[];
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    
    return ContactTransactionPageData(
      allContactTransactions: allTransactions,
      filteredTransactions: filteredTransactions,
      isLoading: state is ContactTransactionsLoading,
      errorMessage: state is ContactTransactionsError ? state.message : null,
    );
  }

  @override
  MultiSelectAction? getAvailableAction(List<Transaction> allTransactions) {
    if (selectedTransactionIds.isEmpty) return null;

    final selectedTransactions = allTransactions
        .where((t) => selectedTransactionIds.contains(t.transactionId))
        .toList();

    final allPending = selectedTransactions.every((t) => t.isPending);
    final allVerifiedLent = selectedTransactions.every((t) => t.isVerified && t.isLent);
    final hasVerifiedNotCompleted = selectedTransactions.any((t) => t.isVerified && !t.isCompleted);

    if (allPending) {
      return MultiSelectAction.verifyAll;
    } else if (allVerifiedLent) {
      return MultiSelectAction.completeAll;
    } else if (!hasVerifiedNotCompleted) {
      return MultiSelectAction.deleteAll;
    }
    
    return null;
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> borrowedTransactions) {
    switch (_selectedFilter) {
      case ContactBorrowedFilter.all:
        return borrowedTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactBorrowedFilter.needsResponse:
        return borrowedTransactions.where((t) => t.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactBorrowedFilter.active:
        return borrowedTransactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactBorrowedFilter.completed:
        return borrowedTransactions.where((t) => t.isCompleted).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  List<Widget> buildContactAppBarActions(BuildContext context, ThemeData theme) {
    return [
      SmallTransactionActionButton(
        icon: Icons.trending_up_rounded,
        tooltip: 'Lent',
        type: ActionButtonType.lent,
        onPressed: () => context.pushReplacement(Routes.contactLentTransactionsF(contactUserId)),
      ),
      const SizedBox(width: 8),
      SmallTransactionActionButton(
        icon: Icons.analytics_outlined,
        tooltip: 'All Transactions',
        type: ActionButtonType.allTransactions,
        onPressed: () => context.pushReplacement(Routes.contactTransactionsF(contactUserId)),
      ),
    ];
  }

  @override
  List<Widget>? buildContactSummaryCards(BuildContext context, ThemeData theme, List<Transaction> transactions) {
    final borrowedTransactions = transactions.where((t) => t.isBorrowed).toList();
    
    final activeBorrowedAmount = borrowedTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final needsResponseAmount = borrowedTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = borrowedTransactions
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
            _selectedFilter = ContactBorrowedFilter.active;
          });
        },
      ),
      TransactionSummaryCard(
        title: 'Needs Response',
        amount: needsResponseAmount,
        color: Colors.amber,
        icon: Icons.hourglass_empty_rounded,
        onTap: () {
          setState(() {
            _selectedFilter = ContactBorrowedFilter.needsResponse;
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
            _selectedFilter = ContactBorrowedFilter.completed;
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
        isSelected: _selectedFilter == ContactBorrowedFilter.all,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = ContactBorrowedFilter.all),
      ),
      TransactionFilterChip(
        label: 'Needs Response',
        isSelected: _selectedFilter == ContactBorrowedFilter.needsResponse,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = ContactBorrowedFilter.needsResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == ContactBorrowedFilter.active,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = ContactBorrowedFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == ContactBorrowedFilter.completed,
        colorType: FilterChipColor.orange,
        onTap: () => setState(() => _selectedFilter = ContactBorrowedFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case ContactBorrowedFilter.all:
        message = 'No borrowing records';
        subtitle = 'Money you borrow from ${contact!.displayName} will appear here';
        break;
      case ContactBorrowedFilter.needsResponse:
        message = 'No transactions need your response';
        subtitle = 'All borrowing from ${contact!.displayName} has been responded to';
        break;
      case ContactBorrowedFilter.active:
        message = 'No active borrowing';
        subtitle = 'Active borrowing from ${contact!.displayName} will appear here';
        break;
      case ContactBorrowedFilter.completed:
        message = 'No completed borrowing';
        subtitle = 'Money paid back to ${contact!.displayName} will appear here';
        break;
    }

    return TransactionEmptyState(
      message: message,
      subtitle: subtitle,
      icon: Icons.trending_down_rounded,
    );
  }

  @override
  Widget? buildHeaderIcon(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.trending_down_rounded,
        color: Colors.orange,
        size: 24,
      ),
    );
  }

  @override
  void onRefresh() {
    context.read<ContactTransactionsCubit>().refreshTransactions(contactUserId);
  }

  @override
  void handleMultiSelectAction(MultiSelectAction action) {
    final cubit = context.read<TransactionCubit>();
    final transactionIds = selectedTransactionIds.toList();

    switch (action) {
      case MultiSelectAction.verifyAll:
        cubit.bulkVerifyTransactions(transactionIds);
        break;
      case MultiSelectAction.completeAll:
        cubit.bulkCompleteTransactions(transactionIds);
        break;
      case MultiSelectAction.deleteAll:
        final pageData = getContactPageData(context);
        final selectedTransactions = pageData.allContactTransactions
            .where((t) => transactionIds.contains(t.transactionId))
            .toList();
        
        final hasVerifiedNotCompleted = selectedTransactions.any((t) => t.isVerified && !t.isCompleted);
        
        if (hasVerifiedNotCompleted) {
          CustomToast.show(
            context,
            message: 'Cannot delete active verified transactions. Complete them first.',
            isSuccess: false,
          );
          return;
        }
        
        cubit.bulkDeleteTransactions(transactionIds);
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