import 'dart:async';

import 'package:flutter/material.dart';

/// LinkedIn-style scroll hide/show for header and bottom nav.
/// Scroll down → hide, scroll up → show. Snaps on direction change.
class ScrollVisibilityNotifier extends StatefulWidget {
  final ScrollController? controller;
  final Widget child;
  final double? headerHeight;
  final void Function(bool visible, double offset)? onVisibilityChanged;

  const ScrollVisibilityNotifier({
    super.key,
    required this.controller,
    required this.child,
    this.headerHeight,
    this.onVisibilityChanged,
  });

  @override
  State<ScrollVisibilityNotifier> createState() =>
      _ScrollVisibilityNotifierState();
}

class _ScrollVisibilityNotifierState extends State<ScrollVisibilityNotifier> {
  double _lastScrollPosition = 0.0;
  bool _isHeaderVisible = true;
  bool _isInitialized = false;
  Timer? _idleTimer;

  /// Minimum scroll delta to trigger show/hide
  static const double _scrollThreshold = 5.0;


  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final pixels = notification.metrics.pixels;

    // Content too small to scroll — always show
    if (notification.metrics.maxScrollExtent <= 0) {
      if (!_isHeaderVisible) {
        _isHeaderVisible = true;
        widget.onVisibilityChanged?.call(true, 0.0);
      }
      return false;
    }

    // Initialize on first event
    if (!_isInitialized) {
      _lastScrollPosition = pixels;
      _isInitialized = true;
      return false;
    }

    final delta = pixels - _lastScrollPosition;

    // Ignore tiny jitter
    if (delta.abs() < _scrollThreshold) return false;

    if (delta > 0 && _isHeaderVisible) {
      // Scrolling DOWN — hide header + bottom nav
      _isHeaderVisible = false;
      widget.onVisibilityChanged?.call(false, 1.0);
    } else if (delta < 0 && !_isHeaderVisible) {
      // Scrolling UP — show header + bottom nav
      _isHeaderVisible = true;
      widget.onVisibilityChanged?.call(true, 0.0);
    }

    _lastScrollPosition = pixels;
    _resetIdleTimer();
    return false;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}

/// Convenience function — backward compatible wrapper.
Widget setupScrollVisibilityNotification({
  required ScrollController? controller,
  required Widget child,
  double? headerHeight,
  void Function(bool, double)? onVisibilityChanged,
}) {
  return ScrollVisibilityNotifier(
    controller: controller,
    headerHeight: headerHeight,
    onVisibilityChanged: onVisibilityChanged,
    child: child,
  );
}
