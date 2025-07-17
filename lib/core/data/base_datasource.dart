// import 'package:dio/dio.dart';

// abstract class BaseDatasource {
//   final Dio dio;

//   BaseDatasource({required this.dio});

//   Future<T> get<T>(
//     String path, {
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     T Function(dynamic)? fromJson,
//   }) async {
//     final response = await dio.get(
//       path,
//       queryParameters: queryParameters,
//       options: options,
//     );
    
//     if (fromJson != null) {
//       return fromJson(response.data);
//     }
//     return response.data as T;
//   }

//   Future<T> post<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     T Function(dynamic)? fromJson,
//   }) async {
//     final response = await dio.post(
//       path,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
    
//     if (fromJson != null) {
//       return fromJson(response.data);
//     }
//     return response.data as T;
//   }

//   Future<T> put<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     T Function(dynamic)? fromJson,
//   }) async {
//     final response = await dio.put(
//       path,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
    
//     if (fromJson != null) {
//       return fromJson(response.data);
//     }
//     return response.data as T;
//   }

//   Future<T> delete<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     T Function(dynamic)? fromJson,
//   }) async {
//     final response = await dio.delete(
//       path,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
    
//     if (fromJson != null) {
//       return fromJson(response.data);
//     }
//     return response.data as T;
//   }

//   Future<T> patch<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     T Function(dynamic)? fromJson,
//   }) async {
//     final response = await dio.patch(
//       path,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
    
//     if (fromJson != null) {
//       return fromJson(response.data);
//     }
//     return response.data as T;
//   }
// }