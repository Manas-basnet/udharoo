import 'package:flutter/material.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction_contact.dart';

class ContactSelectorWidget extends StatefulWidget {
  final String? initialPhone;
  final String? initialName;
  final String? initialEmail;
  final List<TransactionContact> recentContacts;
  final Function(String? phone, String name, String? email) onContactSelected;
  final Function() onQRScanTap;
  final String? phoneError;
  final String? nameError;
  final bool verificationRequired;
  final Function(String) onPhoneValidation;

  const ContactSelectorWidget({
    super.key,
    this.initialPhone,
    this.initialName,
    this.initialEmail,
    required this.recentContacts,
    required this.onContactSelected,
    required this.onQRScanTap,
    this.phoneError,
    this.nameError,
    required this.verificationRequired,
    required this.onPhoneValidation,
  });

  @override
  State<ContactSelectorWidget> createState() => _ContactSelectorWidgetState();
}

class _ContactSelectorWidgetState extends State<ContactSelectorWidget> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _showRecentContacts = false;
  bool _isValidatingPhone = false;
  List<TransactionContact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone ?? '';
    _nameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
    
    _phoneController.addListener(_onPhoneChanged);
    _nameController.addListener(_onContactDataChanged);
    _emailController.addListener(_onContactDataChanged);
    
    _filteredContacts = widget.recentContacts;
  }

  @override
  void didUpdateWidget(ContactSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.verificationRequired != widget.verificationRequired) {
      if (!widget.verificationRequired) {
        _phoneController.clear();
        setState(() {
          _showRecentContacts = false;
        });
        // Defer the callback to after the build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onContactDataChanged();
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.removeListener(_onContactDataChanged);
    _emailController.removeListener(_onContactDataChanged);
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text;
    
    if (phone.isNotEmpty && widget.verificationRequired) {
      _filteredContacts = widget.recentContacts.where((contact) {
        return contact.phone.contains(phone) || 
               contact.name.toLowerCase().contains(phone.toLowerCase());
      }).toList();
      
      setState(() {
        _showRecentContacts = _filteredContacts.isNotEmpty;
      });

      if (phone.length >= 7) {
        _validatePhoneNumber(phone);
      }
    } else {
      setState(() {
        _filteredContacts = widget.recentContacts;
        _showRecentContacts = false;
      });
    }
    
    // Defer the callback to prevent setState during build
    Future.microtask(() {
      _onContactDataChanged();
    });
  }

  void _validatePhoneNumber(String phone) async {
    setState(() {
      _isValidatingPhone = true;
    });

    widget.onPhoneValidation(phone);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isValidatingPhone = false;
        });
      }
    });
  }

  void _onContactDataChanged() {
    if (mounted) {
      widget.onContactSelected(
        widget.verificationRequired ? _phoneController.text : null,
        _nameController.text,
        _emailController.text.isEmpty ? null : _emailController.text,
      );
    }
  }

  void _selectContact(TransactionContact contact) {
    _phoneController.text = contact.phone;
    _nameController.text = contact.name;
    _emailController.text = contact.email ?? '';
    
    setState(() {
      _showRecentContacts = false;
    });
    
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Contact Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onQRScanTap,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        if (widget.verificationRequired) ...[
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'Enter phone number',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isValidatingPhone)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (widget.recentContacts.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _showRecentContacts 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                      ),
                      onPressed: () {
                        setState(() {
                          _showRecentContacts = !_showRecentContacts;
                          if (_showRecentContacts) {
                            _filteredContacts = widget.recentContacts;
                          }
                        });
                      },
                    ),
                ],
              ),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              errorText: widget.phoneError,
            ),
            keyboardType: TextInputType.phone,
          ),
          
          if (_showRecentContacts && _filteredContacts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      contact.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Text(
                      '${contact.transactionCount} transactions',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () => _selectContact(contact),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone number not required for unverified transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
        
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Contact Name *',
            hintText: 'Enter contact name',
            prefixIcon: const Icon(Icons.person),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            errorText: widget.nameError,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email (Optional)',
            hintText: 'Enter email address',
            prefixIcon: const Icon(Icons.email),
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
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}