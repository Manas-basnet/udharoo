import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/datasources/local/transaction_local_datasource_impl.dart';
import 'package:udharoo/features/transactions/data/datasources/remote/transaction_remote_datasource_impl.dart';
import 'package:udharoo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/verify_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/complete_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_contacts_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/generate_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/parse_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transaction_stats_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';

Future<void> initTransaction(GetIt sl) async {
  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionByIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => VerifyTransactionUseCase(sl()));
  sl.registerLazySingleton(() => CompleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionContactsUseCase(sl()));
  sl.registerLazySingleton(() => GetContactTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQRUseCase(sl()));
  sl.registerLazySingleton(() => ParseQRUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionStatsUseCase(sl()));

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<TransactionLocalDatasource>(
    () => TransactionLocalDatasourceImpl(),
  );

  sl.registerFactory(
    () => TransactionCubit(
      createTransactionUseCase: sl(),
      getTransactionsUseCase: sl(),
      getTransactionByIdUseCase: sl(),
      updateTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
      verifyTransactionUseCase: sl(),
      completeTransactionUseCase: sl(),
      getTransactionContactsUseCase: sl(),
      getContactTransactionsUseCase: sl(),
      generateQRUseCase: sl(),
      parseQRUseCase: sl(),
      getTransactionStatsUseCase: sl(),
    ),
  );
}