import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  StreamController<ErrorAnimationType>? errorController;

  late String verificationId;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  String _currentCode = "";

  bool get _isChanging => context.read<AuthCubit>().isChangingPhoneNumber;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
    errorController = StreamController<ErrorAnimationType>();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _verifyCode() {
    if (_currentCode.length == 6) {
      context.read<AuthCubit>().verifyPhoneCode(verificationId, _currentCode);
    }
  }

  void _resendCode() {
    if (_canResend) {
      context.read<AuthCubit>().sendPhoneVerificationCode(widget.phoneNumber);
      _startTimer();
      _codeController.clear();
      setState(() {
        _currentCode = "";
      });
    }
  }

  void _handleBackButton() {
    if (_isChanging) {
      context.read<AuthCubit>().cancelPhoneNumberChange();
      context.pop();
    }
  }

  String _getTitle() {
    if (_isChanging) {
      return 'Verify New Number';
    }
    return 'Enter Verification Code';
  }

  String _getBackButtonText() {
    if (_isChanging) {
      return 'Cancel change';
    }
    return 'Use a different account';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            errorController?.add(ErrorAnimationType.clear);
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
            _codeController.clear();
            setState(() {
              _currentCode = "";
            });
          } else if (state is PhoneVerificationCompleted || state is AuthAuthenticated) {
            String message = 'Phone verified successfully!';
            if (_isChanging) {
              message = 'Phone number changed successfully!';
              context.read<AuthCubit>().cancelPhoneNumberChange();
            }
            CustomToast.show(
              context,
              message: message,
              isSuccess: true,
            );
            
            if (_isChanging) {
              context.pop();
              context.pop();
            }
          } else if (state is PhoneCodeSent && state.verificationId != verificationId) {
            verificationId = state.verificationId;
            CustomToast.show(
              context,
              message: 'New code sent!',
              isSuccess: true,
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isChanging ? () => context.pop() : null,
                        icon: Icon(_isChanging ? Icons.arrow_back : Icons.close),
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
                  
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.sms,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        _getTitle(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          children: [
                            TextSpan(text: _isChanging 
                                ? 'We sent a 6-digit code to your new number\n'
                                : 'We sent a 6-digit code to\n'),
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
                      
                      const SizedBox(height: 24),
                      
                      Form(
                        key: _formKey,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.05,
                          ),
                          child: PinCodeTextField(
                            appContext: context,
                            pastedTextStyle: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            length: 6,
                            obscureText: false,
                            obscuringCharacter: '*',
                            blinkWhenObscuring: true,
                            animationType: AnimationType.fade,
                            validator: (v) {
                              if (v!.length < 6) {
                                return "Please enter complete code";
                              } else {
                                return null;
                              }
                            },
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(8),
                              fieldHeight: 50,
                              fieldWidth: 40,
                              activeFillColor: theme.colorScheme.surface,
                              inactiveFillColor: theme.colorScheme.surface,
                              selectedFillColor: theme.colorScheme.primary.withOpacity(0.1),
                              activeColor: theme.colorScheme.primary,
                              inactiveColor: theme.colorScheme.outline.withOpacity(0.3),
                              selectedColor: theme.colorScheme.primary,
                              disabledColor: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                            cursorColor: theme.colorScheme.primary,
                            animationDuration: const Duration(milliseconds: 300),
                            enableActiveFill: true,
                            errorAnimationController: errorController,
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            boxShadows: [
                              BoxShadow(
                                offset: const Offset(0, 1),
                                color: Colors.black12,
                                blurRadius: 2,
                              )
                            ],
                            onCompleted: (v) {
                              _verifyCode();
                            },
                            onChanged: (value) {
                              setState(() {
                                _currentCode = value;
                              });
                            },
                            beforeTextPaste: (text) {
                              return true;
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is PhoneVerificationLoading;
                          
                          return SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: (isLoading || _currentCode.length < 6)
                                  ? null
                                  : _verifyCode,
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
                                      'Verify Code',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Didn\'t receive the code? ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          TextButton(
                            onPressed: _canResend ? _resendCode : null,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _canResend
                                  ? 'Resend'
                                  : 'Resend in ${_secondsRemaining}s',
                              style: TextStyle(
                                color: _canResend
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32,),
                  
                  TextButton(
                    onPressed: _handleBackButton,
                    child: Text(
                      _getBackButtonText(),
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
    _timer?.cancel();
    errorController?.close();
    _codeController.dispose();
    super.dispose();
  }
}