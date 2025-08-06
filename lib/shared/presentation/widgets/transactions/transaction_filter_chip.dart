import 'package:flutter/material.dart';

enum FilterChipColor {
  primary,
  green,
  orange,
  red,
}

class TransactionFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final FilterChipColor colorType;
  final int? badgeCount;

  const TransactionFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.colorType = FilterChipColor.primary,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = _getSelectedColor(theme);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              selectedColor,
              selectedColor.withValues(alpha: 0.8),
            ],
          ) : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? selectedColor
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount != null && badgeCount! > 0) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ) : const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    badgeCount! > 99 ? '99+' : badgeCount.toString(),
                    style: TextStyle(
                      color: isSelected ? selectedColor : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSelectedColor(ThemeData theme) {
    switch (colorType) {
      case FilterChipColor.primary:
        return theme.colorScheme.primary;
      case FilterChipColor.green:
        return Colors.green;
      case FilterChipColor.orange:
        return Colors.orange;
      case FilterChipColor.red:
        return Colors.red;
    }
  }
}