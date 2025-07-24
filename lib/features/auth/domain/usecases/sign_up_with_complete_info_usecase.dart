import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithCompleteInfoUseCase {
  final AuthRepository repository;

  SignUpWithCompleteInfoUseCase(this.repository);

  Future<ApiResult<AuthUser>> call({
    required String firstName,
    required String lastName,
    required String fullName,
    required String email,
    required String password,
    required DateTime birthDate,
  }) {
    return repository.createUserWithCompleteInfo(
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: email,
      password: password,
      birthDate: birthDate,
    );
  }
}