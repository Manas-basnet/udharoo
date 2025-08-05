part of 'transaction_cubit.dart';

class TransactionState extends Equatable {
  final List<Transaction> transactions;
  final List<Transaction> lentTransactions;
  final List<Transaction> borrowedTransactions;
  final List<Transaction> activeLentTransactions;
  final List<Transaction> activeBorrowedTransactions;
  final List<Transaction> pendingTransactions;
  final List<Transaction> completedTransactions;
  
  final bool isInitialLoading;
  final bool isCreatingTransaction;
  final Set<String> processingTransactionIds;
  
  final String? errorMessage;
  final String? successMessage;
  final bool isInitialized;

  const TransactionState({
    this.transactions = const [],
    this.lentTransactions = const [],
    this.borrowedTransactions = const [],
    this.activeLentTransactions = const [],
    this.activeBorrowedTransactions = const [],
    this.pendingTransactions = const [],
    this.completedTransactions = const [],
    this.isInitialLoading = false,
    this.isCreatingTransaction = false,
    this.processingTransactionIds = const {},
    this.errorMessage,
    this.successMessage,
    this.isInitialized = false,
  });

  factory TransactionState.initial() => const TransactionState();

  TransactionState copyWith({
    List<Transaction>? transactions,
    List<Transaction>? lentTransactions,
    List<Transaction>? borrowedTransactions,
    List<Transaction>? activeLentTransactions,
    List<Transaction>? activeBorrowedTransactions,
    List<Transaction>? pendingTransactions,
    List<Transaction>? completedTransactions,
    bool? isInitialLoading,
    bool? isCreatingTransaction,
    Set<String>? processingTransactionIds,
    String? errorMessage,
    String? successMessage,
    bool? isInitialized,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      lentTransactions: lentTransactions ?? this.lentTransactions,
      borrowedTransactions: borrowedTransactions ?? this.borrowedTransactions,
      activeLentTransactions: activeLentTransactions ?? this.activeLentTransactions,
      activeBorrowedTransactions: activeBorrowedTransactions ?? this.activeBorrowedTransactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      completedTransactions: completedTransactions ?? this.completedTransactions,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isCreatingTransaction: isCreatingTransaction ?? this.isCreatingTransaction,
      processingTransactionIds: processingTransactionIds ?? this.processingTransactionIds,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  TransactionState clearMessages() {
    return TransactionState(
      transactions: transactions,
      lentTransactions: lentTransactions,
      borrowedTransactions: borrowedTransactions,
      activeLentTransactions: activeLentTransactions,
      activeBorrowedTransactions: activeBorrowedTransactions,
      pendingTransactions: pendingTransactions,
      completedTransactions: completedTransactions,
      isInitialLoading: isInitialLoading,
      isCreatingTransaction: isCreatingTransaction,
      processingTransactionIds: processingTransactionIds,
      errorMessage: null,
      successMessage: null,
      isInitialized: isInitialized,
    );
  }

  TransactionState clearError() {
    return TransactionState(
      transactions: transactions,
      lentTransactions: lentTransactions,
      borrowedTransactions: borrowedTransactions,
      activeLentTransactions: activeLentTransactions,
      activeBorrowedTransactions: activeBorrowedTransactions,
      pendingTransactions: pendingTransactions,
      completedTransactions: completedTransactions,
      isInitialLoading: isInitialLoading,
      isCreatingTransaction: isCreatingTransaction,
      processingTransactionIds: processingTransactionIds,
      errorMessage: null,
      successMessage: successMessage,
      isInitialized: isInitialized,
    );
  }

  TransactionState clearSuccess() {
    return TransactionState(
      transactions: transactions,
      lentTransactions: lentTransactions,
      borrowedTransactions: borrowedTransactions,
      activeLentTransactions: activeLentTransactions,
      activeBorrowedTransactions: activeBorrowedTransactions,
      pendingTransactions: pendingTransactions,
      completedTransactions: completedTransactions,
      isInitialLoading: isInitialLoading,
      isCreatingTransaction: isCreatingTransaction,
      processingTransactionIds: processingTransactionIds,
      errorMessage: errorMessage,
      successMessage: null,
      isInitialized: isInitialized,
    );
  }

  bool isTransactionProcessing(String transactionId) {
    return processingTransactionIds.contains(transactionId);
  }

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
  bool get hasTransactions => transactions.isNotEmpty;
  bool get isLoading => isInitialLoading && !isInitialized;
  bool get isEmpty => transactions.isEmpty && isInitialized;

  double get totalActiveTheyOweYou => activeLentTransactions.fold(0.0, (sum, t) => sum + t.amount);
  double get totalActiveYouOweThem => activeBorrowedTransactions.fold(0.0, (sum, t) => sum + t.amount);
  double get netActiveBalance => totalActiveTheyOweYou - totalActiveYouOweThem;

  @override
  List<Object?> get props => [
        transactions,
        lentTransactions,
        borrowedTransactions,
        activeLentTransactions,
        activeBorrowedTransactions,
        pendingTransactions,
        completedTransactions,
        isInitialLoading,
        isCreatingTransaction,
        processingTransactionIds,
        errorMessage,
        successMessage,
        isInitialized,
      ];
}