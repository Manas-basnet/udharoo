import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AmountInputWidget({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  final List<int> _quickAmounts = [1000, 5000, 10000, 25000, 50000];

  void _setQuickAmount(int amount) {
    widget.controller.text = amount.toString();
    if (widget.onChanged != null) {
      widget.onChanged!(amount.toString());
    }
  }

  String _formatQuickAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main amount input with large display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Rs.',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Quick amount buttons
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Quick amounts',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) => _QuickAmountChip(
            amount: amount,
            displayText: _formatQuickAmount(amount),
            onPressed: () => _setQuickAmount(amount),
            isSelected: widget.controller.text == amount.toString(),
          )).toList(),
        ),
      ],
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final int amount;
  final String displayText;
  final VoidCallback onPressed;
  final bool isSelected;

  const _QuickAmountChip({
    required this.amount,
    required this.displayText,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            displayText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}