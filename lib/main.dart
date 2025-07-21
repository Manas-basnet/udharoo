import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:udharoo/config/app_config.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppConfig.setFlavor(AppFlavor.dev);
  
  await Firebase.initializeApp(
    options: AppConfig.firebaseOptions,
  );
  
  await di.init();
  
  runApp(const MyApp());
}