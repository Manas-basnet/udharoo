import 'package:flutter/material.dart';

enum ConfirmationDialogType {
  verify,
  complete,
  reject,
  generic,
}

class ConfirmationDialogData {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color confirmButtonColor;
  final IconData? icon;
  final Color? iconColor;

  const ConfirmationDialogData({
    required this.title,
    required this.message,
    required this.confirmButtonText,
    this.cancelButtonText = 'Cancel',
    required this.confirmButtonColor,
    this.icon,
    this.iconColor,
  });

  static ConfirmationDialogData forTransactionAction(
    ConfirmationDialogType type,
    String contactName,
    double amount,
  ) {
    final formattedAmount = _formatAmount(amount);
    
    switch (type) {
      case ConfirmationDialogType.verify:
        return ConfirmationDialogData(
          title: 'Verify Transaction',
          message: 'Confirm that you have received Rs. $formattedAmount from $contactName?',
          confirmButtonText: 'Verify',
          confirmButtonColor: Colors.green,
          icon: Icons.verified_rounded,
          iconColor: Colors.green,
        );
      case ConfirmationDialogType.complete:
        return ConfirmationDialogData(
          title: 'Mark as Completed',
          message: 'Mark this Rs. $formattedAmount transaction with $contactName as completed?',
          confirmButtonText: 'Complete',
          confirmButtonColor: Colors.blue,
          icon: Icons.check_circle_rounded,
          iconColor: Colors.blue,
        );
      case ConfirmationDialogType.reject:
        return ConfirmationDialogData(
          title: 'Reject Transaction',
          message: 'Are you sure you want to reject this Rs. $formattedAmount transaction with $contactName?',
          confirmButtonText: 'Reject',
          confirmButtonColor: Colors.red,
          icon: Icons.cancel_rounded,
          iconColor: Colors.red,
        );
      case ConfirmationDialogType.generic:
        return ConfirmationDialogData(
          title: 'Confirm Action',
          message: 'Are you sure you want to proceed?',
          confirmButtonText: 'Confirm',
          confirmButtonColor: Colors.blue,
        );
    }
  }

  static String _formatAmount(double amount) {
    String amountStr = amount.toStringAsFixed(0);
    return amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final ConfirmationDialogData data;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.data,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool> show({
    required BuildContext context,
    required ConfirmationDialogData data,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          data: data,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          if (data.icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (data.iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                data.icon,
                color: data.iconColor ?? theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              data.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        data.message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            data.cancelButtonText,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: data.confirmButtonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            data.confirmButtonText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}