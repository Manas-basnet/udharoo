import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';
import 'package:udharoo/shared/services/smart_suggestions_service.dart';

class ContactSelectorWidget extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final String? Function(String?)? phoneValidator;
  final String? Function(String?)? nameValidator;
  final Function(AuthUser?, String?, TransactionType?)? onUserSelected;
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

class _ContactSelectorWidgetState extends State<ContactSelectorWidget>
    with SingleTickerProviderStateMixin {
  AuthUser? _selectedUser;
  Timer? _debounceTimer;
  final FocusNode _phoneFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuggestions = false;
  List<Contact> _recentContacts = [];
  TransactionType? _suggestedType;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (!widget.readOnly) {
      widget.phoneController.addListener(_onPhoneChanged);
      _phoneFocusNode.addListener(_onFocusChanged);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ContactCubit>().loadContacts();
        _loadRecentContacts();
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
    _animationController.dispose();
    super.dispose();
  }

  void _loadRecentContacts() {
    final transactionState = context.read<TransactionCubit>().state;
    final recentContactIds = SmartSuggestionsService.getRecentContacts(
      transactionState.transactions,
      limit: 5,
    );
    
    final contactState = context.read<ContactCubit>().state;
    final recentContacts = <Contact>[];
    
    for (final contactId in recentContactIds) {
      final contact = contactState.contacts
          .where((c) => c.contactUserId == contactId)
          .firstOrNull;
      if (contact != null) {
        recentContacts.add(contact);
      }
    }
    
    setState(() {
      _recentContacts = recentContacts;
    });
  }

  void _onFocusChanged() {
    if (_phoneFocusNode.hasFocus && !widget.readOnly) {
      _showContactsDropdown();
    } else {
      _hideContactsDropdown();
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

      if (phone.isNotEmpty) {
        context.read<ContactCubit>().searchContacts(phone);
      } else {
        context.read<ContactCubit>().clearSearch();
      }
    });
  }

  void _selectUser(AuthUser user, {String? phoneNumber}) {
    String formattedPhone = phoneNumber ?? widget.phoneController.text.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+977$formattedPhone';
    }
    
    final transactionState = context.read<TransactionCubit>().state;
    final suggestedType = SmartSuggestionsService.suggestTransactionType(
      user.uid,
      transactionState.transactions,
    );
    
    setState(() {
      _selectedUser = user;
      _suggestedType = suggestedType;
    });
    
    widget.nameController.text = user.displayName ?? user.fullName ?? '';
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(user, formattedPhone, suggestedType);
    }
    
    _hideContactsDropdown();
    _phoneFocusNode.unfocus();

    _autoSaveContact(user, formattedPhone);
  }

  void _selectFromContact(Contact contact) {
    widget.phoneController.text = contact.phoneNumber.replaceFirst('+977', '');
    widget.nameController.text = contact.name;
    
    context.read<TransactionFormCubit>().lookupUserByPhone(contact.phoneNumber);
    
    _hideContactsDropdown();
    _phoneFocusNode.unfocus();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
      _suggestedType = null;
    });
    
    widget.nameController.clear();
    
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null, null, null);
    }
  }

  void _editPhoneNumber() {
    setState(() {
      _selectedUser = null;
      _suggestedType = null;
    });
    widget.nameController.clear();
    context.read<TransactionFormCubit>().clearUserLookup();
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(null, null, null);
    }
  }

  void _showContactsDropdown() {
    if (!_showSuggestions) {
      setState(() {
        _showSuggestions = true;
      });
      _animationController.forward();
    }
  }

  void _hideContactsDropdown() {
    if (_showSuggestions) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _autoSaveContact(AuthUser user, String phoneNumber) {
    if (user.uid.isNotEmpty && user.displayName?.isNotEmpty == true) {
      context.read<ContactCubit>().addContact(
        contactUserId: user.uid,
        name: user.displayName ?? user.fullName ?? '',
        phoneNumber: phoneNumber,
        email: user.email,
        photoUrl: user.photoURL,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: widget.phoneController,
                focusNode: _phoneFocusNode,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: widget.readOnly ? '' : '98XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  suffixIcon: _buildPhoneSuffixIcon(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(6),
                      topRight: const Radius.circular(6),
                      bottomLeft: Radius.circular(_showSuggestions ? 0 : 6),
                      bottomRight: Radius.circular(_showSuggestions ? 0 : 6),
                    ),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(6),
                      topRight: const Radius.circular(6),
                      bottomLeft: Radius.circular(_showSuggestions ? 0 : 6),
                      bottomRight: Radius.circular(_showSuggestions ? 0 : 6),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(6),
                      topRight: const Radius.circular(6),
                      bottomLeft: Radius.circular(_showSuggestions ? 0 : 6),
                      bottomRight: Radius.circular(_showSuggestions ? 0 : 6),
                    ),
                    borderSide: BorderSide.none,
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

              if (_showSuggestions && !widget.readOnly)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: BlocBuilder<ContactCubit, ContactState>(
                      builder: (context, state) {
                        return _buildContactsDropdown(state, theme);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
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
        
        if (_suggestedType != null && _selectedUser != null) ...[
          const SizedBox(height: 12),
          _buildSmartSuggestion(theme),
        ],
      ],
    );
  }

  Widget _buildContactsDropdown(ContactState state, ThemeData theme) {
    if (state.isSearching || state.isLoading) {
      return Container(
        height: 60,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (state.hasError) {
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
    }
    
    final searchQuery = widget.phoneController.text.trim();
    final displayContacts = searchQuery.isEmpty ? _recentContacts : state.displayContacts;
    
    if (displayContacts.isEmpty) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty ? Icons.history : Icons.search_off,
              size: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty ? 'No recent contacts' : 'No contacts found',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchQuery.isEmpty && _recentContacts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Recent contacts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: displayContacts.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final contact = displayContacts[index];
              return _buildContactItem(contact, theme, searchQuery.isEmpty);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(Contact contact, ThemeData theme, bool isRecentContact) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectFromContact(contact),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.displayName.isNotEmpty 
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecentContact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Recent',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 18,
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact found: ${state.user.displayName ?? state.user.fullName ?? 'Unknown'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state.user.email != null)
                    Text(
                      state.user.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
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
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error,
              size: 18,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Contact not found. This phone number is not registered on Udharoo.',
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

  Widget _buildSmartSuggestion(ThemeData theme) {
    final typeText = _suggestedType == TransactionType.lent ? 'give money' : 'receive money';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Smart suggestion: You usually $typeText with ${_selectedUser?.displayName ?? 'this contact'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}