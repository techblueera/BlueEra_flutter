import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Wraps any scrollable subtree to drive
/// [BottomBarController.isBottomNavVisible] based on user scroll behavior.
///
/// Hides the bottom nav (and subscription peek) once the user has
/// scrolled at least [threshold] px downward in a sustained gesture;
/// restores instantly on the first upward delta. Accumulator resets on
/// scroll-end so each new gesture starts fresh.
///
/// Behavior is active only while mounted — dispose forces visibility
/// back to true so the next screen never inherits a stuck-hidden nav.
class BottomNavHideOnScroll extends StatefulWidget {
  const BottomNavHideOnScroll({
    super.key,
    required this.child,
    this.threshold = 60,
  });

  final Widget child;
  final double threshold;

  @override
  State<BottomNavHideOnScroll> createState() => _BottomNavHideOnScrollState();
}

class _BottomNavHideOnScrollState extends State<BottomNavHideOnScroll> {
  late final BottomBarController _bottomBarController =
      Get.find<BottomBarController>();
  double _accumulator = 0;

  bool _onNotification(ScrollNotification notification) {
    // Vertical-only: horizontal scrollables (auto-rotating banners,
    // category carousels, etc.) inside the page would otherwise bubble
    // their deltas up here and silently drive the accumulator.
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        if (_bottomBarController.isBottomNavVisible.value) {
          _accumulator += delta;
          if (_accumulator >= widget.threshold) {
            _bottomBarController.isBottomNavVisible.value = false;
            _accumulator = 0;
          }
        }
      } else if (delta < 0) {
        _accumulator = 0;
        if (!_bottomBarController.isBottomNavVisible.value) {
          _bottomBarController.isBottomNavVisible.value = true;
        }
      }
    } else if (notification is ScrollEndNotification) {
      _accumulator = 0;
    }
    return false;
  }

  @override
  void dispose() {
    _bottomBarController.isBottomNavVisible.value = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
