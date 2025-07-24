import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';

class QrServiceImpl implements QrService {
  @override
  Future<Uint8List> generateQRCode(String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        
        final painter = QrPainter(
          data: data,
          version: qrCode.typeNumber,
          errorCorrectionLevel: qrCode.errorCorrectLevel,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        );

        final picData = await painter.toImageData(300);
        return picData!.buffer.asUint8List();
      } else {
        throw Exception('Invalid QR data');
      }
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  @override
  Future<String?> scanQRCode() async {
    try {
      final permission = await Permission.camera.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('Camera permission denied');
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to scan QR code: $e');
    }
  }

  @override
  Future<bool> saveQRCodeToGallery(Uint8List qrImageData, String fileName) async {
    try {
      final permission = await Permission.storage.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('Storage permission denied');
      }

      final result = await ImageGallerySaverPlus.saveImage(
        qrImageData,
        name: fileName,
        quality: 100,
      );

      return result['isSuccess'] == true;
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  @override
  Future<void> shareQRCode(Uint8List qrImageData, String fileName) async {
    try {
      await Share.shareXFiles([
        XFile.fromData(
          qrImageData,
          name: '$fileName.png',
          mimeType: 'image/png',
        )
      ], text: 'My QR Code for Udharoo');
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }
}