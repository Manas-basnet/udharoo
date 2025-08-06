import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/transaction_state_widgets.dart';
import 'package:udharoo/shared/presentation/widgets/transactions/multi_select_widgets.dart';

class TransactionListSliver extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? errorMessage;
  final Widget emptyStateWidget;
  final bool isMultiSelectMode;
  final Set<String> selectedTransactionIds;
  final Color selectionColor;
  final Function(String) onTransactionTap;
  final Function(String) onTransactionLongPress;
  final VoidCallback? onRetry;
  final double horizontalPadding;
  final String? detailRoute;

  const TransactionListSliver({
    super.key,
    required this.transactions,
    required this.isLoading,
    this.errorMessage,
    required this.emptyStateWidget,
    required this.isMultiSelectMode,
    required this.selectedTransactionIds,
    required this.selectionColor,
    required this.onTransactionTap,
    required this.onTransactionLongPress,
    this.onRetry,
    required this.horizontalPadding,
    this.detailRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliverFillRemaining(
        child: TransactionLoadingState(),
      );
    }

    if (errorMessage != null && transactions.isEmpty) {
      return SliverFillRemaining(
        child: TransactionErrorState(
          message: errorMessage!,
          onRetry: onRetry,
        ),
      );
    }

    if (transactions.isEmpty) {
      return SliverFillRemaining(
        child: emptyStateWidget,
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = transactions[index];
            final isSelected = selectedTransactionIds.contains(transaction.transactionId);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SelectableTransactionListItem(
                isMultiSelectMode: isMultiSelectMode,
                isSelected: isSelected,
                selectionColor: selectionColor,
                onTap: () {
                  if (isMultiSelectMode) {
                    onTransactionTap(transaction.transactionId);
                  } else {
                    _navigateToDetail(context, transaction);
                  }
                },
                onLongPress: () {
                  if (!isMultiSelectMode) {
                    onTransactionLongPress(transaction.transactionId);
                  }
                },
                child: TransactionListItem(transaction: transaction),
              ),
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Transaction transaction) {
    final route = detailRoute ?? Routes.transactionDetail;
    context.push(route, extra: transaction);
  }
}