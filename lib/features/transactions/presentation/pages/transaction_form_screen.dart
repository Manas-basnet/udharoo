import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/amount_input_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/contact_selector_widget.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_type_selector.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionFormExtra {
  final QRTransactionData? qrData;
  final TransactionType? initialTransactionType;

  TransactionFormExtra({
    this.qrData,
    this.initialTransactionType,
  });
}

class TransactionFormScreen extends StatefulWidget {
  final QRTransactionData? qrData;
  final Contact? prefilledContact;
  final TransactionType? initialTransactionType;

  const TransactionFormScreen({
    super.key,
    this.qrData,
    this.prefilledContact,
    this.initialTransactionType,
  });

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
  String? _selectedPhoneNumber;
  bool _canSubmit = false;
  bool _isQRSource = false;
  bool _isContactPrefilled = false;

  @override
  void initState() {
    super.initState();
    
    _amountController.addListener(_updateSubmitButtonState);
    _phoneController.addListener(_updateSubmitButtonState);
    _nameController.addListener(_updateSubmitButtonState);
    
    if (widget.qrData != null) {
      _initializeFromQRData(widget.qrData!);
    } else if (widget.prefilledContact != null) {
      _initializeFromContact(widget.prefilledContact!);
    } else if (widget.initialTransactionType != null) {
      _selectedType = widget.initialTransactionType;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromQRData(QRTransactionData qrData) {
    setState(() {
      _isQRSource = true;
    });

    _phoneController.text = qrData.phoneNumber.replaceFirst('+977', '');
    _nameController.text = qrData.userName;
    
    final qrUser = AuthUser(
      uid: qrData.userId,
      displayName: qrData.userName,
      phoneNumber: qrData.phoneNumber,
      email: qrData.email,
      emailVerified: false,
      phoneVerified: true,
      isProfileComplete: true,
    );
    
    _selectedUser = qrUser;
    _selectedPhoneNumber = qrData.phoneNumber;
    
    if (qrData.hasTransactionConstraint) {
      _selectedType = _getConstrainedTransactionType(qrData.transactionTypeConstraint!);
    }
    
    _updateSubmitButtonState();
  }

  void _initializeFromContact(Contact contact) {
    setState(() {
      _isContactPrefilled = true;
    });

    _phoneController.text = contact.phoneNumber.replaceFirst('+977', '');
    _nameController.text = contact.displayName;
    
    final contactUser = AuthUser(
      uid: contact.contactUserId,
      displayName: contact.displayName,
      phoneNumber: contact.phoneNumber,
      email: contact.email,
      emailVerified: false,
      phoneVerified: true,
      isProfileComplete: true,
    );
    
    _selectedUser = contactUser;
    _selectedPhoneNumber = contact.phoneNumber;
    
    _updateSubmitButtonState();
  }

  TransactionType _getConstrainedTransactionType(TransactionType constraint) {
    switch (constraint) {
      case TransactionType.lent:
        return TransactionType.borrowed;
      case TransactionType.borrowed:
        return TransactionType.lent;
    }
  }

  void _updateSubmitButtonState() {
    final newCanSubmit = _selectedUser != null && 
                        _selectedType != null && 
                        _amountController.text.trim().isNotEmpty &&
                        _selectedPhoneNumber != null;
    
    if (newCanSubmit != _canSubmit) {
      setState(() {
        _canSubmit = newCanSubmit;
      });
    }
  }

  void _onUserSelected(AuthUser? user, String? phoneNumber) {
    setState(() {
      _selectedUser = user;
      _selectedPhoneNumber = phoneNumber;
    });
    _updateSubmitButtonState();
  }

  void _onTypeChanged(TransactionType? type) {
    if (_isQRSource && widget.qrData?.hasTransactionConstraint == true) {
      return;
    }
    
    setState(() {
      _selectedType = type;
    });
    _updateSubmitButtonState();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedType == null) {
        CustomToast.show(context, message: 'Please select transaction type', isSuccess: false);
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        CustomToast.show(context, message: 'Please enter a valid amount', isSuccess: false);
        return;
      }

      if (_selectedUser == null || _selectedPhoneNumber == null) {
        CustomToast.show(context, message: 'Please select a valid registered contact', isSuccess: false);
        return;
      }

      final description = _descriptionController.text.trim();

      context.read<TransactionFormCubit>().createTransaction(
        amount: amount,
        otherPartyUid: _selectedUser!.uid,
        otherPartyName: _selectedUser!.displayName ?? _selectedUser!.fullName ?? '',
        otherPartyPhone: _selectedPhoneNumber!,
        description: description,
        type: _selectedType!,
      );
    }
  }

  String _getSourceText() {
    if (_isQRSource) {
      if (widget.qrData?.hasTransactionConstraint == true) {
        return 'From QR • ${widget.qrData!.constraintDisplayText}';
      }
      return 'From QR Code';
    } else if (_isContactPrefilled) {
      return 'From Contact';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listener: (context, state) {
        switch (state) {
          case TransactionFormSuccess():
            CustomToast.show(context, message: 'Transaction created successfully', isSuccess: true);
            context.pop();
            break;
          case TransactionFormError():
            CustomToast.show(context, message: state.message, isSuccess: false);
            break;
          case TransactionFormUserNotFound():
            if (!_isContactPrefilled) {
              setState(() {
                _selectedUser = null;
                _selectedPhoneNumber = null;
              });
              _updateSubmitButtonState();
            }
            break;
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isQRSource || _isContactPrefilled) _buildSourceBanner(theme),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Type',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TransactionTypeSelector(
                              selectedType: _selectedType,
                              onTypeChanged: _onTypeChanged,
                              enabled: !(_isQRSource && widget.qrData?.hasTransactionConstraint == true),
                            ),
                            if (_isQRSource && widget.qrData?.hasTransactionConstraint == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Transaction type is fixed by QR code constraint',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
    
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                          ],
                        ),
                      ),
    
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ContactSelectorWidget(
                              phoneController: _phoneController,
                              nameController: _nameController,
                              onUserSelected: _onUserSelected,
                              readOnly: _isQRSource || _isContactPrefilled,
                              qrSourceIndicator: (_isQRSource || _isContactPrefilled) ? _getSourceText() : null,
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
                                if (_selectedUser == null) {
                                  return 'Please select a registered contact';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
    
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description (Optional)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: 'What was this for?',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
                  builder: (context, state) {
                    final isLoading = state is TransactionFormLoading;
    
                    return SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        onPressed: (isLoading || !_canSubmit) ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create Transaction',
                                style: theme.textTheme.bodyMedium?.copyWith(
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

  String _getAppBarTitle() {
    if (_isQRSource) return 'QR Transaction';
    if (_isContactPrefilled) return 'New Transaction';
    return 'New Transaction';
  }

  Widget _buildSourceBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isQRSource ? Icons.qr_code_scanner : Icons.person,
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
                  _isQRSource ? 'QR Code Transaction' : 'Contact Transaction',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _isQRSource 
                      ? 'Contact details pre-filled from QR code'
                      : 'Contact details pre-filled from ${widget.prefilledContact?.displayName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isQRSource && widget.qrData?.expiresAt != null)
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}