import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/data/datasources/remote/transaction_remote_datasource_impl.dart';
import 'package:udharoo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:udharoo/features/transactions/data/services/qr_service_impl.dart';
import 'package:udharoo/features/transactions/domain/datasources/local/transaction_local_datasource.dart';
import 'package:udharoo/features/transactions/domain/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';

Future<void> initTransaction(GetIt sl) async {
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  sl.registerLazySingleton<QrService>(() => QrServiceImpl());

  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionSummaryUseCase(sl()));
  sl.registerLazySingleton(() => SearchTransactionsUseCase(sl()));

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
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
      updateTransactionStatusUseCase: sl(),
      getTransactionSummaryUseCase: sl(),
      searchTransactionsUseCase: sl(),
    ),
  );
}