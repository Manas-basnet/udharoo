import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class LinkPasswordUseCase {
  final AuthRepository repository;

  LinkPasswordUseCase(this.repository);

  Future<ApiResult<AuthUser>> call(String password) {
    return repository.linkPassword(password);
  }
}