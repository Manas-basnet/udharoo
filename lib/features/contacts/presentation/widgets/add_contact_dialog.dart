import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ContactCubit, ContactState>(
      listener: (context, state) {
        if (state.hasFoundUser) {
          _addContactToList(state.foundUser!);
        } else if (state.hasSuccess) {
          CustomToast.show(context, message: state.successMessage!, isSuccess: true);
          Navigator.of(context).pop();
        } else if (state.hasError) {
          CustomToast.show(context, message: state.errorMessage!, isSuccess: false);
        }
      },
      builder: (context, state) {
        return AlertDialog(
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
                    prefixIcon: state.isLookingUpUser
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.phone, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: state.hasError && !state.hasFoundUser ? state.errorMessage : null,
                    errorMaxLines: 2
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
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
                    if (state.hasError || state.hasFoundUser) {
                      context.read<ContactCubit>().clearError();
                      context.read<ContactCubit>().clearFoundUser();
                    }
                  },
                ),
                
                if (state.hasFoundUser) ...[
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
                                state.foundUser!.displayName ?? state.foundUser!.fullName ?? 'Unknown',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.green.shade600,
                                ),
                              ),
                              if (state.foundUser!.email != null)
                                Text(
                                  state.foundUser!.email!,
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
              onPressed: state.isAdding || state.isLookingUpUser 
                  ? null 
                  : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: (state.isAdding || state.isLookingUpUser)
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            FilledButton(
              onPressed: state.isAdding || state.isLookingUpUser 
                  ? null 
                  : _handleAddContact,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: state.isAdding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Contact'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAddContact() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+') ? phone : '+977$phone';
    
    context.read<ContactCubit>().lookupUserByPhone(formattedPhone);
  }

  void _addContactToList(AuthUser user) {
    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+') ? phone : '+977$phone';
    
    context.read<ContactCubit>().addContact(
      contactUserId: user.uid,
      name: user.displayName ?? user.fullName ?? '',
      phoneNumber: formattedPhone,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}