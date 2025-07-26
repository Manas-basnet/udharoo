import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/reject_transaction_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';

Future<void> initTransactions(GetIt sl) async {
  // Use cases
  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => VerifyTransactionUseCase(sl()));
  sl.registerLazySingleton(() => CompleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => RejectTransactionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDatasource: sl(),
      networkInfo: sl(),
    ),
  );

  // Datasource
  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(
      firestore: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => TransactionCubit(
      createTransactionUseCase: sl(),
      getTransactionsUseCase: sl(),
      verifyTransactionUseCase: sl(),
      completeTransactionUseCase: sl(),
      rejectTransactionUseCase: sl(),
    ),
  );
}