import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';

abstract class ContactHistoryRepository {
  Future<ApiResult<void>> saveContactHistory({
    required String phoneNumber,
    required String name,
    String? userId,
  });

  Future<ApiResult<List<ContactHistory>>> getContactHistory({

    int? limit,
    String? userId,
  });

  Future<ApiResult<List<ContactHistory>>> searchContactHistory({
    required String query,
    int? limit,
    String? userId,
  });

  Future<ApiResult<void>> clearContactHistory(String? userId);

  Future<ApiResult<void>> deleteContactHistory({
    required String phoneNumber,
    String? userId,
  });
}