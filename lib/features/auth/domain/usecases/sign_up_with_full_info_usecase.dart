import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithFullInfoUseCase {
  final AuthRepository repository;

  SignUpWithFullInfoUseCase(this.repository);

  Future<ApiResult<AuthUser>> call({
    required String fullName,
    required String email,
    required String password,
  }) {
    return repository.createUserWithFullInfo(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}