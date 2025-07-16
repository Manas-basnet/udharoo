import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isSignUp ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp
                            ? 'Sign up to get started'
                            : 'Sign in to continue',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        enabled: state is! AuthLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  if (_isSignUp) {
                                    context.read<AuthCubit>().signUpWithEmail(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                  } else {
                                    context.read<AuthCubit>().signInWithEmail(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                });
                                _formKey.currentState?.reset();
                              },
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Sign Up',
                        ),
                      ),
                      if (!_isSignUp) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  _showForgotPasswordDialog(context);
                                },
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                      if (state is AuthError) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            context.read<AuthCubit>().resetError();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
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
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthCubit>().sendPasswordResetEmail(email);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}