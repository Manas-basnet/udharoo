import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class PhoneVerificationScreenArgs {
  final String phoneNumber;
  final String verificationId;

  PhoneVerificationScreenArgs({
    required this.phoneNumber,
    required this.verificationId,
  });
}

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.uid;
      context.read<AuthCubit>().setPhoneVerificationInProgress();
    }
    
    context.read<ProfileCubit>().resetError();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated || state is AuthError) {
                if (_isLoading) {
                  setState(() => _isLoading = false);
                  CustomToast.show(
                    context,
                    message: 'Verification failed. Please try again.',
                    isSuccess: false,
                  );
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          BlocListener<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                setState(() => _isLoading = false);
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
              } else if (state is PhoneVerified) {
                setState(() => _isLoading = false);
                context.read<AuthCubit>().updateUserProfile(state.updatedProfile);
                context.read<AuthCubit>().setPhoneVerificationCompleted();
                CustomToast.show(
                  context,
                  message: 'Phone number verified successfully!',
                  isSuccess: true,
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Verification Code',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Enter the 6-digit code sent to',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    widget.phoneNumber,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _codeController,
                    focusNode: _focusNode,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: theme.colorScheme.surface,
                      inactiveFillColor: theme.colorScheme.surface,
                      selectedFillColor: theme.colorScheme.surface,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.outline.withOpacity(0.3),
                      selectedColor: theme.colorScheme.primary,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onCompleted: (value) => _verifyCode(),
                    onChanged: (value) {},
                    beforeTextPaste: (text) => text?.contains(RegExp(r'^\d{6}$')) ?? false,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    
    if (code.length != 6) {
      CustomToast.show(
        context,
        message: 'Please enter a valid 6-digit code',
        isSuccess: false,
      );
      return;
    }
    
    if (_isLoading) return;
    
    final authState = context.read<AuthCubit>().state;
    
    if (authState is! AuthAuthenticated) {
      if (authState is AuthUnauthenticated) {
        CustomToast.show(
          context,
          message: 'Session expired. Please sign in again.',
          isSuccess: false,
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (authState is AuthError) {
        CustomToast.show(
          context,
          message: 'Authentication error. Please try again.',
          isSuccess: false,
        );
        Navigator.of(context).pop();
      } else {
        CustomToast.show(
          context,
          message: 'Please wait for authentication to complete.',
          isSuccess: false,
        );
      }
      return;
    }
    
    if (_currentUserId != null && authState.user.uid != _currentUserId) {
      CustomToast.show(
        context,
        message: 'User session changed. Please try again.',
        isSuccess: false,
      );
      Navigator.of(context).pop();
      return;
    }
    
    setState(() => _isLoading = true);
    
    context.read<ProfileCubit>().verifyPhoneNumber(
      widget.verificationId,
      code,
      authState.user.uid,
    );
  }

  void _resendCode() {
    if (_isLoading) return;
    
    context.read<ProfileCubit>().sendPhoneVerification(widget.phoneNumber);
    
    CustomToast.show(
      context,
      message: 'Verification code sent!',
      isSuccess: true,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}