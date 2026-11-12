import 'package:flutter/material.dart';

/// Central corner radii tokens for Yaadibook.
class AppRadii {
  AppRadii._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  // Semantic component aliases
  static const double card = md;
  static const double input = md;
  static const double dialog = lg;
  static const double badge = sm;

  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusPill = Radius.circular(pill);

  static const BorderRadius borderXs = BorderRadius.all(radiusXs);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderPill = BorderRadius.all(radiusPill);

  // Bottom Sheet top rounded corners
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: radiusXl,
    topRight: radiusXl,
  );
}
