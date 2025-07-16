import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  Future<ApiResult<AuthUser>> call(String email, String password) {
    return repository.signInWithEmailAndPassword(email, password);
  }
}