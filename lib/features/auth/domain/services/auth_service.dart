import 'dart:async';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/events/auth_event.dart';

abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  Stream<AuthEvent> get authEventStream;
  void dispose();
}