import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load transactions when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Lent'),
            Tab(text: 'Borrowed'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
      ),
      body: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, state) {
          switch (state) {
            case TransactionCreated():
              CustomToast.show(
                context,
                message: 'Transaction created successfully',
                isSuccess: true,
              );
              context.read<TransactionCubit>().resetActionState();
              break;
            case TransactionActionSuccess():
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: true,
              );
              context.read<TransactionCubit>().resetActionState();
              break;
            case TransactionError():
              CustomToast.show(
                context,
                message: state.message,
                isSuccess: false,
              );
              break;
            default:
              break;
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsList(context, state, TransactionFilter.all),
              _buildTransactionsList(context, state, TransactionFilter.lent),
              _buildTransactionsList(
                context,
                state,
                TransactionFilter.borrowed,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTransactionDialog(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    TransactionState state,
    TransactionFilter filter,
  ) {
    switch (state) {
      case TransactionLoading():
        return const Center(child: CircularProgressIndicator());

      case TransactionLoaded():
        final transactions = _getFilteredTransactions(state, filter);

        if (transactions.isEmpty) {
          return _buildEmptyState(context, filter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TransactionCubit>().loadTransactions();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionListItem(transaction: transactions[index]);
            },
          ),
        );

      case TransactionError():
        return _buildErrorState(context, state.message);

      default:
        return _buildEmptyState(context, filter);
    }
  }

  List<Transaction> _getFilteredTransactions(
    TransactionLoaded state,
    TransactionFilter filter,
  ) {
    switch (filter) {
      case TransactionFilter.all:
        return state.transactions;
      case TransactionFilter.lent:
        return state.lentTransactions;
      case TransactionFilter.borrowed:
        return state.borrowedTransactions;
    }
  }

  Widget _buildEmptyState(BuildContext context, TransactionFilter filter) {
    final theme = Theme.of(context);

    String message;
    IconData icon;

    switch (filter) {
      case TransactionFilter.all:
        message = 'No transactions yet';
        icon = Icons.receipt_long;
        break;
      case TransactionFilter.lent:
        message = 'No money lent yet';
        icon = Icons.arrow_upward;
        break;
      case TransactionFilter.borrowed:
        message = 'No money borrowed yet';
        icon = Icons.arrow_downward;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first transaction',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<TransactionCubit>().loadTransactions();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCreateTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TransactionCubit>(),
        child: _CreateTransactionDialog(),
      ),
    );
  }
}

enum TransactionFilter { all, lent, borrowed }

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

                // Other Party UID (for now, we'll use a simple text field)
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
