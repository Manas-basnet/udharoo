import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/bloc/qr_generator/qr_generator_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  TransactionType? _selectedTransactionType;
  Duration? _selectedValidityDuration;
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  final List<Duration?> _validityOptions = [
    null, // No expiry
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 6),
    const Duration(hours: 24),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QRGeneratorCubit>().generateQRCode();
    });
  }

  String _getValidityText(Duration? duration) {
    if (duration == null) return 'No expiry';
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
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
          message: 'Storage permission is required to save QR code',
          isSuccess: false,
        );
        return;
      }

      // Capture QR code as image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        CustomToast.show(
          context,
          message: 'Unable to capture QR code',
          isSuccess: false,
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        CustomToast.show(
          context,
          message: 'Failed to process QR code image',
          isSuccess: false,
        );
        return;
      }

      final uint8List = byteData.buffer.asUint8List();
      
      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        uint8List,
        quality: 100,
        name: 'udharoo_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        CustomToast.show(
          context,
          message: 'QR code saved to gallery successfully',
          isSuccess: true,
        );
      } else {
        CustomToast.show(
          context,
          message: 'Failed to save QR code to gallery',
          isSuccess: false,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: 'Error saving QR code: ${e.toString()}',
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

  void _showShareOptions(String qrData, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareOptionsBottomSheet(qrData: qrData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<QRGeneratorCubit, QRGeneratorState>(
            builder: (context, state) {
              if (state is QRGeneratorSuccess) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: _isSaving ? null : _saveQRToGallery,
                      icon: _isSaving 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onSurface,
                              ),
                            )
                          : const Icon(Icons.download, size: 22),
                      tooltip: 'Save to Gallery',
                    ),
                    IconButton(
                      onPressed: () => _showShareOptions(state.qrCodeString, context),
                      icon: const Icon(Icons.share, size: 22),
                      tooltip: 'Share QR Code',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQRCodeDisplay(state, theme),
                  
                  const SizedBox(height: 24),
                  
                  _buildSettingsCard(theme),
                  
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

  Widget _buildQRCodeDisplay(QRGeneratorState state, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your QR Code',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Show this to others for quick transactions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // QR Code Container
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              width: 320,
              height: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildQRCodeContent(state),
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (state is QRGeneratorSuccess) ...[
            _buildQRCodeInfo(state, theme),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveQRToGallery,
                    icon: _isSaving 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showShareOptions(state.qrCodeString, context),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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
              Text(
                'Generating QR Code...',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case QRGeneratorSuccess():
        return Center(
          child: QrImageView(
            data: state.qrCodeString,
            version: QrVersions.auto,
            size: 280,
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            embeddedImage: null,
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
          ),
        );
      case QRGeneratorError():
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to generate QR code',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to retry',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 60,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing QR code...',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildQRCodeInfo(QRGeneratorSuccess state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Type:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                state.qrData.constraintDisplayText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (state.qrData.expiresAt != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expires:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(state.qrData.expiresAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize QR Code',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Transaction Type Constraint
          Text(
            'Transaction Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTransactionTypeSelector(theme),
          
          const SizedBox(height: 16),
          
          // Validity Duration
          Text(
            'Validity Period',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildValiditySelector(theme),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildTransactionTypeOption(null, 'Any Transaction', 'Allow both lending and borrowing', theme),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _buildTransactionTypeOption(TransactionType.lent, 'Lend Only', 'Only allow others to borrow from you', theme),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _buildTransactionTypeOption(TransactionType.borrowed, 'Borrow Only', 'Only allow lending to others', theme),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeOption(
    TransactionType? type,
    String title,
    String subtitle,
    ThemeData theme,
  ) {
    final isSelected = _selectedTransactionType == type;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTransactionType = type;
          });
          context.read<QRGeneratorCubit>().updateTransactionType(type);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<TransactionType?>(
                value: type,
                groupValue: _selectedTransactionType,
                onChanged: (value) {
                  setState(() {
                    _selectedTransactionType = value;
                  });
                  context.read<QRGeneratorCubit>().updateTransactionType(value);
                },
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValiditySelector(ThemeData theme) {
    return DropdownButtonFormField<Duration?>(
      value: _selectedValidityDuration,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _validityOptions.map((duration) {
        return DropdownMenuItem<Duration?>(
          value: duration,
          child: Text(_getValidityText(duration)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedValidityDuration = value;
        });
        context.read<QRGeneratorCubit>().setValidityDuration(value);
      },
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How to use',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            '1. Share this QR code with someone you want to transact with',
            theme,
          ),
          _buildInstructionItem(
            '2. They can scan it to quickly create a transaction with you',
            theme,
          ),
          _buildInstructionItem(
            '3. All your details will be automatically filled in their transaction form',
            theme,
          ),
          _buildInstructionItem(
            '4. The transaction type constraint will limit what they can do',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} from now';
    } else {
      return 'Already expired';
    }
  }
}

class _ShareOptionsBottomSheet extends StatelessWidget {
  final String qrData;

  const _ShareOptionsBottomSheet({required this.qrData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share QR Code',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            _ShareOptionItem(
              icon: Icons.share,
              title: 'Share QR Text',
              subtitle: 'Share the QR code data as text',
              onTap: () {
                Navigator.of(context).pop();
                Share.share(
                  qrData,
                  subject: 'Udharoo Transaction QR Code',
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _ShareOptionItem(
              icon: Icons.copy,
              title: 'Copy to Clipboard',
              subtitle: 'Copy QR code data to clipboard',
              onTap: () {
                Navigator.of(context).pop();
                Clipboard.setData(ClipboardData(text: qrData));
                CustomToast.show(
                  context,
                  message: 'QR code data copied to clipboard',
                  isSuccess: true,
                );
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}