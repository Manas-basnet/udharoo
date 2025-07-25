import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/features/transactions/domain/entities/qr_data.dart';
import 'package:udharoo/features/transactions/domain/usecases/generate_qr_usecase.dart';
import 'package:udharoo/features/transactions/domain/usecases/parse_qr_usecase.dart';

part 'qr_code_state.dart';

class QRCodeCubit extends Cubit<QRCodeState> {
  final GenerateQRUseCase generateQRUseCase;
  final ParseQRUseCase parseQRUseCase;

  QRCodeCubit({
    required this.generateQRUseCase,
    required this.parseQRUseCase,
  }) : super(const QRCodeInitial());

  Future<void> generateQRCode({
    required String userPhone,
    required String userName,
    String? userEmail,
    required bool verificationRequired,
    String? customMessage,
  }) async {
    emit(const QRCodeGenerating());

    final result = await generateQRUseCase(
      userPhone: userPhone,
      userName: userName,
      userEmail: userEmail,
      verificationRequired: verificationRequired,
      customMessage: customMessage,
    );

    if (!isClosed) {
      result.fold(
        onSuccess: (qrData) => emit(QRCodeGenerated(qrData)),
        onFailure: (message, type) => emit(QRCodeError(message, type)),
      );
    }
  }

  Future<void> parseQRCode(String qrCodeData) async {
    emit(const QRCodeParsing());

    final result = await parseQRUseCase(qrCodeData);

    if (!isClosed) {
      result.fold(
        onSuccess: (qrData) => emit(QRCodeParsed(qrData)),
        onFailure: (message, type) => emit(QRCodeError(message, type)),
      );
    }
  }

  void resetState() {
    if (!isClosed) {
      emit(const QRCodeInitial());
    }
  }
}