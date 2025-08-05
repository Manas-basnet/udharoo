import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';


/// Quick transaction dialog
/// USE this widget with dialogs or any use where the [TransactionCubit] and [ContactCubit] are available
class QuickTransactionDialog extends StatefulWidget {
  final TransactionType preSelectedType;

  const QuickTransactionDialog({super.key, required this.preSelectedType});

  @override
  State<QuickTransactionDialog> createState() => _QuickTransactionDialogState();
}

class _QuickTransactionDialogState extends State<QuickTransactionDialog> {
  @override
  void initState() {
    super.initState();
    // Load contacts when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactCubit>().loadContacts();
    });
  }

  _navigateToTransactionForm({Contact? contact}) {
    Navigator.of(context).pop();
    context.go(
      Routes.transactionForm, 
      extra: TransactionFormExtra(
        initialTransactionType: widget.preSelectedType,
        prefilledContact: contact,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Transaction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        TransactionDisplayHelper.getTransactionAction(
                          widget.preSelectedType,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content
            BlocBuilder<ContactCubit, ContactState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load contacts',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final recentContacts = state.contacts.take(5).toList();

                if (recentContacts.isEmpty) {
                  return Column(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No contacts yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add contacts to use quick transactions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a recent contact:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentContactsList(recentContacts, theme),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _navigateToTransactionForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('More options'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContactsList(List<Contact> contacts, ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: contacts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactItem(contact, theme);
        },
      ),
    );
  }

  Widget _buildContactItem(Contact contact, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTransactionForm(contact: contact),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      contact.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.preSelectedType) {
      case TransactionType.lent:
        return Colors.green;
      case TransactionType.borrowed:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.preSelectedType) {
      case TransactionType.lent:
        return Icons.trending_up;
      case TransactionType.borrowed:
        return Icons.trending_down;
    }
  }
}
