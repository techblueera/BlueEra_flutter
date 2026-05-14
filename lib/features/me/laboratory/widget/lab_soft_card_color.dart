import 'package:flutter/material.dart';

/// Palette of pastel backgrounds used by laboratory "test" cards.
///
/// Kept in one place so the catalog grid, the health-camp test cards and
/// any future variants stay visually consistent.
class LabSoftCardColor {
  static const List<Color> palette = [
    Color(0xFFFFFBEB), // Soft yellow / cream
    Color(0xFFF0FDF4), // Soft mint
    Color(0xFFEFF6FF), // Soft blue
    Color(0xFFFAF5FF), // Soft lavender
  ];

  /// Deterministic colour for [key] (typically the test name) so the same
  /// test always renders with the same tint, even when re-sorted.
  static Color forKey(String? key) {
    final int hash = (key?.hashCode ?? 0).abs();
    return palette[hash % palette.length];
  }

  /// Round-robin colour for the [index]-th item in a list.
  static Color forIndex(int index) => palette[index % palette.length];
}
