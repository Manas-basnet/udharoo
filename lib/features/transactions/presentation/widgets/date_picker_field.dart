import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final String? hintText;
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;
  final bool enabled;
  final IconData? prefixIcon;

  const DatePickerField({
    super.key,
    required this.label,
    this.hintText,
    this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: errorText != null 
                ? Colors.red 
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled 
              ? theme.colorScheme.surface 
              : theme.colorScheme.surface.withOpacity(0.5),
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                color: enabled 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null 
                        ? _formatDate(selectedDate!)
                        : hintText ?? 'Tap to select date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null 
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedDate != null && enabled)
              IconButton(
                onPressed: () => onDateSelected(null),
                icon: const Icon(Icons.clear),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            if (enabled)
              Icon(
                Icons.calendar_today,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: this.selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selectedDate != null) {
      onDateSelected(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}