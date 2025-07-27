import 'package:get_it/get_it.dart';
import 'package:udharoo/core/di/auth_di.dart';
import 'package:udharoo/core/di/core_di.dart';
import 'package:udharoo/features/transactions/di/qr_di.dart';
import 'package:udharoo/features/transactions/di/transactions_di.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await initCore(sl);
  await initAuth(sl);
  await initTransactions(sl);
  await initQRFeatures(sl);
}