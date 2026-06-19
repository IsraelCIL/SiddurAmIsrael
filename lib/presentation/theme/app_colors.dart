import 'package:flutter/material.dart';

/// Centralized brand color palette for the siddur UI — the single source of
/// truth that replaces the hardcoded `Color(0x...)` literals previously
/// scattered across the presentation layer.
///
/// Note: per-category flag colors (see `flag_badge.dart`) and debug-only
/// status colors (`dev_overlay.dart`) are intentionally kept local, as they
/// are not part of the brand palette.
abstract final class AppColors {
  // ── Israel Blue ─────────────────────────────────────────────────────────
  /// Royal Blue — main header background, icons, and interactive elements.
  static const Color primary = Color(0xFF0047AB);
  /// Deep Navy — gradient top of the header block.
  static const Color primaryDark = Color(0xFF0A3663);
  /// Dark Navy — text on the cream banner; internal section headers.
  static const Color primaryDarker = Color(0xFF0B3C5D);

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Pure white — scaffold background of every screen.
  static const Color background = Color(0xFFFFFFFF);
  /// Light parchment — prayer-text panels and cards.
  static const Color surface = Color(0xFFFAF5EC);

  // ── Borders & dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFFD4C5A9);
  static const Color borderLight = Color(0xFFE0D5C5);
  static const Color divider = Color(0xFFEEE5D5);

  // ── Text ────────────────────────────────────────────────────────────────
  /// Deep navy — section headers and labels (high contrast on white).
  static const Color textPrimary = Color(0xFF0B3C5D);
  static const Color textSecondary = Color(0xFF6B5848);

  // ── Accents ─────────────────────────────────────────────────────────────
  /// Light periwinkle — subtitle text on the blue header gradient.
  static const Color headerSubtitle = Color(0xFFBDD7F0);

  /// Background of the first-launch settings-reminder banner.
  static const Color bannerBackground = Color(0xFFFFF6DE);
}
