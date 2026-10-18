import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF070B10);
  static const surface = Color(0xFF111821);
  static const sheet = Color(0xFF0E151D);
  static const text = Color(0xFFF2F5F7);
  static const muted = Color(0xFF8E9AA6);
  static const mint = Color(0xFF3DF5C0);
  static const sky = Color(0xFF4CC9F0);
  static const amber = Color(0xFFFFB547);
  static const coral = Color(0xFFFF5D73);
  static const violet = Color(0xFF8B7CFF);

  static const brandGradient = LinearGradient(
    colors: [mint, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Text style: Plus Jakarta Sans for Latin, Noto Sans Devanagari (same weight)
/// as fallback so Hindi renders with matching weight.
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.text,
  double? height,
  double letterSpacing = 0,
}) {
  final deva = GoogleFonts.notoSansDevanagari(fontWeight: weight).fontFamily!;
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: [deva]);
}

TextStyle display(double size, {Color color = AppColors.text}) =>
    ts(size, weight: FontWeight.w800, color: color, letterSpacing: -0.6, height: 1.15);

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF16202A),
      contentTextStyle: ts(14, weight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    datePickerTheme: const DatePickerThemeData(backgroundColor: AppColors.surface),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
    ));
}
