import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/widgets/add_contact_dialog.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/bloc/multi_select_mode/multi_select_mode_cubit.dart';
import 'package:udharoo/shared/presentation/bloc/shorebird_update/shorebird_update_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/quick_transaction_dialog.dart';
import 'package:udharoo/shared/presentation/widgets/shorebird_update_bottomsheet.dart';
import 'package:udharoo/shared/presentation/widgets/expandable_fab.dart';

class ScaffoldWithBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<ScaffoldWithBottomNavBar> {
  final GlobalKey<ExpandableFABState> _fabKey = GlobalKey<ExpandableFABState>();
  bool _isFABExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final currentPath = GoRouterState.of(context).uri.path;
    final shouldHideBottomNavForRoute = 
      currentPath == Routes.transactionForm || 
      currentPath == Routes.transactionDetail ||
      currentPath == Routes.contactTransactionsDetail ||
      currentPath == Routes.homeTransactionDetail;

    return BlocListener<ShorebirdUpdateCubit, ShorebirdUpdateState>(
      listener: (context, state) {
        if (state.status == AppUpdateStatus.available) {
          showUpdateBottomSheet(context);
        }
      },
      child: BlocBuilder<MultiSelectModeCubit, MultiSelectModeState>(
        builder: (context, multiSelectState) {
          final shouldHideBottomNav = shouldHideBottomNavForRoute || multiSelectState.isMultiSelectMode;
          
          return Scaffold(
            body: Stack(
              children: [
                widget.navigationShell,
                if (_isFABExpanded)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeFAB,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: shouldHideBottomNav ? null : Container(
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
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            context,
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                            label: 'Home',
                            index: 0,
                            isSelected: widget.navigationShell.currentIndex == 0,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.receipt_long_outlined,
                            selectedIcon: Icons.receipt_long,
                            label: 'Transactions',
                            index: 1,
                            isSelected: widget.navigationShell.currentIndex == 1,
                          ),
                          const SizedBox(width: 56),
                          _buildNavItem(
                            context,
                            icon: Icons.people_outline,
                            selectedIcon: Icons.people,
                            label: 'Contacts',
                            index: 2,
                            isSelected: widget.navigationShell.currentIndex == 2,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.person_outline,
                            selectedIcon: Icons.person,
                            label: 'Profile',
                            index: 3,
                            isSelected: widget.navigationShell.currentIndex == 3,
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: ExpandableFAB(
                            key: _fabKey,
                            onExpandedChanged: (isExpanded) {
                              setState(() {
                                _isFABExpanded = isExpanded;
                              });
                            },
                            actions: [
                              FABAction(
                                icon: Icons.qr_code_scanner,
                                tooltip: 'Scan QR',
                                onPressed: () => context.push(Routes.qrScanner),
                              ),
                              FABAction(
                                icon: Icons.qr_code,
                                tooltip: 'My QR',
                                onPressed: () => context.push(Routes.qrGenerator),
                              ),
                              FABAction(
                                icon: Icons.trending_up,
                                tooltip: 'Lend Money',
                                onPressed: () => _showQuickTransactionDialog(context, TransactionType.lent),
                              ),
                              FABAction(
                                icon: Icons.trending_down,
                                tooltip: 'Borrow Money',
                                onPressed: () => _showQuickTransactionDialog(context, TransactionType.borrowed),
                              ),
                              FABAction(
                                icon: Icons.person_add,
                                tooltip: 'Add Contact',
                                onPressed: () => _showAddContactDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _closeFAB() {
    _fabKey.currentState?.close();
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
    final multiSelectCubit = context.read<MultiSelectModeCubit>();
    if (multiSelectCubit.state.isMultiSelectMode) {
      multiSelectCubit.exitMultiSelectMode();
    }
    
    if (_isFABExpanded) {
      _closeFAB();
    }
    
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showQuickTransactionDialog(BuildContext context, TransactionType type) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ContactCubit>()),
          BlocProvider.value(value: context.read<TransactionCubit>()),
        ],
        child: QuickTransactionDialog(preSelectedType: type),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ContactCubit>()),
        ],
        child: const AddContactDialog(),
      ),
    );
  }
}