import 'package:flutter/material.dart';

mixin ResponsiveLayoutMixin {
  double getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    return 20.0;
  }

  double calculateExpandedHeight(double screenHeight, double topPadding, {bool hasExtendedHeader = false}) {
    if (hasExtendedHeader) {
      return screenHeight * 0.16;
    }
    return kToolbarHeight;
  }

  EdgeInsets getContentPadding(double screenWidth) {
    final horizontalPadding = getResponsiveHorizontalPadding(screenWidth);
    return EdgeInsets.all(horizontalPadding);
  }

  EdgeInsets getCardPadding(double screenWidth) {
    final horizontalPadding = getResponsiveHorizontalPadding(screenWidth);
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8);
  }
}