import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// Responsive type sizes based on the app's design size.
abstract final class AppTypography {
  static double size(double designSize) => designSize.sp;

  static double get caption => size(11);
  static double get label => size(13);
  static double get body => size(15);
  static double get bodyEmphasis => size(16);
  static double get title => size(20);
  static double get pageTitle => size(24);
  static double get display => size(30);
}

/// Shared mobile typography. Sizes are logical pixels and retain Flutter's
/// system text scaling; exceptional display and brand treatments may override.
abstract final class AppTextStyles {
  static const double captionSize = 12;
  static const double labelSize = 13;
  static const double bodySize = 14;
  static const double buttonSize = 16;
  static const double sectionTitleSize = 17;
  static const double pageTitleSize = 24;

  // Colors are inherited by default so existing themed and state colors remain
  // intact. Use copyWith for emphasis, color, or an exceptional size.
  static const TextStyle caption = TextStyle(fontSize: captionSize);
  static const TextStyle label = TextStyle(fontSize: labelSize);
  static const TextStyle body = TextStyle(fontSize: bodySize);
  static const TextStyle button = TextStyle(
    fontSize: buttonSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: sectionTitleSize,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle pageTitle = TextStyle(
    fontSize: pageTitleSize,
    fontWeight: FontWeight.w800,
  );
}
