import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';
import 'package:udharoo/features/transactions/presentation/services/qr_service.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final QrService _qrService = di.sl<QrService>();
  final ImagePicker _imagePicker = ImagePicker();
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              return IconButton(
                onPressed: () => controller.toggleTorch(),
                icon: Icon(
                  state.torchState == TorchState.on 
                      ? Icons.flash_on 
                      : Icons.flash_off,
                  color: state.torchState == TorchState.on 
                      ? Colors.yellow 
                      : Colors.grey,
                ),
              );
            },
          ),
          IconButton(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          _buildScannerOverlay(),
          
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Position the QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      return _buildActionButton(
                        icon: state.torchState == TorchState.on 
                            ? Icons.flash_on 
                            : Icons.flash_off,
                        label: 'Flash',
                        onTap: () => controller.toggleTorch(),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.flip_camera_ios,
                    label: 'Flip',
                    onTap: () => controller.switchCamera(),
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: _pickImageFromGallery,
                  ),
                  _buildActionButton(
                    icon: Icons.keyboard,
                    label: 'Manual',
                    onTap: _showManualInputDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Processing QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _processScanResult(code);
        break;
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (image != null) {
        // Analyze the image using mobile_scanner
        final BarcodeCapture? result = await controller.analyzeImage(image.path);
        
        if (result != null && result.barcodes.isNotEmpty) {
          final String? qrCode = result.barcodes.first.rawValue;
          if (qrCode != null) {
            await _processScanResult(qrCode);
            return;
          }
        }
        
        // If no QR code found in image
        if (mounted) {
          CustomToast.show(
            context,
            message: 'No QR code found in the selected image',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error processing image: ${e.toString()}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter QR Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'QR Data',
                hintText: 'Paste QR code data here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('From Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context);
                _processScanResult(textController.text);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  Future<void> _processScanResult(String qrData) async {

    final result = await _qrService.parseQrData(qrData);
    
    if (!mounted) return;
    
    result.fold(
      onSuccess: (qrTransactionData) {
        context.pushReplacement(
          Routes.transactionForm,
          extra: TransactionFormScreenArguments(
            qrData: qrTransactionData,
          ),
        );
      },
      onFailure: (message, type) {
        CustomToast.show(
          context,
          message: message,
          isSuccess: false,
        );
        setState(() => _isProcessing = false);
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}