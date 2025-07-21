import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:udharoo/features/profile/presentation/pages/phone_verification_screen.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class PhoneSetupScreen extends StatefulWidget {
  final bool isRequired;

  const PhoneSetupScreen({
    super.key,
    this.isRequired = false,
  });

  @override
  State<PhoneSetupScreen> createState() => _PhoneSetupScreenState();
}

class _PhoneSetupScreenState extends State<PhoneSetupScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.isRequired
          ? null
          : AppBar(
              title: const Text('Add Phone Number'),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
            ),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            setState(() => _isLoading = false);
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is PhoneVerificationSent) {
            setState(() => _isLoading = false);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhoneVerificationScreen(
                  phoneNumber: state.phoneNumber,
                  verificationId: state.verificationId,
                ),
              ),
            );
          }
        },
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
                      Icons.phone,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    widget.isRequired ? 'Phone Number Required' : 'Add Phone Number',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    widget.isRequired
                        ? 'To use Udharoo, you need to verify your phone number. This helps us keep transactions secure and enables QR code functionality.'
                        : 'Add your phone number to enable all features of Udharoo including QR code transactions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (widget.isRequired) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'App functionality is limited until phone verification is complete.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+977 98xxxxxxxx',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Phone number is required';
                        }
                        if (value!.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _sendVerification,
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
                              'Send Verification Code',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  if (!widget.isRequired) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Skip for now'),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendVerification() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final phoneNumber = _phoneController.text.trim();
    
    final phoneExists = await context.read<ProfileCubit>().checkPhoneExists(phoneNumber);
    
    if (phoneExists) {
      setState(() => _isLoading = false);
      CustomToast.show(
        context,
        message: 'This phone number is already registered with another account.',
        isSuccess: false,
      );
      return;
    }
    
    context.read<ProfileCubit>().sendPhoneVerification(phoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}