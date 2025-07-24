import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: navigationShell.currentIndex == 0,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Transactions',
                  index: 1,
                  isSelected: navigationShell.currentIndex == 1,
                ),
                _buildScannerButton(context),
                _buildNavItem(
                  context,
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Contacts',
                  index: 2,
                  isSelected: navigationShell.currentIndex == 2,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  index: 3,
                  isSelected: navigationShell.currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showScannerBottomSheet(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: colorScheme.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onItemTapped(index, context),
        child: Container(
          width: 64,
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 32,
                decoration: isSelected
                    ? BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showScannerBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.qrScanner);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.qr_code,
                    label: 'Generate QR',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.qrGenerator);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.trending_up,
                    label: 'Lend Money',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.transactionForm);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.trending_down,
                    label: 'Borrow Money',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.transactionForm);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}