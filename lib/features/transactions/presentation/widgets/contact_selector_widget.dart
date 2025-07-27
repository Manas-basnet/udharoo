import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';

class ContactSelectorWidget extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final String? Function(String?)? phoneValidator;
  final String? Function(String?)? nameValidator;
  final Function(AuthUser?)? onUserSelected;

  const ContactSelectorWidget({
    super.key,
    required this.phoneController,
    required this.nameController,
    this.phoneValidator,
    this.nameValidator,
    this.onUserSelected,
  });

  @override
  State<ContactSelectorWidget> createState() => _ContactSelectorWidgetState();
}

class _ContactSelectorWidgetState extends State<ContactSelectorWidget> {
  AuthUser? _selectedUser;
  bool _isManualEntry = false;

  @override
  void initState() {
    super.initState();
    widget.phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    widget.phoneController.removeListener(_onPhoneChanged);
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = widget.phoneController.text.trim();
    if (phone.length >= 7) {
      context.read<TransactionFormCubit>().lookupUserByPhone(phone);
    } else if (phone.isEmpty) {
      context.read<TransactionFormCubit>().clearUserLookup();
      _clearSelectedUser();
    }
  }

  void _selectUser(AuthUser user) {
    setState(() {
      _selectedUser = user;
      _isManualEntry = false;
    });
    
    widget.nameController.text = user.displayName ?? user.fullName ?? '';
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(user);
    }
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
      _isManualEntry = false;
    });
    
    widget.nameController.clear();
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null);
    }
  }

  void _enableManualEntry() {
    setState(() {
      _isManualEntry = true;
      _selectedUser = null;
    });
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_search,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Contact Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Phone number input
          TextFormField(
            controller: widget.phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '98XXXXXXXX',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: BlocBuilder<TransactionFormCubit, TransactionFormState>(
                builder: (context, state) {
                  if (state is TransactionFormUserLookupLoading) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  } else if (state is TransactionFormUserFound) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    );
                  } else if (state is TransactionFormUserNotFound) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.person_add,
                        color: Colors.orange,
                        size: 24,
                      ),
                    );
                  }
                  return SizedBox();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: widget.phoneValidator,
            enabled: _selectedUser == null,
          ),
          
          const SizedBox(height: 16),
          
          // User lookup result
          BlocListener<TransactionFormCubit, TransactionFormState>(
            listener: (context, state) {
              if (state is TransactionFormUserFound) {
                _selectUser(state.user);
              } else if (state is TransactionFormUserNotFound) {
                _clearSelectedUser();
              }
            },
            child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildUserStatus(state, theme),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name input
          TextFormField(
            controller: widget.nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: _selectedUser != null 
                  ? 'Auto-filled from contact'
                  : 'Enter full name',
              prefixIcon: const Icon(Icons.person),
              suffix: _selectedUser != null
                  ? InkWell(
                      onTap: _clearSelectedUser,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _selectedUser != null 
                  ? Colors.green.withValues(alpha: 0.05)
                  : theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: widget.nameValidator,
            readOnly: _selectedUser != null && !_isManualEntry,
            textCapitalization: TextCapitalization.words,
          ),
          
          // Manual entry option for user not found
          const SizedBox(height: 12),
          BlocBuilder<TransactionFormCubit, TransactionFormState>(
            builder: (context, state) {
              if (state is TransactionFormUserNotFound && !_isManualEntry) {
                return InkWell(
                  onTap: _enableManualEntry,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'User not found. Tap to continue with manual entry',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatus(TransactionFormState state, ThemeData theme) {
    if (state is TransactionFormUserFound) {
      return Container(
        key: const ValueKey('user_found'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.verified_user,
                size: 20,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.user.displayName ?? state.user.fullName ?? 'Unknown User',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                    ),
                  ),
                  if (state.user.email != null) ...[
                    Text(
                      state.user.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}