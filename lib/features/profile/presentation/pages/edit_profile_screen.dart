import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/router_config.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/features/profile/presentation/widgets/password_setup_dialog.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCountryCode = '+977';
  bool _isUpdatingPhone = false;
  bool _isLinkingGoogle = false;
  bool _isLinkingPassword = false;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+977', 'country': 'Nepal', 'flag': '🇳🇵'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _displayNameController.text = user.displayName ?? '';
      
      if (user.phoneNumber != null) {
        final phone = user.phoneNumber!;
        final countryCode = _extractCountryCode(phone);
        if (countryCode != null) {
          _selectedCountryCode = countryCode;
          _phoneController.text = phone.substring(countryCode.length);
        } else {
          _phoneController.text = phone;
        }
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

  String _getInitial(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    
    return 'U';
  }

  bool _hasGoogleProvider(AuthUser user) {
    return user.hasGoogleProvider;
  }

  bool _hasPasswordProvider(AuthUser user) {
    return user.hasEmailProvider;
  }

  void _showPasswordSetupDialog() {
    PasswordSetupDialog.show(
      context,
      onSetupPassword: (password) {
        setState(() {
          _isLinkingPassword = true;
        });
        context.read<AuthCubit>().linkPassword(password);
        Navigator.of(context).pop();
      },
      isLoading: _isLinkingPassword,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state is PhoneVerificationLoading;
              
              return TextButton(
                onPressed: isLoading ? null : _saveChanges,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: isLoading 
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
            setState(() {
              _isUpdatingPhone = false;
              _isLinkingGoogle = false;
              _isLinkingPassword = false;
            });
          } else if (state is PhoneCodeSent) {
            context.push(
              Routes.phoneVerification,
              extra: PhoneVerificationExtra(
                phoneNumber: state.phoneNumber,
                verificationId: state.verificationId,
              ),
            );
          } else if (state is PhoneVerificationCompleted || state is AuthAuthenticated) {
            if (_isUpdatingPhone) {
              CustomToast.show(
                context,
                message: 'Phone number updated successfully!',
                isSuccess: true,
              );
              setState(() {
                _isUpdatingPhone = false;
              });
              context.pop();
            } else if (_isLinkingGoogle) {
              CustomToast.show(
                context,
                message: 'Google account linked successfully!',
                isSuccess: true,
              );
              setState(() {
                _isLinkingGoogle = false;
              });
            } else if (_isLinkingPassword) {
              CustomToast.show(
                context,
                message: 'Password authentication linked successfully!',
                isSuccess: true,
              );
              setState(() {
                _isLinkingPassword = false;
              });
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: state.user.photoURL != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: Image.network(
                                            state.user.photoURL!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _getInitial(state.user.displayName, state.user.email),
                                            style: theme.textTheme.headlineLarge?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Text(
                            'Basic Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Enter your display name',
                              prefixIcon: const Icon(Icons.person_outline),
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
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Display name cannot be empty';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: state.user.email,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              suffixIcon: const Icon(Icons.lock_outline),
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
                              filled: true,
                              fillColor: theme.colorScheme.surface.withOpacity(0.5),
                            ),
                            enabled: false,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phone Number',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (state.user.phoneVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
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
                                    labelText: 'Phone Number',
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
                                ),
                              ),
                            ],
                          ),
                          
                          if (!state.user.phoneVerified || 
                              (state.user.phoneNumber != null && 
                               '$_selectedCountryCode${_phoneController.text.trim()}' != state.user.phoneNumber)) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      state.user.phoneNumber == null
                                          ? 'Phone number verification is required to access all features.'
                                          : 'Changing your phone number will require verification.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          Text(
                            'Linked Accounts',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Container(
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Google Account',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _hasGoogleProvider(state.user) 
                                                ? 'Linked to ${state.user.email}'
                                                : 'Not linked',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_hasGoogleProvider(state.user))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Linked',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: _isLinkingGoogle 
                                              ? null 
                                              : () {
                                                  setState(() {
                                                    _isLinkingGoogle = true;
                                                  });
                                                  context.read<AuthCubit>().linkGoogleAccount();
                                                },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.primary,
                                            side: BorderSide(
                                              color: theme.colorScheme.primary,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isLinkingGoogle
                                              ? SizedBox(
                                                  height: 12,
                                                  width: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                )
                                              : Text(
                                                  'Link',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                  ],
                                ),
                                
                                Divider(
                                  height: 24,
                                  thickness: 0.5,
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                ),
                                
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Password',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _hasPasswordProvider(state.user)
                                                ? 'Sign in with email or phone + password'
                                                : 'Not linked',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if(_hasPasswordProvider(state.user))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Linked',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: _isLinkingPassword 
                                              ? null 
                                              : _showPasswordSetupDialog,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.primary,
                                            side: BorderSide(
                                              color: theme.colorScheme.primary,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isLinkingPassword
                                              ? SizedBox(
                                                  height: 12,
                                                  width: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                )
                                              : Text(
                                                  'Link',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                  ],
                                ),
                                
                                if (state.user.phoneVerified) ...[
                                  Divider(
                                    height: 24,
                                    thickness: 0.5,
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                  
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.phone,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Phone Number',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              state.user.phoneNumber ?? 'Not provided',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Verified',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final newPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      
      if (user.phoneNumber != newPhoneNumber) {
        setState(() {
          _isUpdatingPhone = true;
        });
        
        if (user.phoneNumber == null) {
          context.read<AuthCubit>().linkPhoneNumber(newPhoneNumber);
        } else {
          context.read<AuthCubit>().updatePhoneNumber(newPhoneNumber);
        }
      } else {
        CustomToast.show(
          context,
          message: 'Profile updated successfully!',
          isSuccess: true,
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}