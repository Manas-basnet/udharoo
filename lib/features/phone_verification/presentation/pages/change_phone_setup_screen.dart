import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/phone_verification/presentation/bloc/phone_verification_cubit.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ChangePhoneVerificationExtra {
  final String currentPhoneNumber;
  final String newPhoneNumber;
  final String verificationId;

  const ChangePhoneVerificationExtra({
    required this.currentPhoneNumber,
    required this.newPhoneNumber,
    required this.verificationId,
  });
}

class ChangePhoneSetupScreen extends StatefulWidget {
  final String newPhoneNumber;

  const ChangePhoneSetupScreen({
    super.key,
    required this.newPhoneNumber,
  });

  @override
  State<ChangePhoneSetupScreen> createState() => _ChangePhoneSetupScreenState();
}

class _ChangePhoneSetupScreenState extends State<ChangePhoneSetupScreen> {
  late String currentPhoneNumber;
  late String newPhoneNumber;

  @override
  void initState() {
    super.initState();
    newPhoneNumber = widget.newPhoneNumber;
    
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      currentPhoneNumber = authState.user.phoneNumber ?? '';
    }
  }

  void _handleSendCode() {
    final phoneVerificationCubit = context.read<PhoneVerificationCubit>();
    phoneVerificationCubit.updatePhoneNumber(newPhoneNumber);
  }

  void _handleCancel() {
    final phoneVerificationCubit = context.read<PhoneVerificationCubit>();
    phoneVerificationCubit.cancelPhoneNumberChange();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
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
              Routes.changePhoneVerification,
              extra: ChangePhoneVerificationExtra(
                currentPhoneNumber: currentPhoneNumber,
                newPhoneNumber: state.phoneNumber,
                verificationId: state.verificationId,
              ),
            );
          case PhoneVerificationAutoCompleted():
            context.read<AuthSessionCubit>().checkAuthStatus();
            CustomToast.show(
              context,
              message: 'Phone number changed successfully!',
              isSuccess: true,
            );
            context.pop();
            context.pop();
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
                      minHeight: screenHeight - 200,
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
                            Icons.phone_android,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Change Phone Number',
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
                            'We need to verify your new phone number before the change takes effect.',
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
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Number',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentPhoneNumber,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Icon(
                                        Icons.arrow_downward,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
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
                                          'New Number',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          newPhoneNumber,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
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
                                  'We\'ll send a verification code to your new number via SMS.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
                          builder: (context, state) {
                            final isLoading = state is PhoneVerificationLoading;
                            
                            return SizedBox(
                              width: double.infinity,
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
                                        'Send Verification Code',
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
}