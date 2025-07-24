import 'dart:typed_data';

abstract class QrService {
  Future<Uint8List> generateQRCode(String data);
  Future<String?> scanQRCode();
  Future<bool> saveQRCodeToGallery(Uint8List qrImageData, String fileName);
  Future<void> shareQRCode(Uint8List qrImageData, String fileName);
}