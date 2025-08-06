import 'package:flutter/material.dart';

enum ActionButtonType {
  search,
  lent,
  borrowed,
  rejected,
  addTransaction,
  allTransactions,
  primary,
}

class TransactionActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ActionButtonType type;
  final bool isLoading;

  const TransactionActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.type = ActionButtonType.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(theme);
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: onPressed == null 
                  ? backgroundColor.withValues(alpha: 0.5)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (type) {
      case ActionButtonType.search:
        return theme.colorScheme.primary.withValues(alpha: 0.9);
      case ActionButtonType.lent:
        return Colors.green.withValues(alpha: 0.9);
      case ActionButtonType.borrowed:
        return Colors.orange.withValues(alpha: 0.9);
      case ActionButtonType.rejected:
        return Colors.red.withValues(alpha: 0.9);
      case ActionButtonType.addTransaction:
        return theme.colorScheme.primary;
      case ActionButtonType.allTransactions:
        return theme.colorScheme.primary;
      case ActionButtonType.primary:
        return theme.colorScheme.primary;
    }
  }
}

class SmallTransactionActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ActionButtonType type;

  const SmallTransactionActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.type = ActionButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(theme);
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (type) {
      case ActionButtonType.lent:
        return Colors.green;
      case ActionButtonType.borrowed:
        return Colors.orange;
      case ActionButtonType.allTransactions:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }
}