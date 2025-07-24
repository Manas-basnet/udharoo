import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:udharoo/features/transactions/presentation/widgets/qr_generator_widget.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _messageController = TextEditingController();
  bool _verificationRequired = false;
  bool _globalVerificationSetting = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadUserSettings() {
    // Load global verification setting
    // This would typically come from user preferences
  }

  void _generateQR() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is! AuthSessionAuthenticated) {
      CustomToast.show(
        context,
        message: 'You must be logged in to generate QR codes',
        isSuccess: false,
      );
      return;
    }

    final user = authState.user;
    if (user.phoneNumber == null) {
      CustomToast.show(
        context,
        message: 'Phone number is required to generate QR codes',
        isSuccess: false,
      );
      return;
    }

    context.read<TransactionCubit>().generateQRCode(
      userPhone: user.phoneNumber!,
      userName: user.displayName ?? user.email ?? 'Unknown User',
      userEmail: user.email,
      verificationRequired: _globalVerificationSetting || _verificationRequired,
      customMessage: _messageController.text.isEmpty ? null : _messageController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Generate QR Code'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: BlocBuilder<AuthSessionCubit, AuthSessionState>(
          builder: (context, authState) {
            if (authState is! AuthSessionAuthenticated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please sign in to generate QR codes',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            final user = authState.user;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.qr_code,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your QR Code',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Generate a QR code that others can scan to quickly add your contact information when creating transactions.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'User Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    user.displayName ?? user.email ?? 'Unknown User',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone Number',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    user.phoneNumber ?? 'Not set',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: user.phoneNumber != null 
                                          ? theme.colorScheme.onSurface
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (user.email != null) ...[
                          const SizedBox(height: 12),
                          Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      user.email!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  if (user.phoneNumber == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A phone number is required to generate QR codes. Please add your phone number in profile settings.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    
                    Text(
                      'QR Code Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: _verificationRequired 
                                    ? theme.colorScheme.primary 
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Require Verification',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Transactions created from this QR will require verification',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _verificationRequired,
                                onChanged: (value) {
                                  setState(() {
                                    _verificationRequired = value;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Custom Message (Optional)',
                        hintText: 'Add a personalized message',
                        prefixIcon: const Icon(Icons.message),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: BlocBuilder<TransactionCubit, TransactionState>(
                        builder: (context, state) {
                          final isLoading = state is TransactionLoading;
                          
                          return FilledButton.icon(
                            onPressed: isLoading ? null : _generateQR,
                            icon: isLoading 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.qr_code),
                            label: Text(
                              isLoading ? 'Generating...' : 'Generate QR Code',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    BlocBuilder<TransactionCubit, TransactionState>(
                      builder: (context, state) {
                        if (state is QRCodeGenerated) {
                          return QRGeneratorWidget(
                            qrData: state.qrData,
                            onShare: () => _shareQR(state.qrData),
                            onSave: () => _saveQR(state.qrData),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _shareQR(qrData) async {
    try {
      final qrService = di.sl<QrService>();
      final qrWidget = QRGeneratorWidget(qrData: qrData, showActions: false);
      final qrImageData = await qrWidget.generateQRImage();
      
      if (qrImageData != null) {
        await qrService.shareQRCode(qrImageData, 'udharoo_qr');
      } else {
        throw Exception('Failed to generate QR image');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to share QR code: ${e.toString()}',
          isSuccess: false,
        );
      }
    }
  }

  void _saveQR(qrData) async {
    try {
      final qrService = di.sl<QrService>();
      final qrWidget = QRGeneratorWidget(qrData: qrData, showActions: false);
      final qrImageData = await qrWidget.generateQRImage();
      
      if (qrImageData != null) {
        final success = await qrService.saveQRCodeToGallery(
          qrImageData, 
          'udharoo_qr_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (mounted) {
          CustomToast.show(
            context,
            message: success 
                ? 'QR code saved to gallery' 
                : 'Failed to save QR code',
            isSuccess: success,
          );
        }
      } else {
        throw Exception('Failed to generate QR image');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to save QR code: ${e.toString()}',
          isSuccess: false,
        );
      }
    }
  }
}