import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF0F0F0);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFF000000);
  static const accentLight = Color(0xFFEDEDED);
  static const text = Color(0xFF1A1A2E);
  static const sub = Color(0xFF8A8FA8);
  static const border = Color(0xFFE4E6F0);
  static const pill = Color(0xFFEDEDED);
  static const danger = Color(0xFFE04444);
  static const success = Color(0xFF34C759);
}

class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w900,
    color: AppColors.text, letterSpacing: -0.5,
  );
  static const title = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.text, height: 1.45,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.sub,
  );
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: AppColors.sub, letterSpacing: 0.8,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PingFang SC',
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.white,
      background: AppColors.bg,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w900,
        color: AppColors.text, letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: AppColors.sub),
    ),
  );
}
