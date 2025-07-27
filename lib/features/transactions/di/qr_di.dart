import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/datasources/local/contact_history_local_datasource.dart';
import 'package:udharoo/features/transactions/data/repositories/contact_history_repository_impl.dart';
import 'package:udharoo/features/transactions/data/repositories/qr_repository_impl.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/clear_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/delete_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/get_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/save_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/contact/search_contact_history_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_code_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/parse_qr_data_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/validate_qr_data_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/contact_history/contact_history_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_generator/qr_generator_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_scanner/qr_scanner_cubit.dart';

Future<void> initQRFeatures(GetIt sl) async {
  // ===== QR Generation & Scanning Use Cases =====
  sl.registerLazySingleton(() => GenerateQRDataUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQRCodeUseCase(sl()));
  sl.registerLazySingleton(() => ParseQRDataUseCase(sl()));
  sl.registerLazySingleton(() => ValidateQRDataUseCase(sl()));

  // ===== Contact History Use Cases =====
  sl.registerLazySingleton(() => GetContactHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SaveContactHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchContactHistoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteContactHistoryUseCase(sl()));
  sl.registerLazySingleton(() => ClearContactHistoryUseCase(sl()));

  // ===== Repositories =====
  sl.registerLazySingleton<QRRepository>(
    () => QRRepositoryImpl(
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<ContactHistoryRepository>(
    () => ContactHistoryRepositoryImpl(
      localDatasource: sl(),
      networkInfo: sl(),
    ),
  );

  // ===== Datasources =====
  sl.registerLazySingleton<ContactHistoryLocalDatasource>(
    () => ContactHistoryLocalDatasourceImpl(),
  );

  // ===== Cubits =====
  sl.registerFactory(
    () => QRGeneratorCubit(
      generateQRDataUseCase: sl(),
      generateQRCodeUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => QRScannerCubit(
      parseQRDataUseCase: sl(),
      validateQRDataUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ContactHistoryCubit(
      getContactHistoryUseCase: sl(),
      saveContactHistoryUseCase: sl(),
      searchContactHistoryUseCase: sl(),
      deleteContactHistoryUseCase: sl(),
    ),
  );
}