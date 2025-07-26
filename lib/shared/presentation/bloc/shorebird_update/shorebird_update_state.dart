part of 'shorebird_update_cubit.dart';

enum AppUpdateStatus {
  initial,
  checking,
  available,
  downloading,
  downloaded,
  upToDate,
  dismissed,
  error,
}

class ShorebirdUpdateState extends Equatable {
  final AppUpdateStatus status;
  final String? errorMessage;

  const ShorebirdUpdateState._({
    required this.status,
    this.errorMessage,
  });

  const ShorebirdUpdateState.initial() : this._(status: AppUpdateStatus.initial);
  const ShorebirdUpdateState.checking() : this._(status: AppUpdateStatus.checking);
  const ShorebirdUpdateState.available() : this._(status: AppUpdateStatus.available);
  const ShorebirdUpdateState.downloading() : this._(status: AppUpdateStatus.downloading);
  const ShorebirdUpdateState.downloaded() : this._(status: AppUpdateStatus.downloaded);
  const ShorebirdUpdateState.upToDate() : this._(status: AppUpdateStatus.upToDate);
  const ShorebirdUpdateState.dismissed() : this._(status: AppUpdateStatus.dismissed);
  const ShorebirdUpdateState.error(String message) : this._(status: AppUpdateStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, errorMessage];
}