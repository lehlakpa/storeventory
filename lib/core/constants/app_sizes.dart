import 'package:flutter/widgets.dart';

class AppSizes {
  AppSizes._();

  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double spacing12 = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const screenPadding = EdgeInsets.fromLTRB(md, md, md, lg);
  static const screenHeaderPadding = EdgeInsets.fromLTRB(md, md, md, 0);
  static const cardPadding = EdgeInsets.all(md);
  static const tilePadding = EdgeInsets.all(spacing12);
  static const buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // Border Radius
  static const double radiusSM = 6.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusMax = 100.0;

  // Icon Sizes
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
}
