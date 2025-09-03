
 import 'package:flutter/material.dart';

Widget setupScrollVisibilityNotification({
  required ScrollController? controller,
  required Widget child,
  required double headerHeight,
  void Function(bool, double)? onVisibilityChanged,
}) {
  double _lastScrollPosition = 0.0;
  double _currentHeaderOffset = 0.0;
  bool _isInitialized = false;

  return NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification notification){
      if (notification.metrics.axis == Axis.vertical) {
        final pixels = notification.metrics.pixels;

        // If content is too small to scroll
        if (notification.metrics.maxScrollExtent <= 0) {
          // Always keep header fully visible
          if (_currentHeaderOffset != 0.0) {
            _currentHeaderOffset = 0.0;
            onVisibilityChanged?.call(true, _currentHeaderOffset);
          }
          return false;
        }

        // Initialize on first scroll
        if (!_isInitialized) {
          _lastScrollPosition = pixels;
          _isInitialized = true;
          return false;
        }

        final delta = pixels - _lastScrollPosition;

        // Don't react to overscroll bounce or tiny jitter
        // if (delta.abs() < 3.0) {
        //   return false;
        // }

        const stepDivisor = 100.0;
        const stepClamp = 0.1;

        if (delta.abs() > 3.0) {
          if (delta > 0) {
            // Scrolling DOWN - hide header
            final hideAmount = (delta / stepDivisor).clamp(0.0, stepClamp);
            _currentHeaderOffset =
                (_currentHeaderOffset + hideAmount).clamp(0.0, 1.0);
            onVisibilityChanged?.call(false, _currentHeaderOffset);

            // 👉 Force hide if at bottom
            final atBottom = notification.metrics.pixels >=
                notification.metrics.maxScrollExtent;
            if (atBottom) {
              _currentHeaderOffset = 1.0; // fully hidden
              onVisibilityChanged?.call(false, _currentHeaderOffset);
            }
          } else if (delta < 0) {
            // 👉 Prevent auto show at bottom
            final atBottom = notification.metrics.pixels >=
                notification.metrics.maxScrollExtent;

            if (!atBottom) {
              // Scrolling UP - show header
              final showAmount = (delta.abs() / stepDivisor).clamp(
                  0.0, stepClamp);
              _currentHeaderOffset =
                  (_currentHeaderOffset - showAmount).clamp(0.0, 1.0);
              onVisibilityChanged?.call(true, _currentHeaderOffset);
            }
          }
        }

        _lastScrollPosition = pixels;
      }
      return false;
    },
    child: child,
  );

}
