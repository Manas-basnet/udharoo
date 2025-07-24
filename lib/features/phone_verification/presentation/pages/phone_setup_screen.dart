import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/phone_verification/presentation/bloc/phone_verification_cubit.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class PhoneVerificationExtra {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationExtra({
    required this.phoneNumber,
    required this.verificationId,
  });
}

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
    final authState = context.read<AuthSessionCubit>().state;
    
    if (authState is AuthSessionAuthenticated && 
        authState.user.phoneNumber != null && 
        authState.user.phoneNumber!.isNotEmpty) {
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

  void _handleSendCode() {
    final phoneVerificationCubit = context.read<PhoneVerificationCubit>();
    
    if (_hasExistingPhone) {
      phoneVerificationCubit.sendPhoneVerificationCode(_existingPhoneNumber!);
    } else {
      if (_formKey.currentState?.validate() ?? false) {
        final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
        phoneVerificationCubit.sendPhoneVerificationCode(fullPhoneNumber);
      }
    }
  }

  void _handleUseAnotherAccount() {
    context.read<AuthSessionCubit>().signOut();
  }

  void _navigateToHomeScreen() {
    while (context.canPop()) {
      context.pop();
    }
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return BlocListener<PhoneVerificationCubit, PhoneVerificationState>(
      listener: (context, state) {
        switch (state) {
          case PhoneVerificationError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          case PhoneCodeSent():
            context.push(
              Routes.phoneVerification,
              extra: PhoneVerificationExtra(
                phoneNumber: state.phoneNumber,
                verificationId: state.verificationId,
              ),
            );
          case PhoneVerificationAutoCompleted():
            context.read<AuthSessionCubit>().checkAuthStatus();
            _navigateToHomeScreen();
          case PhoneVerificationCompleted():
            context.read<AuthSessionCubit>().setUser(state.user);
            _navigateToHomeScreen();
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _handleUseAnotherAccount(),
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
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: keyboardHeight + 24,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.phone_android,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        _hasExistingPhone ? 'Verify Your Device' : 'Verify Your Phone',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _hasExistingPhone 
                              ? 'We need to verify this device to secure your account.'
                              : 'We need to verify your phone number to secure your account.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_hasExistingPhone) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
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
                                            const SizedBox(height: 4),
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
                                Text(
                                  'Phone Number',
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
                                    
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter phone number',
                                          prefixIcon: const Icon(Icons.phone, size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
                              
                              const SizedBox(height: 20),
                              
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
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
                              
                              const SizedBox(height: 24),
                              
                              BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
                                builder: (context, state) {
                                  final isLoading = state is PhoneVerificationLoading;
                                  
                                  return SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: isLoading ? null : _handleSendCode,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(
                                              _hasExistingPhone ? 'Verify Device' : 'Send Code',
                                              style: theme.textTheme.bodyLarge?.copyWith(
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
                      
                      const SizedBox(height: 32),
                      
                      TextButton(
                        onPressed: _handleUseAnotherAccount,
                        child: Text(
                          'Use a different account',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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