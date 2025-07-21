import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:udharoo/features/auth/domain/entities/user_device.dart';

abstract class DeviceInfoService {
  Future<UserDevice> getCurrentDevice();
  Future<String> getDeviceId();
  Future<String> getDeviceName();
  Future<String?> getDeviceModel();
  String getPlatform();
}

class DeviceInfoServiceImpl implements DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DeviceInfoServiceImpl({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  @override
  Future<UserDevice> getCurrentDevice() async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();
    final deviceModel = await getDeviceModel();
    final platform = getPlatform();

    return UserDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceModel: deviceModel,
      platform: platform,
      verifiedAt: DateTime.now(),
      isActive: true,
    );
  }

  @override
  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown-ios-device';
    } else {
      return 'unknown-device';
    }
  }

  @override
  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.name;
    } else {
      return 'Unknown Device';
    }
  }

  @override
  Future<String?> getDeviceModel() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.model;
    } else {
      return null;
    }
  }

  @override
  String getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else {
      return Platform.operatingSystem;
    }
  }
}