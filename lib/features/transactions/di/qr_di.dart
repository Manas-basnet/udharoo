import 'package:get_it/get_it.dart';
import 'package:udharoo/features/transactions/data/repositories/qr_repository_impl.dart';
import 'package:udharoo/features/transactions/domain/repositories/qr_repository.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_code_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/parse_qr_data_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/validate_qr_data_usecase.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_generator/qr_generator_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_scanner/qr_scanner_cubit.dart';

Future<void> initQRFeatures(GetIt sl) async {
  // ===== QR Generation & Scanning Use Cases =====
  sl.registerLazySingleton(() => GenerateQRDataUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQRCodeUseCase(sl()));
  sl.registerLazySingleton(() => ParseQRDataUseCase(sl()));
  sl.registerLazySingleton(() => ValidateQRDataUseCase(sl()));

  // ===== Repositories =====
  sl.registerLazySingleton<QRRepository>(
    () => QRRepositoryImpl(
      networkInfo: sl(),
    ),
  );

  // ===== Datasources =====

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

}