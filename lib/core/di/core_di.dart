import 'package:get_it/get_it.dart';
import 'package:udharoo/core/network/network_info.dart';
import 'package:udharoo/core/services/device_info_service.dart';
import 'package:udharoo/shared/presentation/bloc/theme_cubit/theme_cubit.dart';

Future<void> initCore(GetIt sl) async {
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl());
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
}