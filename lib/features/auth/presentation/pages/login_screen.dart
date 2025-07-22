import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isEmailInput = false;

  void _analyzeInput(String value) {
    setState(() {
      _isEmailInput = value.contains('@');
    });
  }

  String _getInputHint() {
    if (_isSignUp) {
      return 'Enter email address';
    }
    if (_usernameController.text.isEmpty) {
      return 'Enter email or phone number';
    }
    return _isEmailInput ? 'Email address' : 'Phone number';
  }

  String _getInputLabel() {
    if (_isSignUp) {
      return 'Email';
    }
    return _isEmailInput ? 'Email' : 'Phone';
  }

  IconData _getInputIcon() {
    if (_isSignUp) {
      return Icons.email_outlined;
    }
    return _isEmailInput ? Icons.email_outlined : Icons.phone;
  }

  TextInputType _getKeyboardType() {
    if (_isSignUp) {
      return TextInputType.emailAddress;
    }
    return TextInputType.text; // Allow both email and phone input
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      if (_isSignUp) {
        // Sign up always uses email
        context.read<AuthCubit>().signUpWithEmail(username, password);
      } else {
        // Sign in can use email or phone
        if (_isEmailInput) {
          context.read<AuthCubit>().signInWithEmail(username, password);
        } else {
          // For phone, we need to handle country code
          String phoneNumber = username;
          if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+977$phoneNumber'; // Default to Nepal
          }
          context.read<AuthCubit>().signInWithPhone(phoneNumber, password);
        }
      }
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
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo and Title
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Udharoo',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Digital Ledger',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Form Card
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
                              Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSignUp
                                    ? 'Sign up to get started'
                                    : 'Sign in to continue',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Google Sign In Button
                              Container(
                                height: 48,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: state is AuthLoading
                                        ? null
                                        : () {
                                            context.read<AuthCubit>().signInWithGoogle();
                                          },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Continue with Google',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Smart Input Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: _getInputLabel(),
                                  hintText: _getInputHint(),
                                  prefixIcon: Icon(_getInputIcon()),
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
                                keyboardType: _getKeyboardType(),
                                onChanged: _analyzeInput,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'This field is required';
                                  }
                                  if (_isSignUp) {
                                    // Sign up always requires email
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                      return 'Please enter a valid email address';
                                    }
                                  } else {
                                    // Sign in can be email or phone
                                    if (_isEmailInput) {
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                        return 'Please enter a valid email';
                                      }
                                    } else {
                                      if (value!.length < 7) {
                                        return 'Please enter a valid phone number';
                                      }
                                    }
                                  }
                                  return null;
                                },
                                enabled: state is! AuthLoading,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
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
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Password is required';
                                  }
                                  if (_isSignUp && value!.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                enabled: state is! AuthLoading,
                              ),
                              
                              if (!_isSignUp && (_isEmailInput || _usernameController.text.contains('@'))) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: state is AuthLoading
                                        ? null
                                        : () {
                                            _showForgotPasswordDialog(context);
                                          },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Sign In Button
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: state is AuthLoading ? null : _handleSignIn,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: state is AuthLoading
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          _isSignUp ? 'Create Account' : 'Sign In',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Switch Sign Up/In
                              Center(
                                child: TextButton(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isSignUp = !_isSignUp;
                                            _isEmailInput = _isSignUp; // Reset analysis based on mode
                                          });
                                          _formKey.currentState?.reset();
                                          _usernameController.clear();
                                          _passwordController.clear();
                                        },
                                  child: RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _isSignUp
                                              ? 'Already have an account? '
                                              : 'Don\'t have an account? ',
                                        ),
                                        TextSpan(
                                          text: _isSignUp ? 'Sign In' : 'Sign Up',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Reset Password',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthCubit>().sendPasswordResetEmail(email);
                Navigator.of(dialogContext).pop();
                CustomToast.show(
                  context,
                  message: 'Password reset email sent!',
                  isSuccess: true,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}