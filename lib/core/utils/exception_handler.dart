import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/custom_exceptions.dart';

class ExceptionHandler {
  static Future<ApiResult<T>> handleExceptions<T>(
    Future<ApiResult<T>> Function() operation,
  ) async {
    try {
      return await operation();
    } on CustomException catch (e) {
      return ApiResult.failure(e.message, e.failureType);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException<T>(e);
    } on FirebaseException catch (e) {
      return _handleFirebaseException<T>(e);
    } 
    // on DioException catch (e) {
    //   return _handleDioException<T>(e);
    // } 
    on PlatformException catch (e) {
      return _handlePlatformException<T>(e);
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
    } on HandshakeException {
      return ApiResult.failure(
        'SSL handshake failed',
        FailureType.network,
      );
    }  on CertificateException {
      return ApiResult.failure(
        'SSL certificate error',
        FailureType.network,
      );
    } on FormatException catch (e) {
      return ApiResult.failure(
        'Invalid data format: ${e.message}',
        FailureType.validation,
      );
    }  on TlsException {
      return ApiResult.failure(
        'SSL/TLS connection failed',
        FailureType.network,
      );
    } on JsonCyclicError {
      return ApiResult.failure(
        'JSON circular reference error',
        FailureType.validation,
      );
    } on JsonUnsupportedObjectError catch (e) {
      return ApiResult.failure(
        'JSON serialization error: ${e.cause}',
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
    } on FileSystemException catch (e) {
      return ApiResult.failure(
        'File system error: ${e.message}',
        FailureType.cache,
      );
    } on TypeError catch (e) {
      return ApiResult.failure(
        'Type error: ${e.toString()}',
        FailureType.validation,
      );
    } on RangeError catch (e) {
      return ApiResult.failure(
        'Range error: ${e.message}',
        FailureType.validation,
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
    } on NoSuchMethodError catch (e) {
      return ApiResult.failure(
        'Method not found: ${e.toString()}',
        FailureType.unknown,
      );
    } on UnimplementedError catch (e) {
      return ApiResult.failure(
        'Feature not implemented: ${e.message}',
        FailureType.unknown,
      );
    } on UnsupportedError catch (e) {
      return ApiResult.failure(
        'Unsupported operation: ${e.message}',
        FailureType.unknown,
      );
    } on ConcurrentModificationError {
      return ApiResult.failure(
        'Concurrent modification error',
        FailureType.unknown,
      );
    } on IsolateSpawnException catch (e) {
      return ApiResult.failure(
        'Isolate spawn error: ${e.message}',
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
      
      case 'sign-in-aborted':
        return ApiResult.failure(
          e.message ?? 'Sign in was cancelled',
          FailureType.auth,
        );
      
      case 'account-exists-with-different-credential':
        return ApiResult.failure(
          e.message ?? 'Account exists with different sign-in method',
          FailureType.auth,
        );
      
      case 'sign_in_failed':
      case 'google-sign-in-failed':
      case 'user-creation-failed':
        return ApiResult.failure(
          e.message ?? 'Authentication failed',
          FailureType.auth,
        );
      
      default:
        return ApiResult.failure(
          e.message ?? 'Authentication error',
          FailureType.auth,
        );
    }
  }
  
  static ApiResult<T> _handleFirebaseException<T>(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return ApiResult.failure(
          e.message ?? 'Permission denied',
          FailureType.permission,
        );
      case 'unavailable':
        return ApiResult.failure(
          e.message ?? 'Service unavailable',
          FailureType.server,
        );
      case 'deadline-exceeded':
        return ApiResult.failure(
          e.message ?? 'Operation timeout',
          FailureType.network,
        );
      case 'not-found':
        return ApiResult.failure(
          e.message ?? 'Resource not found',
          FailureType.notFound,
        );
      case 'already-exists':
        return ApiResult.failure(
          e.message ?? 'Resource already exists',
          FailureType.validation,
        );
      case 'invalid-argument':
        return ApiResult.failure(
          e.message ?? 'Invalid argument',
          FailureType.validation,
        );
      case 'resource-exhausted':
        return ApiResult.failure(
          e.message ?? 'Resource exhausted',
          FailureType.server,
        );
      case 'failed-precondition':
        return ApiResult.failure(
          e.message ?? 'Failed precondition',
          FailureType.validation,
        );
      case 'aborted':
        return ApiResult.failure(
          e.message ?? 'Operation aborted',
          FailureType.unknown,
        );
      case 'out-of-range':
        return ApiResult.failure(
          e.message ?? 'Out of range',
          FailureType.validation,
        );
      case 'unimplemented':
        return ApiResult.failure(
          e.message ?? 'Feature not implemented',
          FailureType.unknown,
        );
      case 'internal':
        return ApiResult.failure(
          e.message ?? 'Internal error',
          FailureType.server,
        );
      case 'data-loss':
        return ApiResult.failure(
          e.message ?? 'Data loss',
          FailureType.unknown,
        );
      case 'unauthenticated':
        return ApiResult.failure(
          e.message ?? 'Authentication required',
          FailureType.auth,
        );
      default:
        return ApiResult.failure(
          e.message ?? 'Firebase error',
          FailureType.server,
        );
    }
  }

  static ApiResult<T> _handlePlatformException<T>(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
      case 'PERMISSION_DENIED_NEVER_ASK':
      case 'PERMISSION_DISABLED':
        return ApiResult.failure(
          e.message ?? 'Permission denied',
          FailureType.permission,
        );
      case 'NETWORK_ERROR':
      case 'NO_NETWORK':
        return ApiResult.failure(
          e.message ?? 'Network error',
          FailureType.network,
        );
      case 'TIMEOUT':
        return ApiResult.failure(
          e.message ?? 'Operation timeout',
          FailureType.network,
        );
      case 'CANCELLED':
      case 'USER_CANCELLED':
        return ApiResult.failure(
          e.message ?? 'Operation cancelled',
          FailureType.unknown,
        );
      case 'NOT_AVAILABLE':
      case 'NOT_SUPPORTED':
        return ApiResult.failure(
          e.message ?? 'Feature not available',
          FailureType.unknown,
        );
      case 'INVALID_ARGUMENT':
      case 'INVALID_PARAMETER':
        return ApiResult.failure(
          e.message ?? 'Invalid argument',
          FailureType.validation,
        );
      case 'AUTHENTICATION_FAILED':
      case 'AUTH_ERROR':
        return ApiResult.failure(
          e.message ?? 'Authentication failed',
          FailureType.auth,
        );
      case 'BIOMETRIC_ERROR':
      case 'FINGERPRINT_ERROR':
        return ApiResult.failure(
          e.message ?? 'Biometric authentication failed',
          FailureType.auth,
        );
      case 'STORAGE_ERROR':
      case 'FILE_ERROR':
        return ApiResult.failure(
          e.message ?? 'Storage error',
          FailureType.cache,
        );
      case 'MISSING_PLUGIN_EXCEPTION':
        return ApiResult.failure(
          e.message ?? 'Plugin not available',
          FailureType.unknown,
        );
      default:
        return ApiResult.failure(
          e.message ?? 'Platform error: ${e.code}',
          FailureType.unknown,
        );
    }
  }
  
  // static ApiResult<T> _handleDioException<T>(DioException e) {
  //   switch (e.type) {
  //     case DioExceptionType.connectionTimeout:
  //     case DioExceptionType.sendTimeout:
  //     case DioExceptionType.receiveTimeout:
  //       return ApiResult.failure(
  //         'Request timeout',
  //         FailureType.network,
  //       );
      
  //     case DioExceptionType.badResponse:
  //       return _handleHttpStatusCode<T>(e);
      
  //     case DioExceptionType.cancel:
  //       return ApiResult.failure(
  //         'Request cancelled',
  //         FailureType.unknown,
  //       );
      
  //     case DioExceptionType.connectionError:
  //       return ApiResult.failure(
  //         'Connection error',
  //         FailureType.network,
  //       );
      
  //     case DioExceptionType.badCertificate:
  //       return ApiResult.failure(
  //         'SSL certificate error',
  //         FailureType.network,
  //       );
      
  //     case DioExceptionType.unknown:
  //       return ApiResult.failure(
  //           'Network error: ${e.message}',
  //           FailureType.network,
  //         );
  //   }
  // }
  
  // static ApiResult<T> _handleHttpStatusCode<T>(DioException e) {
  //   final statusCode = e.response?.statusCode;
  //   final responseData = e.response?.data;
    
  //   String message = 'Server error';
  //   if (responseData is Map<String, dynamic> && responseData['message'] != null) {
  //     message = responseData['message'].toString();
  //   }
    
  //   switch (statusCode) {
  //     case 400:
  //       return ApiResult.failure(message, FailureType.validation);
  //     case 401:
  //       return ApiResult.failure(message, FailureType.auth);
  //     case 403:
  //       return ApiResult.failure(message, FailureType.permission);
  //     case 404:
  //       return ApiResult.failure(message, FailureType.notFound);
  //     case 422:
  //       return ApiResult.failure(message, FailureType.validation);
  //     case 500:
  //     case 502:
  //     case 503:
  //     case 504:
  //       return ApiResult.failure(message, FailureType.server);
  //     default:
  //       return ApiResult.failure(
  //         'HTTP $statusCode: $message',
  //         FailureType.server,
  //       );
  //   }
  // }
}