import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bottom navigation bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 65,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      // Empty space for the floating button
                      const SizedBox(width: 64),
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
          ),
          // Floating scanner button positioned above the navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 45, // Levitate above the navbar
            child: Center(
              child: _buildFloatingScannerButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingScannerButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showScannerBottomSheet(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.surface,
            width: 3,
          ),
        ),
        child: Icon(
          Icons.qr_code_scanner,
          color: colorScheme.onPrimary,
          size: 26,
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

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index, context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
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
                      // Handle QR scan
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.trending_up,
                    label: 'Lend Money',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle lend money
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.trending_down,
                    label: 'Borrow Money',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle borrow money
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.payment,
                    label: 'Record Payment',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle record payment
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
                color: theme.colorScheme.primary.withOpacity(0.1),
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