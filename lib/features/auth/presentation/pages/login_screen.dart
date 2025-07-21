import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _selectedCountryCode = '+977';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+977', 'country': 'Nepal', 'flag': '🇳🇵'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Udharoo',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Digital Ledger',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _isSignUp ? 'Create Account' : 'Welcome Back',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUp
                                      ? 'Sign up to get started with your digital ledger'
                                      : 'Sign in to manage your loans and borrows',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            Container(
                              height: 56,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: state is AuthLoading
                                      ? null
                                      : () {
                                          context.read<AuthCubit>().signInWithGoogle();
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            
                            const SizedBox(height: 24),
                            
                            if (!_isSignUp) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  labelColor: theme.colorScheme.primary,
                                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                                  indicator: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  tabs: const [
                                    Tab(text: 'Email'),
                                    Tab(text: 'Phone'),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              SizedBox(
                                height: 200,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildEmailForm(theme, state),
                                    _buildPhoneForm(theme, state),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _buildEmailForm(theme, state),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            Center(
                              child: TextButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                        });
                                        _emailFormKey.currentState?.reset();
                                        _phoneFormKey.currentState?.reset();
                                        _emailController.clear();
                                        _passwordController.clear();
                                        _phoneController.clear();
                                      },
                                child: RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodyMedium?.copyWith(
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
                      
                      const SizedBox(height: 40),
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

  Widget _buildEmailForm(ThemeData theme, AuthState state) {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
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
          if (!_isSignUp) ...[
            const SizedBox(height: 16),
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
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: state is AuthLoading
                  ? null
                  : () {
                      if (_emailFormKey.currentState?.validate() ?? false) {
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
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: state is AuthLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(ThemeData theme, AuthState state) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country['flag']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                country['code']!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter phone number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  enabled: state is! AuthLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password is required';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: state is AuthLoading
                  ? null
                  : () {
                      if (_phoneFormKey.currentState?.validate() ?? false) {
                        final fullPhoneNumber = 
                            '$_selectedCountryCode${_phoneController.text.trim()}';
                        context.read<AuthCubit>().signInWithPhone(
                          fullPhoneNumber,
                          _passwordController.text,
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
              child: state is AuthLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      'Sign In with Phone',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
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
                borderRadius: BorderRadius.circular(8),
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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}