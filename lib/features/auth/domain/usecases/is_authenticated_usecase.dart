import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class IsAuthenticatedUseCase {
  final AuthRepository repository;

  IsAuthenticatedUseCase(this.repository);

  Future<ApiResult<bool>> call() {
    return repository.isAuthenticated();
  }
}