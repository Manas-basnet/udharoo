import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/network/api_result.dart';

class ExceptionHandler {
  static Future<ApiResult<T>> handleExceptions<T>(
    Future<ApiResult<T>> Function() operation,
  ) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException<T>(e);
    } on DioException catch (e) {
      return _handleDioException<T>(e);
    } on SocketException {
      return ApiResult.failure(
        'Network connection failed',
        FailureType.network,
      );
    } on TimeoutException {
      return ApiResult.failure(
        'Request timeout',
        FailureType.network,
      );
    } on HttpException catch (e) {
      return ApiResult.failure(
        'HTTP error: ${e.message}',
        FailureType.server,
      );
    } on TlsException {
      return ApiResult.failure(
        'SSL/TLS connection failed',
        FailureType.network,
      );
    } on FormatException {
      return ApiResult.failure(
        'Invalid response format',
        FailureType.validation,
      );
    } on PathNotFoundException {
      return ApiResult.failure(
        'Resource not found',
        FailureType.notFound,
      );
    } on PathAccessException {
      return ApiResult.failure(
        'Access permission denied',
        FailureType.permission,
      );
    } on FileSystemException {
      return ApiResult.failure(
        'File system error',
        FailureType.cache,
      );
    } on ArgumentError catch (e) {
      return ApiResult.failure(
        'Invalid argument: ${e.message}',
        FailureType.validation,
      );
    } on StateError catch (e) {
      return ApiResult.failure(
        'Invalid state: ${e.message}',
        FailureType.unknown,
      );
    } catch (e) {
      return ApiResult.failure(
        'Unexpected error: ${e.toString()}',
        FailureType.unknown,
      );
    }
  }
  
  static ApiResult<T> _handleFirebaseAuthException<T>(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'invalid-credential':
        return ApiResult.failure(
          e.message ?? 'Invalid credentials',
          FailureType.auth,
        );
      
      case 'email-already-in-use':
        return ApiResult.failure(
          e.message ?? 'Email already in use',
          FailureType.validation,
        );
      
      case 'weak-password':
        return ApiResult.failure(
          e.message ?? 'Password is too weak',
          FailureType.validation,
        );
      
      case 'operation-not-allowed':
        return ApiResult.failure(
          e.message ?? 'Operation not allowed',
          FailureType.permission,
        );
      
      case 'too-many-requests':
        return ApiResult.failure(
          e.message ?? 'Too many requests. Try again later.',
          FailureType.server,
        );
      
      case 'network-request-failed':
        return ApiResult.failure(
          e.message ?? 'Network error',
          FailureType.network,
        );
      
      case 'user-disabled':
        return ApiResult.failure(
          e.message ?? 'User account has been disabled',
          FailureType.auth,
        );
      
      default:
        return ApiResult.failure(
          e.message ?? 'Authentication error',
          FailureType.auth,
        );
    }
  }
  
  static ApiResult<T> _handleDioException<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResult.failure(
          'Request timeout',
          FailureType.network,
        );
      
      case DioExceptionType.badResponse:
        return _handleHttpStatusCode<T>(e);
      
      case DioExceptionType.cancel:
        return ApiResult.failure(
          'Request cancelled',
          FailureType.unknown,
        );
      
      case DioExceptionType.connectionError:
        return ApiResult.failure(
          'Connection error',
          FailureType.network,
        );
      
      case DioExceptionType.badCertificate:
        return ApiResult.failure(
          'SSL certificate error',
          FailureType.network,
        );
      
      case DioExceptionType.unknown:
        return ApiResult.failure(
            'Network error: ${e.message}',
            FailureType.network,
          );
    }
  }
  
  static ApiResult<T> _handleHttpStatusCode<T>(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    
    String message = 'Server error';
    if (responseData is Map<String, dynamic> && responseData['message'] != null) {
      message = responseData['message'].toString();
    }
    
    switch (statusCode) {
      case 400:
        return ApiResult.failure(message, FailureType.validation);
      case 401:
        return ApiResult.failure(message, FailureType.auth);
      case 403:
        return ApiResult.failure(message, FailureType.permission);
      case 404:
        return ApiResult.failure(message, FailureType.notFound);
      case 422:
        return ApiResult.failure(message, FailureType.validation);
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiResult.failure(message, FailureType.server);
      default:
        return ApiResult.failure(
          'HTTP $statusCode: $message',
          FailureType.server,
        );
    }
  }
}