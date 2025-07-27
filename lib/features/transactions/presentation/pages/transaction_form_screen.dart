import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/amount_input_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/contact_selector_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_type_selector.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionType? _selectedType;
  AuthUser? _selectedUser;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onUserSelected(AuthUser? user) {
    setState(() {
      _selectedUser = user;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedType == null) {
        CustomToast.show(
          context,
          message: 'Please select transaction type',
          isSuccess: false,
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        CustomToast.show(
          context,
          message: 'Please enter a valid amount',
          isSuccess: false,
        );
        return;
      }

      final otherPartyUid = _selectedUser?.uid ?? 'manual_${_phoneController.text}';
      final otherPartyName = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      if (otherPartyName.isEmpty) {
        CustomToast.show(
          context,
          message: 'Please enter contact name',
          isSuccess: false,
        );
        return;
      }

      context.read<TransactionFormCubit>().createTransaction(
        amount: amount,
        otherPartyUid: otherPartyUid,
        otherPartyName: otherPartyName,
        description: description.isEmpty ? 'Transaction' : description,
        type: _selectedType!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listener: (context, state) {
        switch (state) {
          case TransactionFormSuccess():
            CustomToast.show(
              context,
              message: 'Transaction created successfully',
              isSuccess: true,
            );
            context.pop();
            break;
          case TransactionFormError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
            break;
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('New Transaction'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                
                // Step 1: Transaction Type
                _buildStepHeader('1', 'Choose Type', true),
                const SizedBox(height: 16),
                TransactionTypeSelector(
                  selectedType: _selectedType,
                  onTypeChanged: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Step 2: Amount
                _buildStepHeader('2', 'Enter Amount', _selectedType != null),
                const SizedBox(height: 16),
                AmountInputWidget(
                  controller: _amountController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (amount > 10000000) {
                      return 'Amount cannot exceed Rs. 1,00,00,000';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Step 3: Contact
                _buildStepHeader('3', 'Select Contact', _amountController.text.isNotEmpty),
                const SizedBox(height: 16),
                ContactSelectorWidget(
                  phoneController: _phoneController,
                  nameController: _nameController,
                  onUserSelected: _onUserSelected,
                  phoneValidator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Phone number is required';
                    }
                    if (value!.length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                  nameValidator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Name is required';
                    }
                    if (value!.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Step 4: Description
                _buildStepHeader('4', 'Add Description', _nameController.text.isNotEmpty),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'What was this for? (Optional)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

                const SizedBox(height: 40),

                // Submit Button
                BlocBuilder<TransactionFormCubit, TransactionFormState>(
                  builder: (context, state) {
                    final isLoading = state is TransactionFormLoading;

                    return SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: isLoading ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                'Create Transaction',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String stepNumber, String title, bool isActive) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isActive 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive 
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}