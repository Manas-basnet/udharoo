import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                size: 20,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          BlocBuilder<AuthSessionCubit, AuthSessionState>(
            builder: (context, state) {
              final isLoading = state is AuthSessionLoading;
              
              return FilledButton(
                onPressed: isLoading 
                    ? null 
                    : () {
                        context.read<AuthSessionCubit>().signOut();
                        Navigator.of(dialogContext).pop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign Out'),
              );
            },
          ),
        ],
      ),
    );
  }
}