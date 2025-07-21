import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

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
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNodes[0].requestFocus();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    final code = _codeControllers.map((controller) => controller.text).join();
    if (code.length == 6) {
      context.read<AuthCubit>().verifyPhoneCode(widget.verificationId, code);
    }
  }

  void _resendCode() {
    if (_canResend) {
      context.read<AuthCubit>().sendPhoneVerificationCode(widget.phoneNumber);
      _startTimer();
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
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
            for (var controller in _codeControllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          } else if (state is PhoneVerificationCompleted || state is AuthAuthenticated) {
            CustomToast.show(
              context,
              message: 'Phone verified successfully!',
              isSuccess: true,
            );
            // Navigation to home screen is handled by auto refresh on auth changes from auth cubit and app.dart
          } else if (state is PhoneCodeSent) {
            CustomToast.show(
              context,
              message: 'New code sent!',
              isSuccess: true,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.sms,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Enter Verification Code',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 50,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _focusNodes[index].hasFocus
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withOpacity(0.3),
                                width: _focusNodes[index].hasFocus ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _codeControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onCodeChanged(value, index),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is PhoneVerificationLoading;
                          
                          return SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      final code = _codeControllers
                                          .map((controller) => controller.text)
                                          .join();
                                      if (code.length == 6) {
                                        _verifyCode();
                                      } else {
                                        CustomToast.show(
                                          context,
                                          message: 'Please enter the complete code',
                                          isSuccess: false,
                                        );
                                      }
                                    },
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
                                      'Verify Code',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          );
                        },
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
                            onPressed: _canResend ? _resendCode : null,
                            child: Text(
                              _canResend
                                  ? 'Resend'
                                  : 'Resend in ${_secondsRemaining}s',
                              style: TextStyle(
                                color: _canResend
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                TextButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  child: Text(
                    'I\'ll verify later',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}