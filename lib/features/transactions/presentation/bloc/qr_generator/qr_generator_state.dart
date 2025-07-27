part of 'qr_generator_cubit.dart';

sealed class QRGeneratorState extends Equatable {
  const QRGeneratorState();

  @override
  List<Object?> get props => [];
}

final class QRGeneratorInitial extends QRGeneratorState {
  const QRGeneratorInitial();
}

final class QRGeneratorLoading extends QRGeneratorState {
  const QRGeneratorLoading();
}

final class QRGeneratorSuccess extends QRGeneratorState {
  final QRTransactionData qrData;
  final String qrCodeString;

  const QRGeneratorSuccess(this.qrData, this.qrCodeString);

  @override
  List<Object?> get props => [qrData, qrCodeString];
}

final class QRGeneratorError extends QRGeneratorState {
  final String message;
  final FailureType type;

  const QRGeneratorError(this.message, this.type);

  @override
  List<Object?> get props => [message, type];
}