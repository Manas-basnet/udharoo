part of 'qr_code_cubit.dart';

sealed class QRCodeState extends Equatable {
  const QRCodeState();

  @override
  List<Object?> get props => [];
}

final class QRCodeInitial extends QRCodeState {
  const QRCodeInitial();
}

final class QRCodeGenerating extends QRCodeState {
  const QRCodeGenerating();
}

final class QRCodeGenerated extends QRCodeState {
  final QRData qrData;

  const QRCodeGenerated(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

final class QRCodeParsing extends QRCodeState {
  const QRCodeParsing();
}

final class QRCodeParsed extends QRCodeState {
  final QRData qrData;

  const QRCodeParsed(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

final class QRCodeError extends QRCodeState {
  final String message;
  final FailureType type;

  const QRCodeError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}