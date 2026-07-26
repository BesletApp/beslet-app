/// 🚨 DO NOT MODIFY VALUES WITHOUT DESIGN SYSTEM APPROVAL
/// These values are tied directly to BESLET rules (R12-R14).
/// Changing them WILL break visual consistency across the app.
class AppSpacing {
  // Existing tokens (KEEP)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // 🔒 ENFORCEMENT CONSTANTS (NON-NEGOTIABLE)
  // These values enforce layout rhythm.
  // DO NOT change without system-wide redesign.

  /// Space between zones (Z1 -> Z2 -> Z3 -> Z4). R12.
  static const double zoneGap = 24.0;

  /// Horizontal screen padding. R13.
  static const double screenPadding = 20.0;

  /// Bottom padding after the last zone. R14.
  static const double bottomPadding = 32.0;

  /// Internal padding inside cards.
  static const double cardPadding = 16.0;
}
