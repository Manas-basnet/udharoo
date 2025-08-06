import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';
import 'package:udharoo/shared/mixins/responsive_layout_mixin.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/multi_select_widgets.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/filter_sliver_delegate.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_list_sliver.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

abstract class BaseContactTransactionPage<T extends StatefulWidget> extends State<T> 
    with MultiSelectMixin<T>, ResponsiveLayoutMixin {

  abstract final String contactUserId;
  
  Contact? _contact;
  Contact? get contact => _contact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContactAndTransactions();
    });
  }

  void _loadContactAndTransactions() {
    context.read<ContactCubit>().getContactByUserId(contactUserId).then((contact) {
      if (mounted) {
        setState(() {
          _contact = contact;
        });
        context.read<ContactTransactionsCubit>().loadContactTransactions(contactUserId);
      }
    });
  }

  String get pageTitle;
  List<Transaction> get allContactTransactions;
  List<Transaction> get filteredTransactions;
  bool get isLoading;
  String? get errorMessage;
  Color get primaryColor;
  Color get multiSelectColor;
  
  List<Widget> buildContactAppBarActions(BuildContext context, ThemeData theme);
  List<Widget>? buildContactSummaryCards(BuildContext context, ThemeData theme, List<Transaction> transactions);
  List<Widget> buildFilterChips(BuildContext context, ThemeData theme);
  Widget buildEmptyState(BuildContext context, ThemeData theme);
  Widget? buildHeaderIcon(ThemeData theme);
  
  void onRefresh();
  void handleMultiSelectAction(MultiSelectAction action);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final horizontalPadding = getResponsiveHorizontalPadding(screenWidth);
    final expandedHeight = calculateExpandedHeight(screenHeight, topPadding, hasExtendedHeader: true);

    if (_contact == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<ContactTransactionsCubit, ContactTransactionsState>(
          listener: (context, state) {
            if (state is ContactTransactionsError) {
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
          builder: (context, transactionState) {
            return RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (isMultiSelectMode)
                    buildMultiSelectAppBar(theme, horizontalPadding, transactionState)
                  else
                    buildContactSliverAppBar(theme, horizontalPadding, expandedHeight, transactionState),
                  
                  if (!isMultiSelectMode && transactionState is ContactTransactionsLoaded)
                    buildContactSummarySection(context, theme, transactionState.transactions),
                  
                  buildFilterSection(context, theme, horizontalPadding, transactionState),
                  
                  buildContactTransactionsList(context, theme, horizontalPadding, transactionState),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: isMultiSelectMode
            ? buildMultiSelectBottomBar(theme)
            : null,
      ),
    );
  }

  Widget buildMultiSelectAppBar(ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
    return MultiSelectAppBar(
      selectedCount: selectedCount,
      backgroundColor: multiSelectColor,
      onSelectAll: () {
        if (state is ContactTransactionsLoaded) {
          selectAllTransactions(filteredTransactions);
        }
      },
      onCancel: exitMultiSelectMode,
      horizontalPadding: horizontalPadding,
    );
  }

  Widget buildContactSliverAppBar(ThemeData theme, double horizontalPadding, double expandedHeight, ContactTransactionsState state) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
      actions: [
        ...buildContactAppBarActions(context, theme),
        SizedBox(width: horizontalPadding),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  buildHeaderIcon(theme) ?? Container(
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
                        _contact!.displayName.isNotEmpty
                            ? _contact!.displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pageTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubtitle(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (pageTitle.contains('Lent')) {
      return 'to ${_contact!.displayName}';
    } else if (pageTitle.contains('Borrowed')) {
      return 'from ${_contact!.displayName}';
    } else {
      return _contact!.phoneNumber;
    }
  }

  Widget buildContactSummarySection(BuildContext context, ThemeData theme, List<Transaction> transactions) {
    final summaryCards = buildContactSummaryCards(context, theme, transactions);
    if (summaryCards == null || summaryCards.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: summaryCards
              .expand((card) => [Expanded(child: card), const SizedBox(width: 8)])
              .take(summaryCards.length * 2 - 1)
              .toList(),
        ),
      ),
    );
  }

  Widget buildFilterSection(BuildContext context, ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
    return TransactionFilterSection(
      filterChips: buildFilterChips(context, theme),
      horizontalPadding: horizontalPadding,
    );
  }

  Widget buildContactTransactionsList(BuildContext context, ThemeData theme, double horizontalPadding, ContactTransactionsState state) {
    return TransactionListSliver(
      transactions: filteredTransactions,
      isLoading: state is ContactTransactionsLoading,
      errorMessage: state is ContactTransactionsError ? state.message : null,
      emptyStateWidget: buildEmptyState(context, theme),
      isMultiSelectMode: isMultiSelectMode,
      selectedTransactionIds: selectedTransactionIds,
      selectionColor: primaryColor,
      onTransactionTap: toggleTransactionSelection,
      onTransactionLongPress: enterMultiSelectMode,
      onRetry: onRefresh,
      horizontalPadding: horizontalPadding,
      detailRoute: Routes.contactTransactionsDetail,
    );
  }

  Widget buildMultiSelectBottomBar(ThemeData theme) {
    return MultiSelectBottomBar(
      availableAction: getAvailableAction(allContactTransactions),
      getActionText: getActionText,
      getActionIcon: getActionIcon,
      getActionColor: getActionColor,
      onAction: (action) {
        switch (action) {
          case MultiSelectAction.deleteAll:
            showDeleteConfirmationDialog(context, () {
              CustomToast.show(
                context,
                message: 'Deleting $selectedCount transactions...',
                isSuccess: true,
              );
              handleMultiSelectAction(action);
            });
            break;
          default:
            CustomToast.show(
              context,
              message: '${getActionText(action)}ing $selectedCount transactions...',
              isSuccess: true,
            );
            handleMultiSelectAction(action);
            exitMultiSelectMode();
            break;
        }
      },
    );
  }
}