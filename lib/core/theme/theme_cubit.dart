import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeInitial());

  /// Загружаем тему при старте приложения
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    emit(ThemeUpdated(isDarkMode));
  }

  /// Переключаем тему (и сохраняем в память)
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = !(state is ThemeUpdated && (state as ThemeUpdated).isDarkMode);
    await prefs.setBool('isDarkMode', isDarkMode);
    emit(ThemeUpdated(isDarkMode));
  }
}