import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/shared/presentation/bloc/multi_select_mode/multi_select_mode_cubit.dart';

enum MultiSelectAction {
  verifyAll,
  completeAll,
  deleteAll,
}

mixin MultiSelectMixin<T extends StatefulWidget> on State<T> {
  Set<String> _selectedTransactionIds = {};
  bool _isMultiSelectMode = false;

  Set<String> get selectedTransactionIds => _selectedTransactionIds;
  bool get isMultiSelectMode => _isMultiSelectMode;
  int get selectedCount => _selectedTransactionIds.length;

  void enterMultiSelectMode(String? initialTransactionId) {
    setState(() {
      _isMultiSelectMode = true;
      if (initialTransactionId != null) {
        _selectedTransactionIds.add(initialTransactionId);
      }
    });
    context.read<MultiSelectModeCubit>().enterMultiSelectMode();
  }

  void exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTransactionIds.clear();
    });
    context.read<MultiSelectModeCubit>().exitMultiSelectMode();
  }

  void toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isMultiSelectMode = false;
          context.read<MultiSelectModeCubit>().exitMultiSelectMode();
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void selectAllTransactions(List<Transaction> transactions) {
    setState(() {
      _selectedTransactionIds = transactions.map((t) => t.transactionId).toSet();
    });
  }

  MultiSelectAction? getAvailableAction(List<Transaction> allTransactions) {
    if (_selectedTransactionIds.isEmpty) return null;

    final selectedTransactions = allTransactions
        .where((t) => _selectedTransactionIds.contains(t.transactionId))
        .toList();

    final allPending = selectedTransactions.every((t) => t.isPending);
    final allVerifiedLent = selectedTransactions.every((t) => t.isVerified && t.isLent);

    if (allPending) {
      return MultiSelectAction.verifyAll;
    } else if (allVerifiedLent) {
      return MultiSelectAction.completeAll;
    } else {
      return MultiSelectAction.deleteAll;
    }
  }

  String getActionText(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return 'Confirm';
      case MultiSelectAction.completeAll:
        return 'Mark as Received';
      case MultiSelectAction.deleteAll:
        return 'Delete';
    }
  }

  IconData getActionIcon(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return Icons.check_rounded;
      case MultiSelectAction.completeAll:
        return Icons.check_circle_rounded;
      case MultiSelectAction.deleteAll:
        return Icons.delete_rounded;
    }
  }

  Color getActionColor(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return Colors.green;
      case MultiSelectAction.completeAll:
        return Colors.blue;
      case MultiSelectAction.deleteAll:
        return Colors.red;
    }
  }

  Future<void> showDeleteConfirmationDialog(BuildContext context, VoidCallback onConfirm) async {
    final theme = Theme.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transactions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete $selectedCount transaction${selectedCount == 1 ? '' : 's'}?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
      exitMultiSelectMode();
    }
  }

  @override
  void dispose() {
    if (_isMultiSelectMode) {
      context.read<MultiSelectModeCubit>().exitMultiSelectMode();
    }
    super.dispose();
  }
}