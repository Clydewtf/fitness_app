part of 'theme_cubit.dart';

abstract class ThemeState {}

class ThemeInitial extends ThemeState {}

class ThemeUpdated extends ThemeState {
  final bool isDarkMode;
  ThemeUpdated(this.isDarkMode);
}