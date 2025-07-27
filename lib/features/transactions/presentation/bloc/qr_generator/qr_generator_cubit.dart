import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_transaction_data.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_code_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/qr/generate_qr_usecase.dart';

part 'qr_generator_state.dart';

class QRGeneratorCubit extends Cubit<QRGeneratorState> {
  final GenerateQRDataUseCase _generateQRDataUseCase;
  final GenerateQRCodeUseCase _generateQRCodeUseCase;
  final FirebaseAuth _firebaseAuth;

  QRGeneratorCubit({
    required GenerateQRDataUseCase generateQRDataUseCase,
    required GenerateQRCodeUseCase generateQRCodeUseCase,
    FirebaseAuth? firebaseAuth,
  })  : _generateQRDataUseCase = generateQRDataUseCase,
        _generateQRCodeUseCase = generateQRCodeUseCase,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const QRGeneratorInitial());

  Future<void> generateQRCode({
    TransactionType? transactionTypeConstraint,
    Duration? validityDuration,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      emit(const QRGeneratorError('User not authenticated', FailureType.auth));
      return;
    }

    if (!isClosed) {
      emit(const QRGeneratorLoading());
    }

    // Generate QR data
    final qrDataResult = await _generateQRDataUseCase(
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Unknown User',
      phoneNumber: currentUser.phoneNumber ?? '',
      email: currentUser.email,
      transactionTypeConstraint: transactionTypeConstraint,
      validityDuration: validityDuration,
    );

    if (!isClosed) {
      await qrDataResult.fold(
        onSuccess: (qrData) async {
          // Generate QR code string
          final qrCodeResult = await _generateQRCodeUseCase(qrData);
          
          if (!isClosed) {
            qrCodeResult.fold(
              onSuccess: (qrString) {
                emit(QRGeneratorSuccess(qrData, qrString));
              },
              onFailure: (message, type) {
                emit(QRGeneratorError(message, type));
              },
            );
          }
        },
        onFailure: (message, type) {
          if (!isClosed) {
            emit(QRGeneratorError(message, type));
          }
        },
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const QRGeneratorInitial());
    }
  }

  void updateTransactionType(TransactionType? transactionType) {
    final currentState = state;
    if (currentState is QRGeneratorSuccess) {
      // Regenerate QR code with new constraint
      generateQRCode(
        transactionTypeConstraint: transactionType,
        validityDuration: currentState.qrData.expiresAt?.difference(currentState.qrData.createdAt),
      );
    }
  }

  void setValidityDuration(Duration? duration) {
    final currentState = state;
    if (currentState is QRGeneratorSuccess) {
      // Regenerate QR code with new validity
      generateQRCode(
        transactionTypeConstraint: currentState.qrData.transactionTypeConstraint,
        validityDuration: duration,
      );
    }
  }
}