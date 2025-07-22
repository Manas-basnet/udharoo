import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class UpdateDisplayNameUseCase {
  final AuthRepository repository;

  UpdateDisplayNameUseCase(this.repository);

  Future<ApiResult<AuthUser>> call(String displayName) {
    return repository.updateDisplayName(displayName);
  }
}