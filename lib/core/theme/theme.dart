import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800], // Темный фон для полей ввода
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 34, 34, 34),
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.all(Colors.grey[650]),
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 34, 34, 34), // Темный фон для нижнего меню
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
  );
}