// import 'dart:io';
// import 'package:dio/dio.dart';

// abstract class DeviceInfoService {
//   Future<String?> getDeviceIpAddress();
//   Future<String> getDeviceId();
//   Future<String> getDeviceName();
// }

// class DeviceInfoServiceImpl implements DeviceInfoService {
//   @override
//   Future<String?> getDeviceIpAddress() async {
//     try {
//       final interfaces = await NetworkInterface.list();
//       for (final interface in interfaces) {
//         for (final address in interface.addresses) {
//           if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
//             return address.address;
//           }
//         }
//       }
      
//       return await _getPublicIpAddress();
//     } catch (e) {
//       return await _getPublicIpAddress();
//     }
//   }

//   Future<String?> _getPublicIpAddress() async {
//     try {
//       final dio = Dio();
//       dio.options.connectTimeout = const Duration(seconds: 5);
//       dio.options.receiveTimeout = const Duration(seconds: 5);
      
//       final response = await dio.get('https://api.ipify.org?format=json');
//       return response.data['ip'] as String?;
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   Future<String> getDeviceId() async {
//     return 'device_id_placeholder';
//   }

//   @override
//   Future<String> getDeviceName() async {
//     return Platform.operatingSystem;
//   }
// }