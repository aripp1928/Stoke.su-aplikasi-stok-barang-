import 'package:flutter/material.dart';

/// Palet warna SETOKE.SU — kopi & krem.
/// Nilainya disamakan dengan warna yang dipakai di seluruh layar,
/// supaya tema (tombol, input, snackbar, dsb.) tampil senada.
class AppColors {
  AppColors._();

  // ── Primary (cokelat kopi) ──
  static const Color primary = Color(0xFF38241D);
  static const Color primaryLight = Color(0xFF5D4037);
  static const Color primaryMedium = Color(0xFF6E5649);
  static const Color primarySoft = Color(0xFF8D7B75);

  // ── Surface / Background ──
  static const Color background = Color(0xFFFAF7F2);
  static const Color scaffoldBackground = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EAE1);

  // ── Text ──
  static const Color textPrimary = Color(0xFF2E1E19);
  static const Color textSecondary = Color(0xFF5D4E48);
  static const Color textTertiary = Color(0xFF8D7B75);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF2E1E19);

  // ── Status ──
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF1565C0);

  // ── Border / Divider ──
  static const Color border = Color(0xFFE8E3DD);
  static const Color borderLight = Color(0xFFF2ECE6);
  static const Color divider = Color(0xFFF2ECE6);

  // ── Role badges ──
  static const Color adminBadge = Color(0xFF5D4037);
  static const Color adminBadgeBg = Color(0xFFF0EAE1);
  static const Color crewBadge = Color(0xFF616161);
  static const Color crewBadgeBg = Color(0xFFF5F5F5);

  // ── Stock status ──
  static const Color stockSafe = success;
  static const Color stockLow = warning;
  static const Color stockEmpty = error;

  // ── Bottom nav ──
  static const Color navActive = Color(0xFF38241D);
  static const Color navInactive = Color(0xFFAFA49D);

  // ── Splash / Auth ──
  static const Color splashBackground = Color(0xFF2C1A12);
  static const Color authCardBackground = Color(0xFFFFFFFF);

  // ── Aksen (kartu hero & gradien) ──
  static const Color heroStart = Color(0xFF4A2F25);
  static const Color heroEnd = Color(0xFF2C1A12);
  static const Color gold = Color(0xFFD9B77E);
}
