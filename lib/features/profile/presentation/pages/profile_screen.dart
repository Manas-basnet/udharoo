import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/log_out_dialog.dart';
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.pushNamed('editProfile');
                          },
                          icon: const Icon(Icons.edit_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated) {
                          return Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: state.user.photoURL != null
                                    ? ClipRoundedRectangle(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          state.user.photoURL!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          _getInitial(state.user.displayName, state.user.email),
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.user.displayName ?? state.user.email ?? 'User',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (state.user.email != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  state.user.email!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                              if (state.user.phoneNumber != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      state.user.phoneNumber!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (state.user.phoneVerified)
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.green,
                                      )
                                    else
                                      Icon(
                                        Icons.warning_outlined,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                  ],
                                ),
                              ],
                              if (!state.user.phoneVerified && state.user.phoneNumber == null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_outlined,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Phone not verified',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated && !state.user.phoneVerified) {
                          return Column(
                            children: [
                              _ProfileSection(
                                title: 'Account Security',
                                items: [
                                  _ProfileItem(
                                    icon: Icons.verified_outlined,
                                    title: 'Verify Phone Number',
                                    subtitle: 'Secure your account and enable all features',
                                    onTap: () {
                                      context.pushNamed('phoneSetup');
                                    },
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated && !state.user.emailVerified) {
                          return Column(
                            children: [
                              _ProfileSection(
                                title: 'Email Verification',
                                items: [
                                  _ProfileItem(
                                    icon: Icons.email_outlined,
                                    title: 'Verify Email',
                                    subtitle: 'Verify your email address',
                                    onTap: () {
                                      context.read<AuthCubit>().sendEmailVerification();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Verification email sent!'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    },
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Optional',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    _ProfileSection(
                      title: 'Preferences',
                      items: [
                        BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) {
                            return _ProfileItem(
                              icon: themeState.isDarkMode 
                                  ? Icons.dark_mode_outlined 
                                  : Icons.light_mode_outlined,
                              title: 'Theme',
                              subtitle: themeState.isDarkMode ? 'Dark mode' : 'Light mode',
                              onTap: () {
                                context.read<ThemeCubit>().toggleTheme();
                              },
                              trailing: Switch(
                                value: themeState.isDarkMode,
                                onChanged: (value) {
                                  context.read<ThemeCubit>().setDarkMode(value);
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                        _ProfileItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage your notifications',
                          onTap: () {},
                        ),
                        _ProfileItem(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          subtitle: 'English',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ProfileSection(
                      title: 'Data & Privacy',
                      items: [
                        _ProfileItem(
                          icon: Icons.download_outlined,
                          title: 'Export Data',
                          subtitle: 'Download your data',
                          onTap: () {},
                        ),
                        _ProfileItem(
                          icon: Icons.delete_outline,
                          title: 'Clear Cache',
                          subtitle: 'Free up storage space',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ProfileSection(
                      title: 'Support',
                      items: [
                        _ProfileItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help with the app',
                          onTap: () {},
                        ),
                        _ProfileItem(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App version and info',
                          onTap: () {},
                        ),
                        _ProfileItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => LogoutDialog.show(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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


}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class ClipRoundedRectangle extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const ClipRoundedRectangle({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}