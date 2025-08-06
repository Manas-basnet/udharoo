import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class MultiSelectModeState extends Equatable {
  final bool isMultiSelectMode;

  const MultiSelectModeState({this.isMultiSelectMode = false});

  @override
  List<Object> get props => [isMultiSelectMode];
}

class MultiSelectModeCubit extends Cubit<MultiSelectModeState> {
  MultiSelectModeCubit() : super(const MultiSelectModeState());

  void enterMultiSelectMode() {
    emit(const MultiSelectModeState(isMultiSelectMode: true));
  }

  void exitMultiSelectMode() {
    emit(const MultiSelectModeState(isMultiSelectMode: false));
  }
}