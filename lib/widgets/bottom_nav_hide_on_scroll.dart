import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Wraps a scrollable subtree to drive [BottomBarController.isBottomNavVisible]
/// from the scroll **direction**:
///   * a sustained scroll **down** past [threshold] px hides the bottom nav,
///   * any scroll **up** restores it instantly.
///
/// The bottom nav lives in `BottomNavigationBarScreen`, which listens to
/// `isBottomNavVisible` and slides the bar in/out — so this wrapper only flips
/// that one flag.
///
/// **Single source of truth:** there is exactly one of these, mounted once in
/// `BottomNavigationBarScreen` around `_getScreen(...)`. Because it only reads
/// bubbling [ScrollNotification]s, that single wrapper covers every tab and
/// every "Me" sub-screen (individual + business) without each screen having to
/// opt in. Do **not** add another one inside a child screen — that would put two
/// listeners on the same flag.
///
/// Pass [enabled] = false to opt a screen out entirely (pure pass-through).
class BottomNavHideOnScroll extends StatefulWidget {
  const BottomNavHideOnScroll({
    super.key,
    required this.child,
    this.threshold = 60,
    this.enabled = true,
  });

  final Widget child;

  /// Px of sustained downward scroll before the bar hides.
  final double threshold;

  /// Master switch. When false this is a no-op pass-through.
  final bool enabled;

  @override
  State<BottomNavHideOnScroll> createState() => _BottomNavHideOnScrollState();
}

class _BottomNavHideOnScrollState extends State<BottomNavHideOnScroll> {
  BottomBarController get _bottomBar => Get.put(BottomBarController());

  double _accumulator = 0;

  bool _onNotification(ScrollNotification notification) {
    if (!widget.enabled) return false;
    // Vertical-only: horizontal carousels (banners, category rails) and the
    // horizontal TabBarView swipe must not drive the bar's visibility.
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        // Scrolling content up (finger up) — accumulate, then hide past the
        // threshold so a tiny nudge doesn't flicker the bar.
        if (_bottomBar.isBottomNavVisible.value) {
          _accumulator += delta;
          if (_accumulator >= widget.threshold) {
            _bottomBar.isBottomNavVisible.value = false;
            _accumulator = 0;
          }
        }
      } else if (delta < 0) {
        // Any upward scroll restores the bar immediately.
        _accumulator = 0;
        if (!_bottomBar.isBottomNavVisible.value) {
          _bottomBar.isBottomNavVisible.value = true;
        }
      }
    } else if (notification is ScrollEndNotification) {
      _accumulator = 0;
    }
    // Bubble up so inner listeners (search-header collapse, reels autoplay,
    // pagination) keep receiving the same notifications.
    return false;
  }

  @override
  void dispose() {
    // Never let the next screen inherit a stuck-hidden nav.
    if (widget.enabled && Get.isRegistered<BottomBarController>()) {
      Get.find<BottomBarController>().isBottomNavVisible.value = true;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
