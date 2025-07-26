import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:equatable/equatable.dart';

part 'shorebird_update_state.dart';

class ShorebirdUpdateCubit extends Cubit<ShorebirdUpdateState> {
  final shorebird.ShorebirdUpdater _updater;
  bool _isCheckingForUpdates = false;

  ShorebirdUpdateCubit(this._updater) : super(const ShorebirdUpdateState.initial());

  Future<void> checkForUpdates() async {
    if (_isCheckingForUpdates) return;
    
    try {
      _isCheckingForUpdates = true;
      emit(const ShorebirdUpdateState.checking());
      
      final status = await _updater.checkForUpdate();
      
      if (status == shorebird.UpdateStatus.outdated) {
        emit(const ShorebirdUpdateState.available());
      } else {
        emit(const ShorebirdUpdateState.upToDate());
      }
    } catch (error) {
      emit(ShorebirdUpdateState.error(error.toString()));
    } finally {
      _isCheckingForUpdates = false;
    }
  }

  Future<void> downloadUpdate() async {
    try {
      emit(const ShorebirdUpdateState.downloading());
      
      await _updater.update();
      
      emit(const ShorebirdUpdateState.downloaded());
    } on shorebird.UpdateException catch (error) {
      emit(ShorebirdUpdateState.error(error.message));
    } catch (error) {
      emit(ShorebirdUpdateState.error(error.toString()));
    }
  }

  Future<int?> getCurrentPatchNumber() async {
    try {
      final currentPatch = await _updater.readCurrentPatch();
      return currentPatch?.number;
    } catch (error) {
      return null;
    }
  }

  void dismissUpdate() {
    emit(const ShorebirdUpdateState.dismissed());
  }

  void resetState() {
    emit(const ShorebirdUpdateState.initial());
  }
}