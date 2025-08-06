import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/shared/presentation/pages/transactions/base_contact_transaction_page.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_action_button.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_filter_chip.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_summary_card.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

enum ContactTransactionFilter { all, needsResponse, active, completed }

class ContactTransactionsPage extends StatefulWidget {
  final String contactUserId;

  const ContactTransactionsPage({super.key, required this.contactUserId});

  @override
  State<ContactTransactionsPage> createState() =>
      _ContactTransactionsPageState();
}

class _ContactTransactionsPageState extends BaseContactTransactionPage<ContactTransactionsPage> {
  ContactTransactionFilter _selectedFilter = ContactTransactionFilter.all;

  @override
  String get contactUserId => widget.contactUserId;

  @override
  String get pageTitle => contact?.displayName ?? 'Contact Transactions';

  @override
  Color get primaryColor => Theme.of(context).colorScheme.primary;

  @override
  Color get multiSelectColor => Theme.of(context).colorScheme.primary.withValues(alpha: 0.9);

  @override
  ContactTransactionPageData getContactPageData(BuildContext context) {
    final state = context.watch<ContactTransactionsCubit>().state;
    final allTransactions = state is ContactTransactionsLoaded ? state.transactions : <Transaction>[];
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    
    return ContactTransactionPageData(
      allContactTransactions: allTransactions,
      filteredTransactions: filteredTransactions,
      isLoading: state is ContactTransactionsLoading,
      errorMessage: state is ContactTransactionsError ? state.message : null,
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    switch (_selectedFilter) {
      case ContactTransactionFilter.all:
        return transactions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactTransactionFilter.needsResponse:
        return transactions.where((t) => t.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactTransactionFilter.active:
        return transactions.where((t) => t.isVerified).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContactTransactionFilter.completed:
        return transactions.where((t) => t.isCompleted).toList()
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
        onPressed: () => context.push(
          Routes.contactLentTransactionsF(contactUserId),
        ),
      ),
      const SizedBox(width: 8),
      SmallTransactionActionButton(
        icon: Icons.trending_down_rounded,
        tooltip: 'Borrowed',
        type: ActionButtonType.borrowed,
        onPressed: () => context.push(
          Routes.contactBorrowedTransactionsF(contactUserId),
        ),
      ),
      const SizedBox(width: 8),
      SmallTransactionActionButton(
        icon: Icons.add_rounded,
        tooltip: 'New Transaction',
        type: ActionButtonType.addTransaction,
        onPressed: () => _createNewTransaction(context),
      ),
    ];
  }

  @override
  List<Widget>? buildContactSummaryCards(BuildContext context, ThemeData theme, List<Transaction> transactions) {
    if (transactions.isEmpty) return null;

    final activeTotalLent = _calculateActiveTotalLent(transactions);
    final activeTotalBorrowed = _calculateActiveTotalBorrowed(transactions);
    final netBalance = activeTotalLent - activeTotalBorrowed;

    return [
      TransactionSummaryCard(
        title: 'They owe you',
        amount: activeTotalLent,
        color: Colors.green,
        icon: Icons.trending_up_rounded,
        onTap: () => context.push(
          Routes.contactLentTransactionsF(contactUserId),
        ),
      ),
      TransactionSummaryCard(
        title: 'You owe them',
        amount: activeTotalBorrowed,
        color: Colors.orange,
        icon: Icons.trending_down_rounded,
        onTap: () => context.push(
          Routes.contactBorrowedTransactionsF(contactUserId),
        ),
      ),
      TransactionSummaryCard(
        title: TransactionDisplayHelper.getBalanceLabel(netBalance),
        amount: netBalance.abs(),
        color: netBalance >= 0 ? Colors.green : Colors.orange,
        icon: netBalance >= 0
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
        isNet: true,
        netPrefix: netBalance >= 0 ? '+' : '-',
        onTap: () {
          setState(() {
            _selectedFilter = ContactTransactionFilter.active;
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
        isSelected: _selectedFilter == ContactTransactionFilter.all,
        onTap: () => setState(() => _selectedFilter = ContactTransactionFilter.all),
      ),
      TransactionFilterChip(
        label: 'Needs Response',
        isSelected: _selectedFilter == ContactTransactionFilter.needsResponse,
        onTap: () => setState(() => _selectedFilter = ContactTransactionFilter.needsResponse),
      ),
      TransactionFilterChip(
        label: 'Active',
        isSelected: _selectedFilter == ContactTransactionFilter.active,
        onTap: () => setState(() => _selectedFilter = ContactTransactionFilter.active),
      ),
      TransactionFilterChip(
        label: 'Completed',
        isSelected: _selectedFilter == ContactTransactionFilter.completed,
        onTap: () => setState(() => _selectedFilter = ContactTransactionFilter.completed),
      ),
    ];
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case ContactTransactionFilter.all:
        message = 'No Transactions Yet';
        subtitle = 'Start your first transaction with ${contact?.displayName}';
        icon = Icons.receipt_long_outlined;
        break;
      case ContactTransactionFilter.needsResponse:
        message = 'No transactions need response';
        subtitle = 'All transactions with ${contact?.displayName} have been responded to';
        icon = Icons.check_circle_outline;
        break;
      case ContactTransactionFilter.active:
        message = 'No Active Transactions';
        subtitle = 'Active transactions with ${contact?.displayName} will appear here';
        icon = Icons.verified_outlined;
        break;
      case ContactTransactionFilter.completed:
        message = 'No Completed Transactions';
        subtitle = 'Completed transactions with ${contact?.displayName} will appear here';
        icon = Icons.done_all_rounded;
        break;
    }

    return TransactionEmptyState(
      message: message,
      subtitle: subtitle,
      icon: icon,
      actionButton: ElevatedButton.icon(
        onPressed: () => _createNewTransaction(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Transaction'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget? buildHeaderIcon(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          contact!.displayName.isNotEmpty
              ? contact!.displayName[0].toUpperCase()
              : '?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      case MultiSelectAction.verifyAll:
        break;
      case MultiSelectAction.completeAll:
        break;
      case MultiSelectAction.deleteAll:
        break;
    }
  }

  double _calculateActiveTotalLent(List<Transaction> transactions) {
    return transactions
        .where((t) => t.isLent && t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateActiveTotalBorrowed(List<Transaction> transactions) {
    return transactions
        .where((t) => t.isBorrowed && t.isVerified)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _createNewTransaction(BuildContext context) {
    context.go(Routes.transactionForm, extra: TransactionFormExtra(prefilledContact: contact));
  }
}