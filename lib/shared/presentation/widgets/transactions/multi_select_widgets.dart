import 'package:flutter/material.dart';
import 'package:udharoo/shared/mixins/multi_select_mixin.dart';

class MultiSelectAppBar extends StatelessWidget {
  final int selectedCount;
  final Color backgroundColor;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;
  final double horizontalPadding;

  const MultiSelectAppBar({
    super.key,
    required this.selectedCount,
    required this.backgroundColor,
    required this.onSelectAll,
    required this.onCancel,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        '$selectedCount selected',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSelectAll,
          icon: const Icon(
            Icons.select_all_rounded,
            color: Colors.white,
          ),
          tooltip: 'Select All',
        ),
        IconButton(
          onPressed: onCancel,
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
          ),
          tooltip: 'Cancel',
        ),
        SizedBox(width: horizontalPadding),
      ],
    );
  }
}

class MultiSelectBottomBar extends StatelessWidget {
  final MultiSelectAction? availableAction;
  final String Function(MultiSelectAction) getActionText;
  final IconData Function(MultiSelectAction) getActionIcon;
  final Color Function(MultiSelectAction) getActionColor;
  final Function(MultiSelectAction) onAction;

  const MultiSelectBottomBar({
    super.key,
    required this.availableAction,
    required this.getActionText,
    required this.getActionIcon,
    required this.getActionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (availableAction == null) {
      return const SizedBox.shrink();
    }

    final actionColor = getActionColor(availableAction!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onAction(availableAction!),
            icon: Icon(getActionIcon(availableAction!), size: 18),
            label: Text(getActionText(availableAction!)),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectableTransactionListItem extends StatelessWidget {
  final Widget child;
  final bool isMultiSelectMode;
  final bool isSelected;
  final Color selectionColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SelectableTransactionListItem({
    super.key,
    required this.child,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.selectionColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isMultiSelectMode
              ? Border.all(
                  color: isSelected
                      ? selectionColor
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                )
              : null,
        ),
        child: Stack(
          children: [
            child,
            if (isMultiSelectMode)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectionColor
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? selectionColor
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}