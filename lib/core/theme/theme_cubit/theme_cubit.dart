import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/theme/theme_cubit/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(isDarkMode: false));

  void toggleTheme() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void setDarkMode(bool isDarkMode) {
    emit(state.copyWith(isDarkMode: isDarkMode));
  }
}
