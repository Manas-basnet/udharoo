import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/widgets/add_contact_dialog.dart';
import 'package:udharoo/features/home/presentation/widgets/home_transaction_item.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/quick_transaction_dialog.dart';
import 'package:udharoo/shared/utils/transaction_display_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              
              BlocBuilder<TransactionCubit, TransactionState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _buildNetBalanceCard(state, theme),
                      _buildQuickActions(context, theme),
                      _buildRecentTransactions(context, state, theme),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<AuthSessionCubit, AuthSessionState>(
                builder: (context, state) {
                  final userName = state is AuthSessionAuthenticated 
                      ? state.user.displayName?.split(' ').first ?? 'User'
                      : 'User';
                  return Text(
                    'Hello, $userName',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back to Udharoo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              final pendingCount = state.pendingTransactions.length;
              
              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          pendingCount > 99 ? '99+' : pendingCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(TransactionState state, ThemeData theme) {
    final netBalance = state.netActiveBalance;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Net Balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${TransactionDisplayHelper.formatAmount(netBalance.abs())}',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: netBalance >= 0 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              TransactionDisplayHelper.getBalanceLabel(netBalance),
              style: theme.textTheme.bodySmall?.copyWith(
                color: netBalance >= 0 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  Icons.trending_up_rounded,
                  'They owe you', 
                  state.totalActiveTheyOweYou, 
                  Colors.green,
                  theme,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildBalanceItem(
                  Icons.trending_down_rounded,
                  'You owe them', 
                  state.totalActiveYouOweThem, 
                  Colors.orange,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(IconData icon, String label, double amount, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '₹${TransactionDisplayHelper.formatAmount(amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go(Routes.transactions),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.trending_up,
                  title: 'I gave money',
                  subtitle: 'They owe me',
                  color: Colors.green,
                  onTap: () => _showQuickTransactionDialog(context, TransactionType.lent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.trending_down,
                  title: 'I received money',
                  subtitle: 'I owe them',
                  color: Colors.orange,
                  onTap: () => _showQuickTransactionDialog(context, TransactionType.borrowed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  subtitle: 'Quick setup',
                  color: Colors.blue,
                  onTap: () => context.push(Routes.qrScanner),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add,
                  title: 'Add Contact',
                  subtitle: 'New person',
                  color: Colors.purple,
                  onTap: () => _showAddContactDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, TransactionState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go(Routes.transactions),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransactionsList(context, state, theme),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, TransactionState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (state.hasError && !state.hasTransactions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load transactions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No transactions yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your first transaction using quick actions above',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    final recentTransactions = state.transactions.take(5).toList();
    
    return Column(
      children: [
        ...recentTransactions.map((transaction) => 
          HomeTransactionItem(transaction: transaction)
        ),
        if (state.transactions.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.transactions),
              child: Text(
                'View ${state.transactions.length - 5} more transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}