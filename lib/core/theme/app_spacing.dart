import 'package:responsive_sizer/responsive_sizer.dart';

/// Shared responsive spacing based on the 390 × 844 logical-pixel design size.
abstract final class AppSpacing {
  static const double _designWidth = 390;
  static const double _designHeight = 844;

  /// Converts a width-axis design value to a responsive screen value.
  static double width(double designValue) =>
      (designValue / _designWidth * 100).w;

  /// Converts a height-axis design value to a responsive screen value.
  static double height(double designValue) =>
      (designValue / _designHeight * 100).h;

  static double get pageHorizontal => width(20).clamp(16, 24).toDouble();
  static double get cardPadding => width(16);
  static double get inlineGap => width(8);
  static double get sectionGap => height(18);
  static double get itemGap => height(8);
}
