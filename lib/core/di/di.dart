import 'package:get_it/get_it.dart';
import 'package:udharoo/features/auth/di/auth_di.dart';
import 'package:udharoo/core/di/core_di.dart';
import 'package:udharoo/features/contacts/di/contacts_di.dart';
import 'package:udharoo/features/transactions/di/qr_di.dart';
import 'package:udharoo/features/transactions/di/transactions_di.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await initCore(sl);
  await initAuth(sl);
  await initTransactions(sl);
  await initContacts(sl);
  await initQRFeatures(sl);
}