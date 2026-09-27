import 'package:flutter/material.dart';

/// Centralized color palette for CareMate. Keeping every brand/status
/// color here — instead of scattered `Color(0xFF...)` literals repeated
/// across a dozen screens — means the whole app's look can be tuned
/// from one place, and keeps contrast consistent everywhere at once.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFFFBF6EC); // warm cream, used app-wide
  static const surface = Colors.white; // cards, input fields
  static const cardBorder = Color(0xFFE4DDCB);

  // Brand
  static const primary = Color(0xFF1E4038); // deep teal-green: headers, primary buttons/icons
  static const secondary = Color(0xFF7FA98D); // sage green: "Taken" action, selected chips
  static const gold = Color(0xFFE9A23B); // warm accent: send button, mid-level stock bar

  // Text
  static const textPrimary = Color(0xFF1E4038);
  static const textSecondary = Color(0xFF4C6B63); // unselected chip labels, secondary copy
  static const textMuted = Color(0xFFBFAF8D); // placeholder icons

  // Semantic status
  static const successBg = Color(0xFFE4EFE6);
  static const successFg = Color(0xFF2F5B45);

  static const warningBg = Color(0xFFFBEBD2);
  // Darkened from the app's original 0xFF93611B — that combination
  // sat below comfortable reading contrast against warningBg, which
  // matters more here than on a typical app given the audience.
  static const warningFg = Color(0xFF7A4E12);

  static const dangerBg = Color(0xFFFBE3E0);
  // Darkened from the original 0xFF9A362D, same reasoning as above.
  static const dangerFg = Color(0xFF7D2A21);

  // Darkened from the original 0xFFD2574C. Used for Remove / Skip /
  // SOS — the extra contrast matters most on these.
  static const dangerMain = Color(0xFFC1493E);

  // SOS screen background gradient
  static const sosGradientStart = Color(0xFF3B1512);
  static const sosGradientEnd = primary;
}
