import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/reject_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/bulk_verify_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/bulk_complete_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/bulk_reject_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/bulk_delete_transactions_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_form/transaction_form_cubit.dart';

Future<void> initTransactions(GetIt sl) async {
  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => VerifyTransactionUseCase(sl()));
  sl.registerLazySingleton(() => CompleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => RejectTransactionUseCase(sl()));
  
  sl.registerLazySingleton(() => BulkVerifyTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => BulkCompleteTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => BulkRejectTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => BulkDeleteTransactionsUseCase(sl()));

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDatasource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(
      firestore: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerFactory(
    () => TransactionCubit(
      createTransactionUseCase: sl(),
      getTransactionsUseCase: sl(),
      verifyTransactionUseCase: sl(),
      completeTransactionUseCase: sl(),
      rejectTransactionUseCase: sl(),
      bulkVerifyTransactionsUseCase: sl(),
      bulkCompleteTransactionsUseCase: sl(),
      bulkRejectTransactionsUseCase: sl(),
      bulkDeleteTransactionsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TransactionFormCubit(
      getUserByPhoneUseCase: sl(),
      createTransactionUseCase: sl(),
    ),
  );
}