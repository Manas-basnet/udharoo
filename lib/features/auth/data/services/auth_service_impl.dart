import 'dart:async';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/events/auth_event.dart';
import 'package:udharoo/features/auth/domain/services/auth_service.dart';

class AuthServiceImpl implements AuthService {
  final Stream<AuthUser?> _authStateChanges;
  final _authEventController = StreamController<AuthEvent>.broadcast();

  AuthServiceImpl({required Stream<AuthUser?> authStateChanges}) 
      : _authStateChanges = authStateChanges {
    _listenToAuthChanges();
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateChanges;

  @override
  Stream<AuthEvent> get authEventStream => _authEventController.stream;

  void _listenToAuthChanges() {
    _authStateChanges.listen((user) {
      if (user == null) {
        _authEventController.add(ForceLogoutEvent());
      }
    });
  }

  @override
  void dispose() {
    _authEventController.close();
  }
}