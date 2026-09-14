import 'package:flutter/material.dart';

class Business360Theme {
  static ThemeData light() => ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C57F5), brightness: Brightness.light);
  static ThemeData dark() => ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8B7CFF), brightness: Brightness.dark);
}
