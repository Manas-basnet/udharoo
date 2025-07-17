import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionFormScreen extends StatefulWidget {
  final QrTransactionData? qrData;
  final TransactionType? initialType;

  const TransactionFormScreen({
    super.key,
    this.qrData,
    this.initialType,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _userNameController = TextEditingController();
  final _userPhoneController = TextEditingController();

  TransactionType _selectedType = TransactionType.lend;
  DateTime? _selectedDueDate;
  bool _requiresVerification = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.qrData != null) {
      final qrData = widget.qrData!;
      _userNameController.text = qrData.userName;
      _userPhoneController.text = qrData.userPhone ?? '';
      // Don't pre-fill amount, description, or due date - let user enter them
      _requiresVerification = true; // Default to requiring verification
    }

    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.qrData != null 
              ? 'Complete Transaction' 
              : 'New Transaction',
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: BlocListener<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state is TransactionCreated) {
            CustomToast.show(
              context,
              message: 'Transaction created successfully!',
              isSuccess: true,
            );
            Navigator.of(context).pop();
          } else if (state is TransactionError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.qrData == null) ...[
                          _buildTransactionTypeSelector(),
                          const SizedBox(height: 24),
                        ],
                        
                        if (widget.qrData == null) ...[
                          _buildUserInfoSection(),
                          const SizedBox(height: 24),
                        ],
                        
                        _buildAmountSection(),
                        const SizedBox(height: 24),
                        
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),
                        
                        _buildDueDateSection(),
                        const SizedBox(height: 24),
                        
                        _buildVerificationSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(20),
                child: BlocBuilder<TransactionCubit, TransactionState>(
                  builder: (context, state) {
                    return SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state is TransactionCreating
                            ? null
                            : _submitForm,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is TransactionCreating
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                'Create Transaction',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: TransactionType.lend,
                icon: Icons.trending_up,
                title: 'Lend Money',
                subtitle: 'You are lending',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: TransactionType.borrow,
                icon: Icons.trending_down,
                title: 'Borrow Money',
                subtitle: 'You are borrowing',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required TransactionType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1) 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? color 
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Person Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _userNameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter person\'s name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _userPhoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter amount',
            prefixIcon: const Icon(Icons.currency_rupee),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Amount is required';
            }
            final amount = double.tryParse(value!);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'What is this transaction for?',
            prefixIcon: const Icon(Icons.description_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDueDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDueDate != null
                        ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                        : 'Select due date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedDueDate != null
                          ? null
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                if (_selectedDueDate != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedDueDate = null),
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSection() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.verified_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requires Verification',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Other person will need to accept this transaction',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _requiresVerification,
            onChanged: (value) => setState(() => _requiresVerification = value),
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      CustomToast.show(
        context,
        message: 'Please login to create transactions',
        isSuccess: false,
      );
      return;
    }

    final currentUser = authState.user;
    final amount = double.parse(_amountController.text);

    String fromUserId, toUserId;
    String? fromUserName, toUserName, fromUserPhone, toUserPhone;

    if (widget.qrData != null) {
      final qrData = widget.qrData!;
      if (_selectedType == TransactionType.lend) {
        fromUserId = currentUser.uid;
        toUserId = qrData.userId;
        fromUserName = currentUser.displayName;
        toUserName = qrData.userName;
        fromUserPhone = currentUser.phoneNumber;
        toUserPhone = qrData.userPhone;
      } else {
        fromUserId = qrData.userId;
        toUserId = currentUser.uid;
        fromUserName = qrData.userName;
        toUserName = currentUser.displayName;
        fromUserPhone = qrData.userPhone;
        toUserPhone = currentUser.phoneNumber;
      }
    } else {
      if (_selectedType == TransactionType.lend) {
        fromUserId = currentUser.uid;
        toUserId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
        fromUserName = currentUser.displayName;
        toUserName = _userNameController.text.trim();
        fromUserPhone = currentUser.phoneNumber;
        toUserPhone = _userPhoneController.text.trim().isNotEmpty 
            ? _userPhoneController.text.trim() 
            : null;
      } else {
        fromUserId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
        toUserId = currentUser.uid;
        fromUserName = _userNameController.text.trim();
        toUserName = currentUser.displayName;
        fromUserPhone = _userPhoneController.text.trim().isNotEmpty 
            ? _userPhoneController.text.trim() 
            : null;
        toUserPhone = currentUser.phoneNumber;
      }
    }

    context.read<TransactionCubit>().createTransaction(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      type: _selectedType,
      description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      dueDate: _selectedDueDate,
      requiresVerification: _requiresVerification,
      fromUserName: fromUserName,
      toUserName: toUserName,
      fromUserPhone: fromUserPhone,
      toUserPhone: toUserPhone,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _userNameController.dispose();
    _userPhoneController.dispose();
    super.dispose();
  }
}