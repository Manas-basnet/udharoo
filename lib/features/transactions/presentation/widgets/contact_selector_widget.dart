import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';
import 'package:udharoo/features/transactions/presentation/bloc/contact_history/contact_history_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';

class ContactSelectorWidget extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final String? Function(String?)? phoneValidator;
  final String? Function(String?)? nameValidator;
  final Function(AuthUser?, String?)? onUserSelected;
  final bool readOnly;
  final String? qrSourceIndicator;

  const ContactSelectorWidget({
    super.key,
    required this.phoneController,
    required this.nameController,
    this.phoneValidator,
    this.nameValidator,
    this.onUserSelected,
    this.readOnly = false,
    this.qrSourceIndicator,
  });

  @override
  State<ContactSelectorWidget> createState() => _ContactSelectorWidgetState();
}

class _ContactSelectorWidgetState extends State<ContactSelectorWidget> {
  AuthUser? _selectedUser;
  Timer? _debounceTimer;
  final FocusNode _phoneFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) {
      widget.phoneController.addListener(_onPhoneChanged);
      _phoneFocusNode.addListener(_onFocusChanged);
      
      // Load contact history when widget initializes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ContactHistoryCubit>().loadContactHistory();
      });
    }
  }

  @override
  void dispose() {
    if (!widget.readOnly) {
      widget.phoneController.removeListener(_onPhoneChanged);
      _phoneFocusNode.removeListener(_onFocusChanged);
    }
    _phoneFocusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_phoneFocusNode.hasFocus && !widget.readOnly) {
      _showContactHistoryOverlay();
    } else {
      _hideContactHistoryOverlay();
    }
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
      
      // Update contact history search
      if (phone.isNotEmpty) {
        context.read<ContactHistoryCubit>().searchContacts(phone);
      } else {
        context.read<ContactHistoryCubit>().loadContactHistory();
      }
    });
  }

  void _selectUser(AuthUser user, {String? phoneNumber}) {
    String formattedPhone = phoneNumber ?? widget.phoneController.text.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+977$formattedPhone';
    }
    
    setState(() {
      _selectedUser = user;
    });
    
    widget.nameController.text = user.displayName ?? user.fullName ?? '';
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(user, formattedPhone);
    }
    
    _hideContactHistoryOverlay();
  }

  void _selectFromHistory(ContactHistory contact) {
    widget.phoneController.text = contact.phoneNumber.replaceFirst('+977', '');
    widget.nameController.text = contact.name;
    
    // Try to look up the user
    context.read<TransactionFormCubit>().lookupUserByPhone(contact.phoneNumber);
    
    _hideContactHistoryOverlay();
    _phoneFocusNode.unfocus();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
    });
    
    widget.nameController.clear();
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null, null);
    }
  }

  void _editPhoneNumber() {
    setState(() {
      _selectedUser = null;
    });
    widget.nameController.clear();
    context.read<TransactionFormCubit>().clearUserLookup();
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null, null);
    }
  }

  void _showContactHistoryOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
    });
  }

  void _hideContactHistoryOverlay() {
    _removeOverlay();
    setState(() {
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    
    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: BlocBuilder<ContactHistoryCubit, ContactHistoryState>(
              builder: (context, state) {
                return _buildContactHistoryList(state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactHistoryList(ContactHistoryState state) {
    final theme = Theme.of(context);
    
    switch (state) {
      case ContactHistoryLoading():
      case ContactHistorySearching():
        return Container(
          height: 60,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
        
      case ContactHistoryLoaded():
      case ContactHistorySearchResults():
        final contacts = state is ContactHistoryLoaded 
            ? state.contacts 
            : (state as ContactHistorySearchResults).contacts;
            
        if (contacts.isEmpty) {
          return Container(
            height: 60,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No recent contacts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }
        
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: contacts.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return _buildContactHistoryItem(contact, theme);
          },
        );
        
      case ContactHistoryError():
        return Container(
          height: 60,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error loading contacts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContactHistoryItem(ContactHistory contact, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectFromHistory(contact),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.history,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          contact.phoneNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          ' • ${contact.transactionCount} transactions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                contact.formattedLastUsed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR Source Indicator
        if (widget.qrSourceIndicator != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.qrSourceIndicator!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Phone number input
        TextFormField(
          controller: widget.phoneController,
          focusNode: _phoneFocusNode,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: widget.readOnly ? '' : '98XXXXXXXX',
            prefixIcon: const Icon(Icons.phone, size: 20),
            suffixIcon: _buildPhoneSuffixIcon(),
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
            filled: true,
            fillColor: _selectedUser != null || widget.readOnly
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.scaffoldBackgroundColor,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: widget.readOnly ? [] : [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: widget.phoneValidator,
          readOnly: _selectedUser != null || widget.readOnly,
        ),
        
        const SizedBox(height: 12),
        
        // User lookup result
        if (!widget.readOnly)
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
        if (_selectedUser != null || widget.readOnly) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: widget.readOnly ? '' : 'Auto-filled from contact',
              prefixIcon: const Icon(Icons.person, size: 20),
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
              filled: true,
              fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
            validator: widget.nameValidator,
            readOnly: true,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneSuffixIcon() {
    return BlocBuilder<TransactionFormCubit, TransactionFormState>(
      builder: (context, state) {
        if (widget.readOnly) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.qr_code,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          );
        } else if (_selectedUser != null) {
          return IconButton(
            onPressed: _editPhoneNumber,
            icon: const Icon(Icons.edit, size: 16),
            tooltip: 'Edit phone number',
          );
        } else if (state is TransactionFormUserLookupLoading) {
          return Container(
            padding: const EdgeInsets.all(14),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        } else if (state is TransactionFormUserFound) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          );
        } else if (state is TransactionFormUserNotFound) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 20,
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
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 16,
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
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error,
              size: 16,
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