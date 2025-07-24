import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class FinishedTransactionsScreen extends StatefulWidget {
  const FinishedTransactionsScreen({super.key});

  @override
  State<FinishedTransactionsScreen> createState() => _FinishedTransactionsScreenState();
}

class _FinishedTransactionsScreenState extends State<FinishedTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFinishedTransactions();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFinishedTransactions() {
    context.read<TransactionCubit>().getTransactions(
      status: TransactionStatus.completed,
      refresh: true,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<TransactionCubit>().state;
      if (state is TransactionsLoaded && state.hasMore) {
        context.read<TransactionCubit>().getTransactions(
          status: TransactionStatus.completed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionError():
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
          title: const Text('Completed Transactions'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: _loadFinishedTransactions,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading && state is! TransactionsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionsLoaded) {
              if (state.transactions.isEmpty) {
                return _buildEmptyState();
              }

              return _buildTransactionsList(state.transactions, state.hasMore);
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async => _loadFinishedTransactions(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= transactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final transaction = transactions[index];
          return TransactionCard(
            transaction: transaction,
            onTap: () {
              context.push('/transaction-detail', extra: transaction);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No completed transactions',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed transactions will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}