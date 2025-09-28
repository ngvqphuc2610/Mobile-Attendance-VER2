
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

final ThemeData appTheme = ThemeData(
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.barcodeColor,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    showUnselectedLabels: true,
  ),
  // Thêm các theme khác nếu cần
);
