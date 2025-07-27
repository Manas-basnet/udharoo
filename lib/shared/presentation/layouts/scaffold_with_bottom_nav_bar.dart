import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/bloc/shorebird_update/shorebird_update_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/shorebird_update_bottomsheet.dart';

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<ShorebirdUpdateCubit, ShorebirdUpdateState>(
      listener: (context, state) {
        if (state.status == AppUpdateStatus.available) {
          showUpdateBottomSheet(context);
        }
      },
      child: Scaffold(
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
                  _buildAddButton(context, colorScheme),
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
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCreateActionBottomSheet(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.add,
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
    // Adjust index for the + button in the middle
    int actualIndex = index;
    if (index >= 2) {
      actualIndex = index + 1;
    }
    
    navigationShell.goBranch(
      actualIndex,
      initialLocation: actualIndex == navigationShell.currentIndex,
    );
  }

  void _showCreateActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CreateActionBottomSheet(),
    );
  }
}

class _CreateActionBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create New',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _CreateActionItem(
              icon: Icons.receipt_long,
              title: 'Create Transaction',
              subtitle: 'Add a new lending or borrowing record',
              onTap: () {
                Navigator.of(context).pop();
                _showCreateTransactionDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _CreateActionItem(
              icon: Icons.qr_code,
              title: 'QR Code',
              subtitle: 'Generate or scan QR code (Coming soon)',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              isEnabled: false,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => di.sl<TransactionCubit>(),
        child: _CreateTransactionDialog(),
      ),
    );
  }
}

class _CreateActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isEnabled;

  const _CreateActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled 
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isEnabled 
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isEnabled 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reuse the existing create transaction dialog from the previous implementation
class _CreateTransactionDialog extends StatefulWidget {
  @override
  State<_CreateTransactionDialog> createState() =>
      _CreateTransactionDialogState();
}

class _CreateTransactionDialogState extends State<_CreateTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherPartyNameController = TextEditingController();
  final _otherPartyUidController = TextEditingController();

  TransactionType _selectedType = TransactionType.lent;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _otherPartyNameController.dispose();
    _otherPartyUidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Transaction',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Transaction Type
                Text('Transaction Type', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TransactionType>(
                        title: const Text('Lent'),
                        subtitle: const Text('I gave money'),
                        value: TransactionType.lent,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TransactionType>(
                        title: const Text('Borrowed'),
                        subtitle: const Text('I took money'),
                        value: TransactionType.borrowed,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    prefixText: 'Rs. ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Other Party Name
                TextFormField(
                  controller: _otherPartyNameController,
                  decoration: InputDecoration(
                    labelText: _selectedType == TransactionType.lent
                        ? 'Borrower Name'
                        : 'Lender Name',
                    hintText: 'Enter name',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Other Party UID
                TextFormField(
                  controller: _otherPartyUidController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    hintText: 'Enter user ID',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'User ID is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What was this for?',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<TransactionCubit, TransactionState>(
                        builder: (context, state) {
                          final isLoading = state is TransactionCreating;

                          return FilledButton(
                            onPressed: isLoading
                                ? null
                                : _handleCreateTransaction,
                            child: isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCreateTransaction() {
    if (_formKey.currentState?.validate() ?? false) {
      final cubit = context.read<TransactionCubit>();

      cubit.createTransaction(
        amount: double.parse(_amountController.text),
        otherPartyUid: _otherPartyUidController.text.trim(),
        otherPartyName: _otherPartyNameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
      );

      Navigator.of(context).pop();
    }
  }
}