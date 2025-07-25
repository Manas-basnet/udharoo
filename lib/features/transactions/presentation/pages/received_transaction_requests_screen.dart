import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/received_transaction_requests/received_transaction_requests_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ReceivedTransactionRequestsScreen extends StatefulWidget {
  const ReceivedTransactionRequestsScreen({super.key});

  @override
  State<ReceivedTransactionRequestsScreen> createState() => _ReceivedTransactionRequestsScreenState();
}

class _ReceivedTransactionRequestsScreenState extends State<ReceivedTransactionRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _loadReceivedRequests();
  }

  void _loadReceivedRequests() {
    context.read<ReceivedTransactionRequestsCubit>().loadReceivedTransactionRequests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<ReceivedTransactionRequestsCubit, ReceivedTransactionRequestsState>(
      listener: (context, state) {
        switch (state) {
          case ReceivedTransactionRequestVerified():
            CustomToast.show(
              context,
              message: 'Transaction verified successfully',
              isSuccess: true,
            );
            _loadReceivedRequests();
          case ReceivedTransactionRequestsError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Verification Requests'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: _loadReceivedRequests,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildInfoHeader(theme),
            Expanded(
              child: BlocBuilder<ReceivedTransactionRequestsCubit, ReceivedTransactionRequestsState>(
                builder: (context, state) {
                  if (state is ReceivedTransactionRequestsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ReceivedTransactionRequestsLoaded) {
                    if (state.requests.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return _buildRequestsList(state.requests);
                  }

                  return _buildEmptyState(theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transaction Verification Requests',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These transactions require your verification before they can be completed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<Transaction> requests) {
    return RefreshIndicator(
      onRefresh: () async => _loadReceivedRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final transaction = requests[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TransactionCard(
              transaction: transaction,
              onTap: () {
                context.push(Routes.transactionDetailGen(transaction.id));
              },
              onVerify: transaction.canBeVerified
                  ? () => _verifyTransaction(transaction)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No verification requests',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When someone creates a transaction that requires your verification, it will appear here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Transactions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to verify this transaction?'),
            const SizedBox(height: 16),
            Text(
              'Amount: ${transaction.formattedAmount}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'From: ${transaction.contactName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (transaction.description != null) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${transaction.description}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ReceivedTransactionRequestsCubit>().verifyTransaction(transaction.id, 'current-user-id');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}