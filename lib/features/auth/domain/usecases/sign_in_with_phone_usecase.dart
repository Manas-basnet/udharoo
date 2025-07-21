import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SignInWithPhoneUseCase {
  final AuthRepository repository;

  SignInWithPhoneUseCase(this.repository);

  Future<ApiResult<AuthUser>> call(String phoneNumber, String password) {
    return repository.signInWithPhoneAndPassword(phoneNumber, password);
  }
}