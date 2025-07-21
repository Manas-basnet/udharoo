import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:udharoo/features/profile/data/datasources/local/profile_local_datasource_impl.dart';
import 'package:udharoo/features/profile/data/datasources/remote/profile_remote_datasource_impl.dart';
import 'package:udharoo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:udharoo/features/profile/domain/datasources/local/profile_local_datasource.dart';
import 'package:udharoo/features/profile/domain/datasources/remote/profile_remote_datasource.dart';
import 'package:udharoo/features/profile/domain/repositories/profile_repository.dart';
import 'package:udharoo/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/check_phone_exists_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/verify_phone_usecase.dart';
import 'package:udharoo/features/profile/domain/usecases/create_user_profile_usecase.dart';
import 'package:udharoo/features/profile/presentation/bloc/profile_cubit.dart';

Future<void> initProfile(GetIt sl) async {
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => CheckPhoneExistsUseCase(sl()));
  sl.registerLazySingleton(() => SendPhoneVerificationUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPhoneNumberUseCase(sl()));
  sl.registerLazySingleton(() => CreateUserProfileUseCase(sl()));

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasourceImpl(
      firestore: sl(),
      storage: sl(),
      auth: sl(),
    ),
  );

  sl.registerLazySingleton<ProfileLocalDatasource>(
    () => ProfileLocalDatasourceImpl(),
  );

  sl.registerFactory(
    () => ProfileCubit(
      getUserProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      checkPhoneExistsUseCase: sl(),
      sendPhoneVerificationUseCase: sl(),
      verifyPhoneNumberUseCase: sl(),
      createUserProfileUseCase: sl(),
    ),
  );
}