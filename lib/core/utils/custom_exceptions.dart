import 'package:udharoo/core/network/api_result.dart';

abstract class CustomException implements Exception {
  final String message;
  final FailureType failureType;

  const CustomException(this.message, this.failureType);

  @override
  String toString() => '$runtimeType: $message';
}

class ValidationException extends CustomException {
  const ValidationException(String message) 
      : super(message, FailureType.validation);
}

class BusinessLogicException extends CustomException {
  const BusinessLogicException(String message) 
      : super(message, FailureType.unknown);
}

class CacheException extends CustomException {
  const CacheException(String message) 
      : super(message, FailureType.cache);
}

class NotAuthenticatedException extends CustomException {
  const NotAuthenticatedException([String? message]) 
      : super(message ?? 'User not authenticated', FailureType.auth);
}

class InsufficientPermissionException extends CustomException {
  const InsufficientPermissionException([String? message]) 
      : super(message ?? 'Insufficient permissions', FailureType.permission);
}

class DataNotAvailableException extends CustomException {
  const DataNotAvailableException([String? message]) 
      : super(message ?? 'Data not available', FailureType.noData);
}

class ServerMaintenanceException extends CustomException {
  const ServerMaintenanceException([String? message]) 
      : super(message ?? 'Server under maintenance', FailureType.server);
}

class FeatureDisabledException extends CustomException {
  const FeatureDisabledException([String? message]) 
      : super(message ?? 'Feature is disabled', FailureType.unknown);
}

class RateLimitExceededException extends CustomException {
  const RateLimitExceededException([String? message]) 
      : super(message ?? 'Rate limit exceeded', FailureType.server);
}

class DataCorruptedException extends CustomException {
  const DataCorruptedException([String? message]) 
      : super(message ?? 'Data is corrupted', FailureType.validation);
}

class SyncException extends CustomException {
  const SyncException([String? message]) 
      : super(message ?? 'Synchronization failed', FailureType.network);
}

class ConflictException extends CustomException {
  const ConflictException([String? message]) 
      : super(message ?? 'Data conflict detected', FailureType.validation);
}

class QuotaExceededException extends CustomException {
  const QuotaExceededException([String? message]) 
      : super(message ?? 'Quota exceeded', FailureType.server);
}

class DependencyException extends CustomException {
  const DependencyException([String? message]) 
      : super(message ?? 'Dependency error', FailureType.unknown);
}