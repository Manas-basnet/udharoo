import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';

enum MultiSelectAction {
  verifyAll,
  completeAll,
  deleteAll,
}

mixin MultiSelectMixin<T extends StatefulWidget> on State<T> {
  bool _isMultiSelectMode = false;
  Set<String> _selectedTransactionIds = {};

  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedTransactionIds => _selectedTransactionIds;
  int get selectedCount => _selectedTransactionIds.length;

  void enterMultiSelectMode(String transactionId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTransactionIds = {transactionId};
    });
  }

  void exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTransactionIds.clear();
    });
  }

  void toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void selectAllTransactions(List<Transaction> transactions) {
    setState(() {
      _selectedTransactionIds = Set.from(
        transactions.map((t) => t.transactionId)
      );
    });
  }

  MultiSelectAction? getAvailableAction(List<Transaction> allTransactions) {
    if (_selectedTransactionIds.isEmpty) return null;
    
    final selectedTransactions = allTransactions
        .where((t) => _selectedTransactionIds.contains(t.transactionId))
        .toList();
    
    if (selectedTransactions.isEmpty) return null;

    final allNeedVerification = selectedTransactions.every((t) => 
      t.isPending && t.isBorrowed
    );
    
    final allNeedCompletion = selectedTransactions.every((t) => 
      t.isVerified && t.isLent
    );

    if (allNeedVerification) {
      return MultiSelectAction.verifyAll;
    } else if (allNeedCompletion) {
      return MultiSelectAction.completeAll;
    } else {
      return MultiSelectAction.deleteAll;
    }
  }

  String getActionText(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return 'Verify All';
      case MultiSelectAction.completeAll:
        return 'Mark All Complete';
      case MultiSelectAction.deleteAll:
        return 'Delete All';
    }
  }

  IconData getActionIcon(MultiSelectAction action) {
    switch (action) {
      case MultiSelectAction.verifyAll:
        return Icons.verified_rounded;
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

  void showDeleteConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transactions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete $selectedCount selected transactions? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
              exitMultiSelectMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}