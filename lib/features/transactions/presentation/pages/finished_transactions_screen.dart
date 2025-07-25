import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/enums/transaction_status.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_list/transaction_list_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_summary_widget.dart';
import 'package:udharoo/features/transactions/presentation/utils/transaction_utils.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class FinishedTransactionsScreen extends StatefulWidget {
  const FinishedTransactionsScreen({super.key});

  @override
  State<FinishedTransactionsScreen> createState() => _FinishedTransactionsScreenState();
}

class _FinishedTransactionsScreenState extends State<FinishedTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  // ignore: unused_field
  List<Transaction> _finishedTransactions = []; //TODO: implement logic for filters
  Map<String, dynamic> _stats = {};
  
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
    context.read<TransactionListCubit>().loadTransactions(
      status: TransactionStatus.completed,
      refresh: true,
    );
  }

  void _calculateStats(List<Transaction> transactions) {
    final summary = TransactionUtils.calculateTransactionSummary(transactions);
    
    setState(() {
      _stats = {
        'totalLending': summary['totalLending'],
        'totalBorrowing': summary['totalBorrowing'],
        'netAmount': summary['netAmount'],
      };
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<TransactionListCubit>().state;
      if (state is TransactionListLoaded && state.hasMore) {
        context.read<TransactionListCubit>().loadTransactions(
          status: TransactionStatus.completed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionListCubit, TransactionListState>(
      listener: (context, state) {
        switch (state) {
          case TransactionListLoaded():
            setState(() {
              _finishedTransactions = state.transactions;
            });
            _calculateStats(state.transactions);
          case TransactionListError():
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
        body: Column(
          children: [
            if (_stats.isNotEmpty) _buildSummaryHeader(),
            Expanded(
              child: BlocBuilder<TransactionListCubit, TransactionListState>(
                builder: (context, state) {
                  if (state is TransactionListLoading && state is! TransactionListLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TransactionListLoaded) {
                    if (state.transactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTransactionsList(state.transactions, state.hasMore);
                  }

                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          TransactionSummaryWidget(
            stats: _stats,
            showNetAmount: true,
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ],
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
              context.push(Routes.transactionDetailGen(transaction.id));
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No completed transactions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Completed transactions will appear here once you mark them as finished',
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
}