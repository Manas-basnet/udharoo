import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_generator/qr_generator_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QRGeneratorCubit>().generateQRCode(
        validityDuration: const Duration(hours: 24),
      );
    });
  }

  Future<void> _saveQRToGallery() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        if (await _getAndroidVersion() >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        CustomToast.show(
          context,
          message: 'Permission needed to save QR code',
          isSuccess: false,
        );
        return;
      }

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        CustomToast.show(
          context,
          message: 'Unable to save QR code',
          isSuccess: false,
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        CustomToast.show(
          context,
          message: 'Failed to process QR code',
          isSuccess: false,
        );
        return;
      }

      final uint8List = byteData.buffer.asUint8List();
      
      final result = await ImageGallerySaverPlus.saveImage(
        uint8List,
        quality: 100,
        name: 'udharoo_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        CustomToast.show(
          context,
          message: 'QR code saved successfully',
          isSuccess: true,
        );
      } else {
        CustomToast.show(
          context,
          message: 'Failed to save QR code',
          isSuccess: false,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: 'Error saving QR code',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      final version = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(version.stdout.toString().trim()) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void _shareQRCode(String qrData) {
    SharePlus.instance.share(
      ShareParams(
        text: qrData,
        subject: 'Connect with me on Udharoo',
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quick Share'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<QRGeneratorCubit, QRGeneratorState>(
        listener: (context, state) {
          if (state is QRGeneratorError) {
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeaderSection(theme),
                  
                  const SizedBox(height: 32),
                  
                  _buildQRCodeCard(state, theme),
                  
                  const SizedBox(height: 32),
                  
                  if (state is QRGeneratorSuccess) 
                    _buildActionButtons(state, theme),
                  
                  const SizedBox(height: 24),
                  
                  _buildInstructions(theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.qr_code_2,
            color: Colors.white,
            size: 40,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Your QR Code',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Let others add transactions with you easily',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQRCodeCard(QRGeneratorState state, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              width: 280,
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildQRCodeContent(state),
            ),
          ),
          
          if (state is QRGeneratorSuccess) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Valid for 24 hours',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRCodeContent(QRGeneratorState state) {
    switch (state) {
      case QRGeneratorLoading():
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating your QR code...'),
            ],
          ),
        );
      case QRGeneratorSuccess():
        return QrImageView(
          data: state.qrCodeString,
          version: QrVersions.auto,
          size: 248,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        );
      case QRGeneratorError():
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              const Text('Failed to create QR code'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<QRGeneratorCubit>().generateQRCode(
                    validityDuration: const Duration(hours: 24),
                  );
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildActionButtons(QRGeneratorSuccess state, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _shareQRCode(state.qrCodeString),
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share QR Code'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveQRToGallery,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 20),
            label: Text(_isSaving ? 'Saving...' : 'Save to Photos'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInstructionStep(
            '1',
            'Share this QR code with someone',
            'Send via WhatsApp, show your screen, or save to photos',
            theme,
          ),
          
          const SizedBox(height: 12),
          
          _buildInstructionStep(
            '2',
            'They scan it with their Udharoo app',
            'Your details will be automatically filled in their transaction form',
            theme,
          ),
          
          const SizedBox(height: 12),
          
          _buildInstructionStep(
            '3',
            'Create transactions instantly',
            'No need to exchange phone numbers or type contact details',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}