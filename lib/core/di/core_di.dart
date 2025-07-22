import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:udharoo/core/network/network_info.dart';
import 'package:udharoo/features/auth/domain/services/device_info_service.dart';
import 'package:udharoo/features/transactions/data/services/qr_service_impl.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';

Future<void> initCore(GetIt sl) async {
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton<QrService>(() => QrServiceImpl());

  sl.registerLazySingleton<DeviceInfoService>(
    () => DeviceInfoServiceImpl(deviceInfoPlugin: sl()),
  );
}