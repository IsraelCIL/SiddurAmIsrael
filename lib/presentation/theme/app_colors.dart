import 'package:flutter/material.dart';

/// Centralized brand color palette for the siddur UI — the single source of
/// truth that replaces the hardcoded `Color(0x...)` literals previously
/// scattered across the presentation layer.
///
/// Note: per-category flag colors (see `flag_badge.dart`) and debug-only
/// status colors (`dev_overlay.dart`) are intentionally kept local, as they
/// are not part of the brand palette.
abstract final class AppColors {
  // ── Brand burgundy ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF8B1A1A);
  static const Color primaryDark = Color(0xFF6B1212);
  static const Color primaryDarker = Color(0xFF5A1010);

  // ── Parchment / surfaces ────────────────────────────────────────────────
  static const Color background = Color(0xFFFDF8F0);
  static const Color surface = Color(0xFFFAF5EC);

  // ── Borders & dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFFD4C5A9);
  static const Color borderLight = Color(0xFFE0D5C5);
  static const Color divider = Color(0xFFEEE5D5);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3A2E22);
  static const Color textSecondary = Color(0xFF6B5848);

  // ── Accents ─────────────────────────────────────────────────────────────
  /// Pink subtitle text on the burgundy header gradient.
  static const Color headerSubtitle = Color(0xFFFFCDD2);

  /// Background of the first-launch settings-reminder banner.
  static const Color bannerBackground = Color(0xFFFFF6DE);
}
