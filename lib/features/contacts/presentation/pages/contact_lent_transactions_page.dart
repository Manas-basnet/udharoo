import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/presentation/pages/transactions/base_contact_transaction_page.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_action_button.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_filter_chip.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_summary_card.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum ContactLentFilter { 
  all, 
  needsResponse,
  active, 
  completed,
}

class ContactLentTransactionsPage extends StatefulWidget {
  final String contactUserId;

  const ContactLentTransactionsPage({
    super.key,
    required this.contactUserId,
  });

  @override
  State<ContactLentTransactionsPage> createState() => _ContactLentTransactionsPageState();
}

class _ContactLentTransactionsPageState extends BaseContactTransactionPage<ContactLentTransactionsPage> {
  ContactLentFilter _selectedFilter = ContactLentFilter.all;

  @override
  String get contactUserId => widget.contactUserId;

  @override
  String get pageTitle => 'Money I Lent';

  @override
  Color get primaryColor => Colors.green;

  @override
  Color get multiSelectColor => Colors.green.withValues(alpha: 0.9);

  @override
  ContactTransactionPageData getContactPageData(BuildContext context, ContactTransactionsState state) {
    final allTransactions = state is ContactTransactionsLoaded 
        ? state.transactions.where((t) => t.isLent).toList()
        : <Transaction>[];
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    
    return ContactTransactionPageData(
      allContactTransactions: allTransactions,
      filteredTransactions: filteredTransactions,
      isLoading: state is ContactTransactionsLoading,
      errorMessage: state is ContactTransactionsError ? state.message : null,
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> lentTransactions) {
    switch (_selectedFilter) {
      case ContactLentFilter.all:
        return lentTransactions
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactLentFilter.needsResponse:
        return lentTransactions.where((t) => t.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactLentFilter.active:
        return lentTransactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactLentFilter.completed:
        return lentTransactions.where((t) => t.isCompleted).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  List<Widget> buildContactAppBarActions(BuildContext context, ThemeData theme) {
    return [
      SmallTransactionActionButton(
        icon: Icons.trending_down_rounded,
        tooltip: 'Borrowed',
        type: ActionButtonType.borrowed,
        onPressed: () => context.pushReplacement(Routes.contactBorrowedTransactionsF(contactUserId)),
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
    final lentTransactions = transactions.where((t) => t.isLent).toList();
    
    final activeLentAmount = lentTransactions
        .where((t) => t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final awaitingResponseAmount = lentTransactions
        .where((t) => t.isPending)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final completedAmount = lentTransactions
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
            _selectedFilter = ContactLentFilter.active;
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
            _selectedFilter = ContactLentFilter.needsResponse;
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
            _selectedFilter = ContactLentFilter.completed;
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
        isSelected: _selectedFilter == ContactLentFilter.all,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = ContactLentFilter.all),
      ),
      TransactionFilterChip(
        label: 'Awaiting Response',
        isSelected: _selectedFilter == ContactLentFilter.needsResponse,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = ContactLentFilter.needsResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == ContactLentFilter.active,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = ContactLentFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == ContactLentFilter.completed,
        colorType: FilterChipColor.green,
        onTap: () => setState(() => _selectedFilter = ContactLentFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case ContactLentFilter.all:
        message = 'No lending records';
        subtitle = 'Money you lend to ${contact!.displayName} will appear here';
        break;
      case ContactLentFilter.needsResponse:
        message = 'No transactions awaiting response';
        subtitle = 'All lending to ${contact!.displayName} has been responded to';
        break;
      case ContactLentFilter.active:
        message = 'No active lending';
        subtitle = 'Active lending to ${contact!.displayName} will appear here';
        break;
      case ContactLentFilter.completed:
        message = 'No completed lending';
        subtitle = 'Money received back from ${contact!.displayName} will appear here';
        break;
    }

    return TransactionEmptyState(
      message: message,
      subtitle: subtitle,
      icon: Icons.trending_up_rounded,
    );
  }

  @override
  Widget? buildHeaderIcon(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.trending_up_rounded,
        color: Colors.green,
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
    switch (action) {
      case MultiSelectAction.completeAll:
        // ignore: unused_local_variable
        for (final transactionId in selectedTransactionIds) {
          // TODO:Handle completing all selected transactions
        }
        break;
      case MultiSelectAction.deleteAll:
        break;
      case MultiSelectAction.verifyAll:
        break;
    }
  }
}