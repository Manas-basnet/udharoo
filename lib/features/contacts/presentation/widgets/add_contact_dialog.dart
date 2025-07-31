import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  bool _isSearching = false;
  AuthUser? _foundUser;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ContactCubit, ContactState>(
      listener: (context, state) {
        if (state is ContactAddSuccess) {
          CustomToast.show(context, message: 'Contact added successfully', isSuccess: true);
          Navigator.of(context).pop();
        } else if (state is ContactError) {
          CustomToast.show(context, message: state.message, isSuccess: false);
        }
      },
      child: AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Contact',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '98XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchUser,
                        ),
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
                onChanged: (_) {
                  setState(() {
                    _foundUser = null;
                  });
                },
              ),
              
              if (_foundUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Found',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              _foundUser!.displayName ?? _foundUser!.fullName ?? 'Unknown',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade600,
                              ),
                            ),
                            if (_foundUser!.email != null)
                              Text(
                                _foundUser!.email!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          BlocBuilder<ContactCubit, ContactState>(
            builder: (context, state) {
              final isLoading = state is ContactAdding;
              
              return FilledButton(
                onPressed: (isLoading || _foundUser == null) ? null : _addContact,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Contact'),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _searchUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final formattedPhone = phone.startsWith('+') ? phone : '+977$phone';
      
      // This would need to be injected properly
      // For now, we'll simulate the search
      await Future.delayed(const Duration(seconds: 1));
      
      // You would call the actual use case here
      // final result = await getUserByPhoneUseCase(formattedPhone);
      
      setState(() {
        // Simulate found user - replace with actual logic
        _foundUser = AuthUser(
          uid: 'test_uid',
          displayName: 'Test User',
          phoneNumber: formattedPhone,
          email: 'test@example.com',
          emailVerified: true,
          phoneVerified: true,
          isProfileComplete: true,
        );
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        CustomToast.show(context, message: 'User not found', isSuccess: false);
      }
    }
  }

  void _addContact() {
    if (_foundUser == null) return;

    context.read<ContactCubit>().addContact(
      contactUserId: _foundUser!.uid,
      name: _foundUser!.displayName ?? _foundUser!.fullName ?? '',
      phoneNumber: _foundUser!.phoneNumber ?? '',
      email: _foundUser!.email,
      photoUrl: _foundUser!.photoURL,
    );
  }
}