import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/config/routes/router_config.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class PhoneSetupScreen extends StatefulWidget {
  const PhoneSetupScreen({super.key});

  @override
  State<PhoneSetupScreen> createState() => _PhoneSetupScreenState();
}

class _PhoneSetupScreenState extends State<PhoneSetupScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+977';
  bool _hasExistingPhone = false;
  String? _existingPhoneNumber;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+977', 'country': 'Nepal', 'flag': '🇳🇵'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingPhoneNumber();
  }

  void _checkExistingPhoneNumber() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.phoneNumber != null) {
      setState(() {
        _hasExistingPhone = true;
        _existingPhoneNumber = authState.user.phoneNumber;
      });
      
      final phone = authState.user.phoneNumber!;
      final countryCode = _extractCountryCode(phone);
      if (countryCode != null) {
        _selectedCountryCode = countryCode;
        _phoneController.text = phone.substring(countryCode.length);
      } else {
        _phoneController.text = phone;
      }
    } else if (authState is PhoneVerificationRequired && authState.user.phoneNumber != null) {
      setState(() {
        _hasExistingPhone = true;
        _existingPhoneNumber = authState.user.phoneNumber;
      });
      
      final phone = authState.user.phoneNumber!;
      final countryCode = _extractCountryCode(phone);
      if (countryCode != null) {
        _selectedCountryCode = countryCode;
        _phoneController.text = phone.substring(countryCode.length);
      } else {
        _phoneController.text = phone;
      }
    }
  }

  String? _extractCountryCode(String phoneNumber) {
    for (final country in _countryCodes) {
      if (phoneNumber.startsWith(country['code']!)) {
        return country['code']!;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is PhoneCodeSent) {
            context.go(
              Routes.phoneVerification,
              extra: PhoneVerificationExtra(
                phoneNumber: state.phoneNumber,
                verificationId: state.verificationId,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          //TODO : show close app dialog
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32,),
                  
                  // Content
                  Column(
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.phone_android,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        _hasExistingPhone ? 'Verify Your Device' : 'Verify Your Phone',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        _hasExistingPhone 
                            ? 'We need to verify this device to secure your account.'
                            : 'We need to verify your phone number to secure your account.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Form Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_hasExistingPhone) ...[
                                // Existing phone display
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Phone Number',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _existingPhoneNumber!,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Phone input
                                Text(
                                  'Phone Number',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    // Country code dropdown
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: theme.colorScheme.outline.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCountryCode,
                                          onChanged: (String? newValue) {
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
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Phone number input
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter phone number',
                                          prefixIcon: const Icon(Icons.phone, size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.red),
                                          ),
                                          filled: true,
                                          fillColor: theme.colorScheme.surface,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                        ),
                                        keyboardType: TextInputType.phone,
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
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Info box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
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
                                        _hasExistingPhone
                                            ? 'We\'ll send a verification code to verify this device.'
                                            : 'We\'ll send a verification code to this number via SMS.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Send Code Button
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is PhoneVerificationLoading;
                                  
                                  return SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              if (_hasExistingPhone) {
                                                context.read<AuthCubit>().reVerifyExistingPhone();
                                              } else {
                                                if (_formKey.currentState?.validate() ?? false) {
                                                  final fullPhoneNumber = 
                                                      '$_selectedCountryCode${_phoneController.text.trim()}';
                                                  context.read<AuthCubit>().sendPhoneVerificationCode(
                                                    fullPhoneNumber,
                                                  );
                                                }
                                              }
                                            },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(
                                              _hasExistingPhone ? 'Verify Device' : 'Send Code',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32,),
                  
                  // Skip button
                  TextButton(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                    },
                    child: Text(
                      'Use a different account',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
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