import 'package:flutter/material.dart';

/// Central color tokens for Yaadibook.
///
/// Designed with a fresh green primary palette, crisp neutral backgrounds,
/// and accessible high-contrast typography suited for outdoor/field visibility.
class AppColors {
  AppColors._();

  // Brand Primaries (Fresh Green)
  static const Color primary = Color(0xFF15803D); // Tailwind Green 700
  static const Color primaryLight = Color(0xFF22C55E); // Tailwind Green 500
  static const Color primaryDark = Color(0xFF166534); // Tailwind Green 800
  static const Color primaryContainer = Color(0xFFDCFCE7); // Tailwind Green 100
  static const Color primarySurface = primaryContainer;
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF14532D);

  // Secondary Accents (Trust Blue)
  static const Color secondary = Color(0xFF0284C7); // Tailwind Sky 600
  static const Color secondaryContainer = Color(0xFFE0F2FE); // Tailwind Sky 100
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF0369A1);

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color card = Color(0xFFFFFFFF);

  // Text & Content
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textDisabled = Color(0xFFCBD5E1); // Slate 300

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color divider = Color(0xFFE2E8F0);

  // Status & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successContainer = successBg;
  static const Color successText = Color(0xFF14532D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningContainer = warningBg;
  static const Color warningText = Color(0xFF92400E);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorContainer = errorBg;
  static const Color errorText = Color(0xFF991B1B);

  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoContainer = infoBg;
  static const Color infoText = Color(0xFF1E40AF);

  // WhatsApp brand color for direct customer contact
  static const Color whatsApp = Color(0xFF25D366);
  static const Color whatsAppBg = Color(0xFFDCF8C6);
}
