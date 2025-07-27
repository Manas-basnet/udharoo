import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/auth/domain/entities/auth_user.dart';
import 'package:udharoo/features/auth/domain/repositories/auth_repository.dart';

class GetUserByPhoneUseCase {
  final AuthRepository repository;

  GetUserByPhoneUseCase(this.repository);

  Future<ApiResult<AuthUser?>> call(String phoneNumber) async {
    return repository.getUserByPhoneNumber(phoneNumber);
  }
}