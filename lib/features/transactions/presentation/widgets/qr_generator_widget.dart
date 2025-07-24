import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';

class QRGeneratorWidget extends StatelessWidget {
  final QRData qrData;
  final Function()? onShare;
  final Function()? onSave;
  final bool showActions;

  const QRGeneratorWidget({
    super.key,
    required this.qrData,
    this.onShare,
    this.onSave,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrDataJson = jsonEncode({
      'userPhone': qrData.userPhone,
      'userName': qrData.userName,
      'userEmail': qrData.userEmail,
      'verificationRequired': qrData.verificationRequired,
      'generatedAt': qrData.generatedAt.toIso8601String(),
      'customMessage': qrData.customMessage,
    });
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: QrImageView(
                  data: qrDataJson,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qrData.userName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          qrData.userPhone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (qrData.userEmail != null)
                          Text(
                            qrData.userEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (qrData.verificationRequired) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verification Required',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (qrData.customMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.message,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qrData.customMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (showActions) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.download),
                  label: const Text('Save to Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Share QR'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Others can scan this QR code to quickly add your contact information when creating transactions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Uint8List?> generateQRImage() async {
    try {
      final qrDataJson = jsonEncode({
        'userPhone': qrData.userPhone,
        'userName': qrData.userName,
        'userEmail': qrData.userEmail,
        'verificationRequired': qrData.verificationRequired,
        'generatedAt': qrData.generatedAt.toIso8601String(),
        'customMessage': qrData.customMessage,
      });

      final qrValidationResult = QrValidator.validate(
        data: qrDataJson,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        
        final painter = QrPainter(
          data: qrDataJson,
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
        return picData?.buffer.asUint8List();
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}