import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/auth/presentation/bloc/signin_cubit.dart';
import 'package:udharoo/features/phone_verification/presentation/bloc/phone_verification_cubit.dart';
import 'package:udharoo/features/profile/presentation/widgets/password_setup_dialog.dart';
import 'package:udharoo/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:udharoo/features/profile/presentation/widgets/change_phone_dialog.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLinkingGoogle = false;
  bool _isLinkingPassword = false;
  bool _isUpdatingDisplayName = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      final user = authState.user;
      _displayNameController.text = user.displayName ?? '';
    }
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

  void _showPasswordSetupDialog(SignInCubit signInCubit) {
    PasswordSetupDialog.show(
      context,
      onSetupPassword: (password) {
        setState(() {
          _isLinkingPassword = true;
        });
        signInCubit.linkPassword(password);
        Navigator.of(context).pop();
      },
      isLoading: _isLinkingPassword,
    );
  }

  void _showChangePasswordDialog() {
    bool isChangingPassword = false;
    ChangePasswordDialog.show(
      context,
      onChangePassword: ({required String currentPassword, required String newPassword}) async {
        isChangingPassword = true;
        final didUpdate = await context.read<AuthSessionCubit>().changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        if(didUpdate && mounted) {
          CustomToast.show(
            context,
            message: 'Password changed successfully!',
            isSuccess: true,
          );
          Navigator.of(context).pop();
        } else {
          if(!mounted) return;
          CustomToast.show(
            context,
            message: 'Failed to change password. Please try again.',
            isSuccess: false,
          );
        }
        isChangingPassword = false;
      },
      isLoading: isChangingPassword,
    );
  }

  void _showChangePhoneDialog(PhoneVerificationCubit phoneVerificationCubit) {
    ChangePhoneDialog.show(
      context,
      onChangePhone: (phoneNumber) {
        phoneVerificationCubit.startPhoneNumberChange(phoneNumber);
        Navigator.of(context).pop();
        context.push(Routes.phoneSetup, extra: {'isChanging': true});
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<SignInCubit, SignInState>(
          listener: (context, state) {
            switch (state) {
              case GoogleAccountLinked():
                CustomToast.show(
                  context,
                  message: 'Google account linked successfully!',
                  isSuccess: true,
                );
                context.read<AuthSessionCubit>().setUser(state.user);
                setState(() {
                  _isLinkingGoogle = false;
                });
              case PasswordLinked():
                CustomToast.show(
                  context,
                  message: 'Password authentication linked successfully!',
                  isSuccess: true,
                );
                context.read<AuthSessionCubit>().setUser(state.user);
                setState(() {
                  _isLinkingPassword = false;
                });
              case SignInError():
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
                setState(() {
                  _isLinkingGoogle = false;
                  _isLinkingPassword = false;
                });
              default:
                break;
            }
          },
        ),
        BlocListener<AuthSessionCubit, AuthSessionState>(
          listener: (context, state) {
            if (state is AuthSessionAuthenticated && _isUpdatingDisplayName) {
              CustomToast.show(
                context,
                message: 'Display name updated successfully!',
                isSuccess: true,
              );
              setState(() {
                _isUpdatingDisplayName = false;
              });
            } else if (state is AuthSessionError) {
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: false,
              );
              setState(() {
                _isUpdatingDisplayName = false;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            BlocBuilder<AuthSessionCubit, AuthSessionState>(
              builder: (context, state) {
                final isLoading = _isUpdatingDisplayName;
                
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<AuthSessionCubit, AuthSessionState>(
                  builder: (context, state) {
                    if (state is AuthSessionAuthenticated) {
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
                          
                          Text(
                            'Linked Accounts',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          BlocBuilder<SignInCubit, SignInState>(
                            builder: (context, signInState) {
                              final signInCubit = context.read<SignInCubit>();
                              
                              return Container(
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
                                              onPressed: (_isLinkingGoogle || signInState is SignInLoading)
                                                  ? null 
                                                  : () {
                                                      setState(() {
                                                        _isLinkingGoogle = true;
                                                      });
                                                      signInCubit.linkGoogleAccount();
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
                                              child: (_isLinkingGoogle || signInState is SignInLoading)
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
                                          Row(
                                            children: [
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
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton(
                                                  onPressed: _showChangePasswordDialog,
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
                                                  child: Text(
                                                    'Change',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  )
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          SizedBox(
                                            height: 32,
                                            child: OutlinedButton(
                                              onPressed: (_isLinkingPassword || signInState is SignInLoading)
                                                  ? null 
                                                  : () => _showPasswordSetupDialog(signInCubit),
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
                                              child: (_isLinkingPassword || signInState is SignInLoading)
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
                                    
                                    BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
                                      builder: (context, phoneState) {
                                        final phoneVerificationCubit = context.read<PhoneVerificationCubit>();
                                        
                                        return Row(
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
                                                    state.user.phoneNumber ?? 'Not linked',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (state.user.phoneVerified && state.user.phoneNumber != null)
                                              Row(
                                                children: [
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
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    height: 32,
                                                    child: OutlinedButton(
                                                      onPressed: () => _showChangePhoneDialog(phoneVerificationCubit),
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
                                                      child: Text(
                                                        'Change',
                                                        style: theme.textTheme.labelSmall?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    context.push(Routes.phoneSetup, extra: {'isChanging': true});
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
                                                  child: Text(
                                                    'Link',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
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

    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated) {
      final user = authState.user;
      final newDisplayName = _displayNameController.text.trim();
      
      bool hasDisplayNameChanged = user.displayName != newDisplayName;
      
      if (hasDisplayNameChanged) {
        setState(() {
          _isUpdatingDisplayName = true;
        });
        context.read<AuthSessionCubit>().updateDisplayName(newDisplayName);
      } else {
        CustomToast.show(
          context,
          message: 'No changes to save!',
          isSuccess: false,
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }
}