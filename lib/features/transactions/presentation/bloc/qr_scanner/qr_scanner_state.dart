part of 'qr_scanner_cubit.dart';

sealed class QRScannerState extends Equatable {
  const QRScannerState();

  @override
  List<Object?> get props => [];
}

final class QRScannerInitial extends QRScannerState {
  const QRScannerInitial();
}

final class QRScannerLoading extends QRScannerState {
  const QRScannerLoading();
}

final class QRScannerSuccess extends QRScannerState {
  final QRTransactionData qrData;

  const QRScannerSuccess(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

final class QRScannerError extends QRScannerState {
  final String message;
  final FailureType type;

  const QRScannerError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}