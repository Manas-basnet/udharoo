import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class LinkGoogleAccountUseCase {
  final AuthRepository repository;

  LinkGoogleAccountUseCase(this.repository);

  Future<ApiResult<AuthUser>> call() {
    return repository.linkGoogleAccount();
  }
}