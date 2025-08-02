import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/services/smart_suggestions_service.dart';

class AmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? contactId;

  const AmountInputWidget({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.contactId,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  List<double> _smartAmounts = [];
  List<String> _descriptionSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSmartSuggestions();
    widget.controller.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _loadSmartSuggestions() {
    // Get transaction history from cubit
    final transactionState = context.read<TransactionCubit>().state;
    final recentAmounts = SmartSuggestionsService.getRecentAmounts(
      transactionState.transactions,
      limit: 3,
    );
    
    setState(() {
      _smartAmounts = SmartSuggestionsService.getAmountSuggestions(
        contactId: widget.contactId,
        history: transactionState.transactions,
        recentAmounts: recentAmounts,
      );
    });
  }

  void _onAmountChanged() {
    final amount = double.tryParse(widget.controller.text);
    if (amount != null) {
      setState(() {
        _descriptionSuggestions = SmartSuggestionsService.getDescriptionSuggestions(amount);
      });
    }
  }

  void _setAmount(double amount) {
    widget.controller.text = amount.toString();
    if (widget.onChanged != null) {
      widget.onChanged!(amount.toString());
    }
    setState(() {});
  }

  String _formatAmountChip(double amount) {
    if (amount >= 1000) {
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)}L';
      }
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
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
        
        // Smart amount suggestions
        if (_smartAmounts.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart suggestions',
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
            children: _smartAmounts.take(6).map((amount) => _AmountChip(
              amount: amount,
              displayText: _formatAmountChip(amount),
              onPressed: () => _setAmount(amount),
              isSelected: widget.controller.text == amount.toString(),
              isPrimary: true,
            )).toList(),
          ),
          
          const SizedBox(height: 20),
        ],
        
        // Common amounts
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Common amounts',
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
          children: [100, 500, 1000, 2000, 5000, 10000].map((amount) => _AmountChip(
            amount: amount.toDouble(),
            displayText: _formatAmountChip(amount.toDouble()),
            onPressed: () => _setAmount(amount.toDouble()),
            isSelected: widget.controller.text == amount.toString(),
            isPrimary: false,
          )).toList(),
        ),
        
        // Description suggestions based on amount
        if (_descriptionSuggestions.isNotEmpty && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Common for this amount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _descriptionSuggestions.take(4).map((description) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ).toList(),
          ),
        ],
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final double amount;
  final String displayText;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isPrimary;

  const _AmountChip({
    required this.amount,
    required this.displayText,
    required this.onPressed,
    required this.isSelected,
    required this.isPrimary,
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
                : isPrimary 
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : isPrimary
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPrimary) ...[
                Icon(
                  Icons.star,
                  size: 12,
                  color: isSelected 
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                displayText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? theme.colorScheme.onPrimary
                      : isPrimary
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}