import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/log_out_dialog.dart';

import '../../../../core/theme/theme_cubit/theme_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: state is AuthAuthenticated && state.user.photoURL != null
                      ? NetworkImage(state.user.photoURL!)
                      : null,
                  child: state is AuthAuthenticated && state.user.photoURL == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                if (state is AuthAuthenticated) ...[
                  Text(
                    state.user.displayName ?? state.user.email ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.user.email != null)
                    Text(
                      state.user.email!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.user.emailVerified ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.user.emailVerified ? 'Verified' : 'Not Verified',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (state is AuthAuthenticated && !state.user.emailVerified) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Verify Email'),
                      subtitle: const Text('Tap to send verification email'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.read<AuthCubit>().sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Profile'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.security),
                    title: Text('Change Password'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notification Settings'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => LogoutDialog.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkmode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: isDarkmode,
                  onChanged: (value) {
                    setState(() {
                      isDarkmode = value;
                      context.read<ThemeCubit>().setDarkMode(value);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('English'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.storage),
                title: Text('Clear Cache'),
                subtitle: Text('Free up storage space'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                subtitle: Text('App version and info'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => LogoutDialog.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}