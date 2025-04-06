import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF2196F3),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF2196F3),
    secondary: const Color(0xFF009688),
    background: const Color(0xFFE1F5FE),
    surface: const Color(0xFFFFFFFF),
    onPrimary: const Color(0xFFFFFFFF),
    onSecondary: const Color(0xFF000000),
    onBackground: const Color(0xFF000000),
    onSurface: const Color(0xFF000000),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
);