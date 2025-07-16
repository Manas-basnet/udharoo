import 'package:firebase_core/firebase_core.dart';
import 'package:udharoo/firebase_options_dev.dart' as dev;
import 'package:udharoo/firebase_options_staging.dart' as staging;
import 'package:udharoo/firebase_options_prod.dart' as prod;

enum AppFlavor { dev, staging, prod }

class AppConfig {
  static AppFlavor _flavor = AppFlavor.dev;

  static AppFlavor get flavor => _flavor;

  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
  }

  static FirebaseOptions get firebaseOptions {
    switch (_flavor) {
      case AppFlavor.dev:
        return dev.DefaultFirebaseOptions.currentPlatform;
      case AppFlavor.staging:
        return staging.DefaultFirebaseOptions.currentPlatform;
      case AppFlavor.prod:
        return prod.DefaultFirebaseOptions.currentPlatform;
    }
  }

  static String get appName {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'Udharoo Dev';
      case AppFlavor.staging:
        return 'Udharoo Staging';
      case AppFlavor.prod:
        return 'Udharoo';
    }
  }

  static String get appSuffix {
    switch (_flavor) {
      case AppFlavor.dev:
        return '.dev';
      case AppFlavor.staging:
        return '.staging';
      case AppFlavor.prod:
        return '';
    }
  }

  static bool get isDebug {
    switch (_flavor) {
      case AppFlavor.dev:
      case AppFlavor.staging:
        return true;
      case AppFlavor.prod:
        return false;
    }
  }
}