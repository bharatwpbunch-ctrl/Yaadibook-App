import 'package:flutter/widgets.dart';

/// Central spacing and dimension tokens for Yaadibook.
///
/// Follows a strict 4-8pt grid system to ensure consistent alignment and
/// generous touch targets across all device screens.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;

  // Minimum touch target size as per mobile accessibility guidelines (48x48)
  static const double minTouchTarget = 48.0;

  // Common Insets
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // Screen horizontal padding standard
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(
    horizontal: lg,
  );

  // Card inner padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  // Common Gap Widgets for Flex/Row/Column layouts
  static const SizedBox gapH4 = SizedBox(width: xs);
  static const SizedBox gapH6 = SizedBox(width: 6.0);
  static const SizedBox gapH8 = SizedBox(width: sm);
  static const SizedBox gapH12 = SizedBox(width: md);
  static const SizedBox gapH16 = SizedBox(width: lg);
  static const SizedBox gapH24 = SizedBox(width: xxl);

  static const SizedBox gapV2 = SizedBox(height: xxs);
  static const SizedBox gapV4 = SizedBox(height: xs);
  static const SizedBox gapV8 = SizedBox(height: sm);
  static const SizedBox gapV12 = SizedBox(height: md);
  static const SizedBox gapV16 = SizedBox(height: lg);
  static const SizedBox gapV20 = SizedBox(height: xl);
  static const SizedBox gapV24 = SizedBox(height: xxl);
  static const SizedBox gapV32 = SizedBox(height: xxxl);
  static const SizedBox gapV48 = SizedBox(height: massive);
}
