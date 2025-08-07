import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  /// Screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Screen width
  double get screenWidth => screenSize.width;

  /// Screen height
  double get screenHeight => screenSize.height;

  /// Mobile: width ≤ 600
  bool get isMobile => screenWidth <= 600;

  /// Tablet: 600 < width ≤ 900
  bool get isTablet => screenWidth > 600 && screenWidth <= 900;

  /// Large tablet: width > 900
  bool get isLargeTablet => screenWidth > 900;

  /// Responsive font size multiplier
  double get fontScale {
    if (isMobile) return 1.0;
    if (isTablet) return 1.2;
    if (isLargeTablet) return 1.4;
    return 1.0;
  }

  /// Responsive font size utility
  double responsiveFont(double baseSize) => baseSize * fontScale;

  // Additional responsive helpers for BottomNav
  bool get isSmallPhone => screenWidth < 360;

  /// Responsive value helper
  T responsiveValue<T>({required T mobile, T? tablet, T? largeTablet}) {
    if (isLargeTablet && largeTablet != null) return largeTablet;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
