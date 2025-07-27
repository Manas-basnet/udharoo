import 'dart:async';
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    widget.phoneController.removeListener(_onPhoneChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPhoneChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final phone = widget.phoneController.text.trim();
      if (phone.length >= 7) {
        context.read<TransactionFormCubit>().lookupUserByPhone(phone);
      } else if (phone.isEmpty) {
        context.read<TransactionFormCubit>().clearUserLookup();
        _clearSelectedUser();
      }
    });
  }

  void _selectUser(AuthUser user) {
    setState(() {
      _selectedUser = user;
    });
    
    widget.nameController.text = user.displayName ?? user.fullName ?? '';
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(user);
    }
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
    });
    
    widget.nameController.clear();
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null);
    }
  }

  void _editPhoneNumber() {
    setState(() {
      _selectedUser = null;
    });
    widget.nameController.clear();
    context.read<TransactionFormCubit>().clearUserLookup();
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Phone number input
          TextFormField(
            controller: widget.phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '98XXXXXXXX',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: _buildPhoneSuffixIcon(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: _selectedUser != null 
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.scaffoldBackgroundColor,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: widget.phoneValidator,
            readOnly: _selectedUser != null,
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
          
          // Name input
          if (_selectedUser != null) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Auto-filled from contact',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
              validator: widget.nameValidator,
              readOnly: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneSuffixIcon() {
    return BlocBuilder<TransactionFormCubit, TransactionFormState>(
      builder: (context, state) {
        if (_selectedUser != null) {
          return IconButton(
            onPressed: _editPhoneNumber,
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit phone number',
          );
        } else if (state is TransactionFormUserLookupLoading) {
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
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          );
        } else if (state is TransactionFormUserNotFound) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUserStatus(TransactionFormState state, ThemeData theme) {
    if (state is TransactionFormUserFound) {
      return Container(
        key: const ValueKey('user_found'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 20,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Found: ${state.user.displayName ?? state.user.fullName ?? 'Unknown'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (state.user.email != null)
                    Text(
                      state.user.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (state is TransactionFormUserNotFound) {
      return Container(
        key: const ValueKey('user_not_found'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error,
              size: 20,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'User not found. This phone number is not registered on Udharoo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}