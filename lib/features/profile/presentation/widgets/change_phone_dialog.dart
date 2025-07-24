import 'package:flutter/material.dart';

class ChangePhoneDialog extends StatefulWidget {
  final Function(String phoneNumber) onChangePhone;
  final bool isLoading;

  const ChangePhoneDialog({
    super.key,
    required this.onChangePhone,
    this.isLoading = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String phoneNumber) onChangePhone,
    bool isLoading = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => ChangePhoneDialog(
        onChangePhone: onChangePhone,
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends State<ChangePhoneDialog> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCountryCode = '+977';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+977', 'country': 'Nepal', 'flag': '🇳🇵'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.phone_android,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Change Phone Number',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!widget.isLoading)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface,
                          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Enter your new phone number. You will need to verify this number before the change takes effect.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'New Phone Number',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          onChanged: widget.isLoading ? null : (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            }
                          },
                          items: _countryCodes.map((country) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      country['flag']!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      country['code']!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          prefixIcon: const Icon(Icons.phone, size: 20),
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
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !widget.isLoading,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone number is required';
                          }
                          if (value!.length < 7) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can cancel this change at any time before verification is complete.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isLoading 
                            ? null 
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  final fullPhoneNumber = 
                                      '$_selectedCountryCode${_phoneController.text.trim()}';
                                  widget.onChangePhone(fullPhoneNumber);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: widget.isLoading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}