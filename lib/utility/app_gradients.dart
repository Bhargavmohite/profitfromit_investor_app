import 'package:flutter/material.dart';

class AppGradients {
  // Blue Gradient
  static const LinearGradient blue = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF082EAF), // Start
      Color(0xFF6484ED), // Middle
      Color(0xFFFFFFFF), // End
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Green Gradient
  static const LinearGradient green = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF16A34A), // Start
      Color(0xFF63ED94), // Middle
      Color(0xFFFFFFFF), // End
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Red Gradient
  static const LinearGradient red = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFDC2626), // Start
      Color(0xFFEF6464), // Middle
      Color(0xFFFFFFFF), // End
    ],
    stops: [0.0, 0.5, 1.0],
  );
}