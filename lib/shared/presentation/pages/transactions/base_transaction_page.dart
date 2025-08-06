import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';
import 'package:udharoo/shared/mixins/responsive_layout_mixin.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/multi_select_widgets.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/filter_sliver_delegate.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_list_sliver.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

abstract class BaseTransactionPage<T extends StatefulWidget> extends State<T> 
    with MultiSelectMixin<T>, ResponsiveLayoutMixin {

  String get pageTitle;
  List<Transaction> get allTransactions;
  List<Transaction> get filteredTransactions;
  bool get isLoading;
  String? get errorMessage;
  bool get hasTransactions;
  Color get primaryColor;
  Color get multiSelectColor;
  
  List<Widget> buildAppBarActions(BuildContext context, ThemeData theme, double horizontalPadding);
  List<Widget>? buildSummaryCards(BuildContext context, ThemeData theme);
  List<Widget> buildFilterChips(BuildContext context, ThemeData theme);
  Widget buildEmptyState(BuildContext context, ThemeData theme);
  
  void onRefresh();
  void handleMultiSelectAction(MultiSelectAction action);
  String? get detailRoute => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final horizontalPadding = getResponsiveHorizontalPadding(screenWidth);
    final expandedHeight = calculateExpandedHeight(screenHeight, topPadding);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (isMultiSelectMode)
                buildMultiSelectAppBar(theme, horizontalPadding)
              else
                buildSliverAppBar(theme, expandedHeight, horizontalPadding),
              
              if (!isMultiSelectMode && buildSummaryCards(context, theme) != null)
                buildSummarySection(context, theme),
              
              buildFilterSection(context, theme, horizontalPadding),
              
              buildTransactionsList(context, theme, horizontalPadding),
            ],
          ),
        ),
        bottomNavigationBar: isMultiSelectMode
            ? buildMultiSelectBottomBar(theme)
            : null,
      ),
    );
  }

  Widget buildMultiSelectAppBar(ThemeData theme, double horizontalPadding) {
    return MultiSelectAppBar(
      selectedCount: selectedCount,
      backgroundColor: multiSelectColor,
      onSelectAll: () => selectAllTransactions(filteredTransactions),
      onCancel: exitMultiSelectMode,
      horizontalPadding: horizontalPadding,
    );
  }

  Widget buildSliverAppBar(ThemeData theme, double expandedHeight, double horizontalPadding) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        pageTitle,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        ...buildAppBarActions(context, theme, horizontalPadding),
        SizedBox(width: horizontalPadding),
      ],
    );
  }

  Widget buildSummarySection(BuildContext context, ThemeData theme) {
    final summaryCards = buildSummaryCards(context, theme);
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

  Widget buildFilterSection(BuildContext context, ThemeData theme, double horizontalPadding) {
    return TransactionFilterSection(
      filterChips: buildFilterChips(context, theme),
      horizontalPadding: horizontalPadding,
    );
  }

  Widget buildTransactionsList(BuildContext context, ThemeData theme, double horizontalPadding) {
    return TransactionListSliver(
      transactions: filteredTransactions,
      isLoading: isLoading,
      errorMessage: hasTransactions ? null : errorMessage,
      emptyStateWidget: buildEmptyState(context, theme),
      isMultiSelectMode: isMultiSelectMode,
      selectedTransactionIds: selectedTransactionIds,
      selectionColor: primaryColor,
      onTransactionTap: toggleTransactionSelection,
      onTransactionLongPress: enterMultiSelectMode,
      onRetry: onRefresh,
      horizontalPadding: horizontalPadding,
      detailRoute: detailRoute,
    );
  }

  Widget buildMultiSelectBottomBar(ThemeData theme) {
    return MultiSelectBottomBar(
      availableAction: getAvailableAction(allTransactions),
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