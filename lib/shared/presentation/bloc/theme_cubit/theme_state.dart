part of 'theme_cubit.dart';

class ThemeState {
  final bool isDarkMode;

  const ThemeState({required this.isDarkMode});

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}
