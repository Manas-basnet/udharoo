import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_type.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/amount_input_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/contact_selector_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_type_selector.dart';
import 'package:udharoo/features/transactions/presentation/widgets/date_picker_field.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;
  final String? scannedContactPhone;
  final String? scannedContactName;
  final String? scannedContactEmail;
  final bool? scannedVerificationRequired;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.scannedContactPhone,
    this.scannedContactName,
    this.scannedContactEmail,
    this.scannedVerificationRequired,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.lending;
  double? _amount;
  String _contactPhone = '';
  String _contactName = '';
  String? _contactEmail;
  DateTime? _dueDate;
  bool _verificationRequired = false;
  
  List<TransactionContact> _recentContacts = [];
  
  String? _amountError;
  String? _phoneError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadRecentContacts();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _selectedType = transaction.type;
      _amount = transaction.amount;
      _contactPhone = transaction.contactPhone;
      _contactName = transaction.contactName;
      _contactEmail = transaction.contactEmail;
      _dueDate = transaction.dueDate;
      _verificationRequired = transaction.verificationRequired;
      _descriptionController.text = transaction.description ?? '';
    } else if (widget.scannedContactPhone != null) {
      _contactPhone = widget.scannedContactPhone!;
      _contactName = widget.scannedContactName ?? '';
      _contactEmail = widget.scannedContactEmail;
      _verificationRequired = widget.scannedVerificationRequired ?? false;
    }
  }

  void _loadRecentContacts() {
    context.read<TransactionFormCubit>().loadTransactionContacts();
  }

  bool _validateForm() {
    bool isValid = true;
    
    setState(() {
      _amountError = null;
      _phoneError = null;
      _nameError = null;
    });

    if (_amount == null || _amount! <= 0) {
      setState(() {
        _amountError = 'Please enter a valid amount';
      });
      isValid = false;
    }

    if (_contactPhone.isEmpty) {
      setState(() {
        _phoneError = 'Phone number is required';
      });
      isValid = false;
    } else if (_contactPhone.length < 7) {
      setState(() {
        _phoneError = 'Please enter a valid phone number';
      });
      isValid = false;
    }

    if (_contactName.isEmpty) {
      setState(() {
        _nameError = 'Contact name is required';
      });
      isValid = false;
    } else if (_contactName.length < 2) {
      setState(() {
        _nameError = 'Name must be at least 2 characters';
      });
      isValid = false;
    }

    if (_dueDate != null && _dueDate!.isBefore(DateTime.now())) {
      CustomToast.show(
        context,
        message: 'Due date cannot be in the past',
        isSuccess: false,
      );
      isValid = false;
    }

    return isValid;
  }

  void _handleSubmit() {
    if (!_validateForm()) return;

    final authState = context.read<AuthSessionCubit>().state;
    if (authState is! AuthSessionAuthenticated) {
      CustomToast.show(
        context,
        message: 'You must be logged in to create transactions',
        isSuccess: false,
      );
      return;
    }

    final transaction = Transaction(
      id: widget.transaction?.id ?? '',
      type: _selectedType,
      amount: _amount!,
      contactPhone: _contactPhone,
      contactName: _contactName,
      contactEmail: _contactEmail?.isEmpty == true ? null : _contactEmail,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      dueDate: _dueDate,
      verificationRequired: _verificationRequired,
      status: TransactionStatus.pending,
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: authState.user.uid,
    );

    if (widget.transaction != null) {
      context.read<TransactionFormCubit>().updateTransaction(transaction);
    } else {
      context.read<TransactionFormCubit>().createTransaction(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transaction != null;
    
    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listener: (context, state) {
        switch (state) {
          case TransactionFormCreated():
            CustomToast.show(
              context,
              message: 'Transaction created successfully',
              isSuccess: true,
            );
            context.pop(state.transaction);
          case TransactionFormUpdated():
            CustomToast.show(
              context,
              message: 'Transaction updated successfully',
              isSuccess: true,
            );
            context.pop(state.transaction);
          case TransactionFormContactsLoaded():
            setState(() {
              _recentContacts = state.contacts;
            });
          case TransactionFormError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            BlocBuilder<TransactionFormCubit, TransactionFormState>(
              builder: (context, state) {
                final isLoading = state is TransactionFormLoading;
                
                return TextButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  child: Text(
                    isEditing ? 'Update' : 'Create',
                    style: TextStyle(
                      color: isLoading 
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Type',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                TransactionTypeSelector(
                  selectedType: _selectedType,
                  onTypeChanged: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                AmountInputWidget(
                  initialAmount: _amount,
                  onAmountChanged: (amount) {
                    setState(() {
                      _amount = amount;
                      _amountError = null;
                    });
                  },
                  errorText: _amountError,
                ),
                
                const SizedBox(height: 24),
                
                ContactSelectorWidget(
                  initialPhone: _contactPhone,
                  initialName: _contactName,
                  initialEmail: _contactEmail,
                  recentContacts: _recentContacts,
                  onContactSelected: (phone, name, email) {
                    setState(() {
                      _contactPhone = phone;
                      _contactName = name;
                      _contactEmail = email;
                      _phoneError = null;
                      _nameError = null;
                    });
                  },
                  onQRScanTap: () {
                    context.push(Routes.qrScanner);
                  },
                  phoneError: _phoneError,
                  nameError: _nameError,
                ),
                
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add a note about this transaction',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 24),
                
                DatePickerField(
                  label: 'Due Date (Optional)',
                  hintText: 'Tap to select due date',
                  selectedDate: _dueDate,
                  onDateSelected: (date) {
                    setState(() {
                      _dueDate = date;
                    });
                  },
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  prefixIcon: Icons.event,
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: _verificationRequired 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification Required',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Require the other party to verify this transaction',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _verificationRequired,
                        onChanged: (value) {
                          setState(() {
                            _verificationRequired = value;
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}