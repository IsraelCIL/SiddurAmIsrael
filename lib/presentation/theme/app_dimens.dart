/// Centralized layout / sizing constants for the presentation layer.
abstract final class AppDimens {
  // ── Prayer font scaling ─────────────────────────────────────────────────
  // Shared by the FontSizeFab (+/- buttons) and the Settings slider so the
  // bounds stay in lockstep.
  static const double fontFactorMin = 0.6;
  static const double fontFactorMax = 1.6;
  static const double fontFactorStep = 0.1;
  static const int fontFactorDivisions = 10;
}
