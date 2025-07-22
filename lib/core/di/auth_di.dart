import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:udharoo/features/auth/data/datasources/local/shared_prefs_auth_local_datasource_impl.dart';
import 'package:udharoo/features/auth/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:udharoo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:udharoo/features/auth/data/services/auth_service_impl.dart';
import 'package:udharoo/features/auth/domain/datasources/local/auth_local_datasource.dart';
import 'package:udharoo/features/auth/domain/datasources/remote/auth_remote_datasource.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';
import 'package:udharoo/features/auth/domain/services/auth_service.dart';
import 'package:udharoo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/send_phone_verification_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/verify_phone_code_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/sign_in_with_phone_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/link_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/update_phone_number_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_phone_verification_status_usecase.dart';
import 'package:udharoo/features/auth/domain/usecases/check_email_verification_status_usecase.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_cubit.dart';

Future<void> initAuth(GetIt sl) async {
  sl.registerLazySingleton(() => GoogleSignIn());

  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithPhoneUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmailUseCase(sl()));
  sl.registerLazySingleton(() => SendEmailVerificationUseCase(sl()));
  sl.registerLazySingleton(() => SendPhoneVerificationCodeUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPhoneCodeUseCase(sl()));
  sl.registerLazySingleton(() => LinkPhoneNumberUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePhoneNumberUseCase(sl()));
  sl.registerLazySingleton(() => CheckPhoneVerificationStatusUseCase(sl()));
  sl.registerLazySingleton(() => CheckEmailVerificationStatusUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      deviceInfoService: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(),
  );

  sl.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(
      authStateChanges: sl<AuthRepository>().authStateChanges,
    ),
  );

  sl.registerFactory(
    () => AuthCubit(
      signInWithEmailUseCase: sl(),
      signUpWithEmailUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signInWithPhoneUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      isAuthenticatedUseCase: sl(),
      sendPasswordResetEmailUseCase: sl(),
      sendEmailVerificationUseCase: sl(),
      sendPhoneVerificationCodeUseCase: sl(),
      verifyPhoneCodeUseCase: sl(),
      linkPhoneNumberUseCase: sl(),
      updatePhoneNumberUseCase: sl(),
      checkPhoneVerificationStatusUseCase: sl(),
      checkEmailVerificationStatusUseCase: sl(),
      authService: sl(),
    ),
  );
}