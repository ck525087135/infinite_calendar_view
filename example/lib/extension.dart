import 'package:flutter/material.dart';

extension ColorExtension on Color {
  get pastel => HSLColor.fromColor(this)
      .withSaturation(0.65)
      .withLightness(0.87)
      .toColor();

  get onPastel => HSLColor.fromColor(this)
      .withSaturation(0.48)
      .withLightness(0.28)
      .toColor();
}
