import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/parse_qr_data_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/validate_qr_data_usecase.dart';

part 'qr_scanner_state.dart';

class QRScannerCubit extends Cubit<QRScannerState> {
  final ParseQRDataUseCase _parseQRDataUseCase;
  final ValidateQRDataUseCase _validateQRDataUseCase;
  final FirebaseAuth _firebaseAuth;

  QRScannerCubit({
    required ParseQRDataUseCase parseQRDataUseCase,
    required ValidateQRDataUseCase validateQRDataUseCase,
    FirebaseAuth? firebaseAuth,
  })  : _parseQRDataUseCase = parseQRDataUseCase,
        _validateQRDataUseCase = validateQRDataUseCase,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const QRScannerInitial());

  Future<void> processQRCode(String qrString) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      emit(const QRScannerError('User not authenticated', FailureType.auth));
      return;
    }

    if (!isClosed) {
      emit(const QRScannerLoading());
    }

    // Parse QR data
    final parseResult = await _parseQRDataUseCase(qrString);

    if (!isClosed) {
      await parseResult.fold(
        onSuccess: (qrData) async {
          // Validate QR data
          final validationResult = await _validateQRDataUseCase(
            qrData: qrData,
            currentUserId: currentUser.uid,
          );

          if (!isClosed) {
            validationResult.fold(
              onSuccess: (isValid) {
                if (isValid) {
                  emit(QRScannerSuccess(qrData));
                } else {
                  emit(const QRScannerError(
                    'Invalid QR code data',
                    FailureType.validation,
                  ));
                }
              },
              onFailure: (message, type) {
                emit(QRScannerError(message, type));
              },
            );
          }
        },
        onFailure: (message, type) {
          if (!isClosed) {
            emit(QRScannerError(message, type));
          }
        },
      );
    }
  }

  Future<void> processManualInput(String qrString) async {
    await processQRCode(qrString);
  }

  void resetState() {
    if (!isClosed) {
      emit(const QRScannerInitial());
    }
  }

  void clearError() {
    if (!isClosed && state is QRScannerError) {
      emit(const QRScannerInitial());
    }
  }
}