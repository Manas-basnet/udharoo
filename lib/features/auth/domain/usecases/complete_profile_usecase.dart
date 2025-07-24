import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class CompleteProfileUseCase {
  final AuthRepository repository;

  CompleteProfileUseCase(this.repository);

  Future<ApiResult<AuthUser>> call({
    required String fullName,
    required DateTime birthDate,
  }) {
    return repository.completeProfile(
      fullName: fullName,
      birthDate: birthDate,
    );
  }
}