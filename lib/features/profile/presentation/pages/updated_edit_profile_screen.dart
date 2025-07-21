import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class UpdatedEditProfileScreen extends StatefulWidget {
  const UpdatedEditProfileScreen({super.key});

  @override
  State<UpdatedEditProfileScreen> createState() => _UpdatedEditProfileScreenState();
}

class _UpdatedEditProfileScreenState extends State<UpdatedEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadUserProfile();
  }

  void _initializeForm() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _displayNameController.text = user.displayName ?? '';
      _phoneNumberController.text = user.phoneNumber ?? '';
      _currentImageUrl = user.photoURL;
      
      _displayNameController.addListener(_onFormChanged);
      _phoneNumberController.addListener(_onFormChanged);
    }
  }

  void _loadUserProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadUserProfile(authState.user.uid);
    }
  }

  void _onFormChanged() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final hasChanges = _displayNameController.text != (user.displayName ?? '') ||
                        _phoneNumberController.text != (user.phoneNumber ?? '') ||
                        _selectedImage != null;
      
      if (hasChanges != _hasChanges) {
        setState(() => _hasChanges = hasChanges);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                setState(() => _isLoading = false);
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
              }
            },
          ),
          BlocListener<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                setState(() => _isLoading = false);
                CustomToast.show(
                  context,
                  message: state.message,
                  isSuccess: false,
                );
              } else if (state is ProfileLoaded) {
                setState(() => _isLoading = false);
                CustomToast.show(
                  context,
                  message: 'Profile updated successfully!',
                  isSuccess: true,
                );
                Navigator.pop(context);
              } else if (state is ProfileUpdating) {
                setState(() => _isLoading = true);
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePictureSection(),
                const SizedBox(height: 32),
                _buildBasicInfoSection(),
                const SizedBox(height: 32),
                _buildContactInfoSection(),
                const SizedBox(height: 32),
                if (_hasChanges) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final theme = Theme.of(context);
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _currentImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildDefaultAvatar(state.user, theme),
                                    ),
                                  )
                                : _buildDefaultAvatar(state.user, theme),
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
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    _selectedImage != null || _currentImageUrl != null
                        ? 'Change Photo'
                        : 'Add Photo',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_currentImageUrl != null || _selectedImage != null)
                  TextButton(
                    onPressed: _removeImage,
                    child: Text(
                      'Remove Photo',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  state.user.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultAvatar(user, theme) {
    return Center(
      child: Text(
        (user.displayName?.isNotEmpty == true 
            ? user.displayName![0] 
            : user.email?[0] ?? 'U').toUpperCase(),
        style: theme.textTheme.headlineLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Display name is required';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your phone number is used as a unique identifier for transactions and is required for QR code generation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _saveChanges,
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
            : Text(
                'Save Changes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _hasChanges = true;
          });
        }
      } catch (e) {
        CustomToast.show(
          context,
          message: 'Failed to pick image: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
      _hasChanges = true;
    });
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final phoneNumber = _phoneNumberController.text.trim();
    
    if (phoneNumber != (authState.user.phoneNumber ?? '')) {
      final phoneExists = await context.read<ProfileCubit>().checkPhoneExists(phoneNumber);
      if (phoneExists) {
        CustomToast.show(
          context,
          message: 'This phone number is already registered with another account.',
          isSuccess: false,
        );
        return;
      }
    }

    context.read<ProfileCubit>().updateProfile(
      uid: authState.user.uid,
      displayName: _displayNameController.text.trim(),
      phoneNumber: phoneNumber,
      profileImage: _selectedImage,
    );
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_onFormChanged);
    _phoneNumberController.removeListener(_onFormChanged);
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}