import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/transactions/data/datasources/local/contact_history_local_datasource.dart';
import 'package:udharoo/features/transactions/data/models/contact_history_model.dart';
import 'package:udharoo/features/transactions/domain/entities/contact_history.dart';
import 'package:udharoo/features/transactions/domain/repositories/contact_history_repository.dart';

class ContactHistoryRepositoryImpl extends BaseRepository implements ContactHistoryRepository {
  final ContactHistoryLocalDatasource _localDatasource;

  ContactHistoryRepositoryImpl({
    required ContactHistoryLocalDatasource localDatasource,
    required super.networkInfo,
  }) : _localDatasource = localDatasource;

  @override
  Future<ApiResult<void>> saveContactHistory({
    required String phoneNumber,
    required String name,
    String? userId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      // Validate input
      if (phoneNumber.trim().isEmpty) {
        return ApiResult.failure(
          'Phone number cannot be empty',
          FailureType.validation,
        );
      }

      if (name.trim().isEmpty) {
        return ApiResult.failure(
          'Contact name cannot be empty',
          FailureType.validation,
        );
      }

      final contact = ContactHistoryModel(
        phoneNumber: phoneNumber.trim(),
        name: name.trim(),
        lastUsed: DateTime.now(),
        transactionCount: 1,
        userId: userId,
      );

      await _localDatasource.saveContact(contact);
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<List<ContactHistory>>> getContactHistory({
    int? limit,
    String? userId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final contacts = await _localDatasource.getContacts(
        limit: limit,
        userId: userId,
      );
      
      return ApiResult.success(contacts.cast<ContactHistory>());
    });
  }

  @override
  Future<ApiResult<List<ContactHistory>>> searchContactHistory({
    required String query,
    int? limit,
    String? userId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (query.trim().isEmpty) {
        return ApiResult.success(<ContactHistory>[]);
      }

      final contacts = await _localDatasource.searchContacts(
        query: query.trim(),
        limit: limit,
        userId: userId,
      );
      
      return ApiResult.success(contacts.cast<ContactHistory>());
    });
  }

  @override
  Future<ApiResult<void>> clearContactHistory(String? userId) async {
    return ExceptionHandler.handleExceptions(() async {
      await _localDatasource.clearContacts(userId);
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<void>> deleteContactHistory({
    required String phoneNumber,
    String? userId,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (phoneNumber.trim().isEmpty) {
        return ApiResult.failure(
          'Phone number cannot be empty',
          FailureType.validation,
        );
      }

      await _localDatasource.deleteContact(phoneNumber.trim(), userId);
      return ApiResult.success(null);
    });
  }
}