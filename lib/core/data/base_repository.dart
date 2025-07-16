import 'dart:async';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/network/network_info.dart';
import 'package:udharoo/core/utils/exception_handler.dart';

abstract class BaseRepository {
  BaseRepository({required this.networkInfo});

  final NetworkInfo networkInfo;

  Future<ApiResult<T>> handleRemoteCallFirst<T>({
    required Future<ApiResult<T>> Function() remoteCall,
    Future<ApiResult<T>> Function()? localCall,
    required Future<void> Function(T? data) saveLocalData,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      if (!(await networkInfo.isConnected)) {
        if (localCall != null) {
          return await localCall();
        }
        return ApiResult.failure(
          'No internet connection',
          FailureType.network,
        );
      }

      final remoteResult = await remoteCall();
      
      if (remoteResult is Success) {
        try {
          await saveLocalData(remoteResult.data);
        } catch (e) {
          //silently ignore save erors kina bhane we already got the data we need
        }
      }

      return remoteResult;
    });
  }

  Future<ApiResult<T>> handleCacheCallFirst<T>({
    required Future<ApiResult<T>> Function() localCall,
    Future<ApiResult<T>> Function()? remoteCall,
    required Future<void> Function(T? data) saveLocalData,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final result = await localCall();

      if (result.data != null) {
        return result;
      }

      if (!(await networkInfo.isConnected)) {
        return ApiResult.failure(
          'No internet connection',
          FailureType.network,
        );
      }

      if (remoteCall != null) {
        final remoteResult = await remoteCall();
        
        if (remoteResult is Success) {
          try {
            await saveLocalData(remoteResult.data);
          } catch (e) {
            //silently ignore save erors kina bhane we already got the data we need
          }
        }
        return remoteResult;
      }

      return ApiResult.failure(
        'No data available',
        FailureType.noData,
      );
    });
  }

  Future<ApiResult<T>> handleCacheCallFirstNoResponse<T>({
    required Future<ApiResult<T>> Function() localCall,
    Future<ApiResult<T>> Function()? remoteCall,
    required Future<void> Function(T? data) saveLocalData,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final result = await localCall();

      if (result.data != null) {
        return result;
      }

      if (!(await networkInfo.isConnected)) {
        return ApiResult.failure(
          'No internet connection',
          FailureType.network,
        );
      }

      if (remoteCall != null) {
        final remoteResult = await remoteCall();
        
        if (remoteResult is Success) {
          try {
            await saveLocalData(remoteResult.data);
          } catch (e) {
            //silently ignore save erors kina bhane we already got the data we need
          }
        }
        return remoteResult;
      }

      return ApiResult.failure(
        'No data available',
        FailureType.noData,
      );
    });
  }
}