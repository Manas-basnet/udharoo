import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(isDarkMode: false)) {
    SharedPreferences.getInstance().then((prefs) {
      emit(state.copyWith(isDarkMode: prefs.getBool('isDarkMode') ?? false));
    });
  }
  void toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !state.isDarkMode);
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void setDarkMode(bool isDarkMode) {
    emit(state.copyWith(isDarkMode: isDarkMode));
  }
}
