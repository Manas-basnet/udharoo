import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:udharoo/features/phone_verification/presentation/bloc/phone_verification_cubit.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ChangePhoneVerificationScreen extends StatefulWidget {
  final String currentPhoneNumber;
  final String newPhoneNumber;
  final String verificationId;

  const ChangePhoneVerificationScreen({
    super.key,
    required this.currentPhoneNumber,
    required this.newPhoneNumber,
    required this.verificationId,
  });

  @override
  State<ChangePhoneVerificationScreen> createState() => _ChangePhoneVerificationScreenState();
}

class _ChangePhoneVerificationScreenState extends State<ChangePhoneVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  StreamController<ErrorAnimationType>? errorController;

  late String verificationId;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  String _currentCode = "";

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
    _timer?.cancel();
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
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyCode() {
    if (_currentCode.length == 6) {
      final cubit = context.read<PhoneVerificationCubit>();
      cubit.verifyPhoneCode(verificationId, _currentCode);
    }
  }

  void _resendCode() {
    if (_canResend) {
      final cubit = context.read<PhoneVerificationCubit>();
      cubit.resendPhoneVerificationCode();
      _startTimer();
      if (mounted) {
        _codeController.clear();
        setState(() {
          _currentCode = "";
        });
      }
    }
  }

  void _handleCancel() {
    final cubit = context.read<PhoneVerificationCubit>();
    cubit.cancelPhoneNumberChange();
    context.pop();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return BlocListener<PhoneVerificationCubit, PhoneVerificationState>(
      listener: (context, state) {
        switch (state) {
          case PhoneVerificationError():
            if (mounted) {
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
            }
          case PhoneVerificationCompleted():
            if (mounted) {
              CustomToast.show(
                context,
                message: 'Phone number changed successfully!',
                isSuccess: true,
              );
              
              context.read<AuthSessionCubit>().setUser(state.user);
              context.read<PhoneVerificationCubit>().cancelPhoneNumberChange();
              
              context.pop();
              context.pop();
              context.pop();
            }
          case PhoneCodeResent():
            if (mounted) {
              verificationId = state.verificationId;
              CustomToast.show(
                context,
                message: 'New code sent to your new number!',
                isSuccess: true,
              );
            }
          case PhoneVerificationAutoCompleted():
            if (mounted) {
              context.read<AuthSessionCubit>().checkAuthStatus();
              CustomToast.show(
                context,
                message: 'Phone number changed successfully!',
                isSuccess: true,
              );
              context.pop();
              context.pop();
              context.pop();
            }
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
                      onPressed: _handleCancel,
                      icon: const Icon(Icons.arrow_back),
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - 200,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.sms,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Verify New Number',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              children: [
                                const TextSpan(text: 'We sent a 6-digit code to your new number\n'),
                                TextSpan(
                                  text: widget.newPhoneNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
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
                                selectedFillColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                activeColor: theme.colorScheme.primary,
                                inactiveColor: theme.colorScheme.outline.withValues(alpha: 0.3),
                                selectedColor: theme.colorScheme.primary,
                                disabledColor: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                              onCompleted: (v) => _verifyCode(),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    _currentCode = value;
                                  });
                                }
                              },
                              beforeTextPaste: (text) => true,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
                          builder: (context, state) {
                            final isLoading = state is PhoneVerificationLoading;
                            
                            return SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: (isLoading || _currentCode.length < 6)
                                    ? null
                                    : _verifyCode,
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
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Didn\'t receive the code? ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
                              builder: (context, state) {
                                final isLoading = state is PhoneVerificationLoading;
                                
                                return TextButton(
                                  onPressed: (_canResend && !isLoading) ? _resendCode : null,
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
                                      color: (_canResend && !isLoading)
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Changing from:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Text(
                                      widget.currentPhoneNumber,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SizedBox(width: 24),
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.newPhoneNumber,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        TextButton(
                          onPressed: _handleCancel,
                          child: Text(
                            'Cancel Change',
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
              ),
            ],
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