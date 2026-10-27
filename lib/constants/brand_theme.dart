import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
}

class AppShadow {
  AppShadow._();
  static const card = [
    BoxShadow(color: Color(0x0F101828), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1A101828), blurRadius: 24, offset: Offset(0, -4)),
  ];
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.border,
      centerTitle: false,
      titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.muted),
      labelStyle: text.bodyMedium?.copyWith(color: AppColors.textSoft),
      floatingLabelStyle: text.bodyMedium?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.w600),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
      focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.4)),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        minimumSize: const Size(64, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        minimumSize: const Size(64, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
      labelStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.onPrimary,
      unselectedLabelColor: AppColors.textSoft,
      indicatorColor: AppColors.primary,
      dividerColor: AppColors.divider,
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      tabAlignment: TabAlignment.start,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
