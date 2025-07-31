import 'package:get_it/get_it.dart';
import 'package:udharoo/features/contacts/data/datasources/local/contact_local_datasource.dart';
import 'package:udharoo/features/contacts/data/datasources/remote/contact_remote_datasource.dart';
import 'package:udharoo/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:udharoo/features/contacts/domain/repositories/contact_repository.dart';
import 'package:udharoo/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_by_user_id_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contact_transactions_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:udharoo/features/contacts/domain/usecases/search_contacts_usecase.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';

Future<void> initContacts(GetIt sl) async {
  // Use cases
  sl.registerLazySingleton(() => GetContactsUseCase(sl()));
  sl.registerLazySingleton(() => SearchContactsUseCase(sl()));
  sl.registerLazySingleton(() => AddContactUseCase(sl()));
  sl.registerLazySingleton(() => DeleteContactUseCase(sl()));
  sl.registerLazySingleton(() => GetContactByUserIdUseCase(sl()));
  sl.registerLazySingleton(() => GetContactTransactionsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      // getUserByPhoneUseCase: sl(),
      networkInfo: sl(),
    ),
  );

  // Datasources
  sl.registerLazySingleton<ContactLocalDatasource>(
    () => ContactLocalDatasourceImpl(),
  );

  sl.registerLazySingleton<ContactRemoteDatasource>(
    () => ContactRemoteDatasourceImpl(
      firestore: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => ContactCubit(
      getContactsUseCase: sl(),
      searchContactsUseCase: sl(),
      addContactUseCase: sl(),
      deleteContactUseCase: sl(),
      getContactByUserIdUseCase: sl(),
    ),
  );
}