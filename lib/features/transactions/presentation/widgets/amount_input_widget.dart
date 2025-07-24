import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInputWidget extends StatefulWidget {
  final double? initialAmount;
  final Function(double?) onAmountChanged;
  final String? errorText;
  final bool enabled;

  const AmountInputWidget({
    super.key,
    this.initialAmount,
    required this.onAmountChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _controller.text = widget.initialAmount!.toStringAsFixed(2);
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.replaceAll(',', '');
    if (text.isEmpty) {
      widget.onAmountChanged(null);
      return;
    }

    final amount = double.tryParse(text);
    widget.onAmountChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount *',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null 
                  ? Colors.red 
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              _CurrencyInputFormatter(),
            ],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  'NPR',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              hintText: '0.00',
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              errorText: widget.errorText,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            _QuickAmountButton(
              amount: 1000,
              onTap: _setQuickAmount,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _QuickAmountButton(
              amount: 5000,
              onTap: _setQuickAmount,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _QuickAmountButton(
              amount: 10000,
              onTap: _setQuickAmount,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _QuickAmountButton(
              amount: 25000,
              onTap: _setQuickAmount,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  void _setQuickAmount(double amount) {
    _controller.text = amount.toStringAsFixed(2);
    widget.onAmountChanged(amount);
    _focusNode.unfocus();
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final Function(double) onTap;
  final ThemeData theme;

  const _QuickAmountButton({
    required this.amount,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(amount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatAmount(amount),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    final parts = numericOnly.split('.');
    if (parts.length > 2) {
      return oldValue;
    }

    String formatted = parts[0];
    
    if (formatted.length > 3) {
      final reversed = formatted.split('').reversed.join();
      final chunks = <String>[];
      
      for (int i = 0; i < reversed.length; i += 3) {
        final end = i + 3;
        chunks.add(reversed.substring(i, end > reversed.length ? reversed.length : end));
      }
      
      formatted = chunks.join(',').split('').reversed.join();
    }

    if (parts.length == 2) {
      formatted += '.${parts[1]}';
    }

    final newSelection = TextSelection.collapsed(
      offset: formatted.length,
    );

    return TextEditingValue(
      text: formatted,
      selection: newSelection,
    );
  }
}