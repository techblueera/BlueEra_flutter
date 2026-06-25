import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared back-press handling for the "Me" tab business/individual home
/// screens (food, grocery, hospital, school, …).
///
/// Each of those screens owns a [TabController] whose first tab is the
/// Order / Inquiry tab. Product wants a single, consistent behaviour:
/// pressing the system/back button while on any *other* internal tab
/// (Overview, Products, Posts, Stats, …) should first hop back to that
/// first tab — only once already on the first tab does back fall through
/// to the normal bottom-nav routing (→ Discover, then exit).
///
/// The back button itself is intercepted globally by the single [PopScope]
/// in `BottomNavigationBarWidget` (a second PopScope inside the tab screens
/// caused double-fired callbacks). So instead of each screen owning a
/// PopScope, it registers a tiny interceptor on [BottomBarController] that
/// the global handler consults. This mixin wires that registration up and
/// tears it down on dispose.
///
/// Usage:
/// ```dart
/// class _FooState extends State<Foo>
///     with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
///   @override
///   void initState() {
///     super.initState();
///     _tabController = TabController(length: _tabs.length, vsync: this);
///     registerMeTabBackHandler(_tabController);
///   }
/// }
/// ```
mixin MeTabBackHandlerMixin<T extends StatefulWidget> on State<T> {
  bool Function()? _meBackHandlerRef;

  /// Registers a back-press interceptor that animates [controller] to its
  /// first tab (index 0) when it's currently on any other tab. Call once,
  /// right after the [TabController] is created in `initState`.
  void registerMeTabBackHandler(TabController controller) {
    if (!Get.isRegistered<BottomBarController>()) return;
    bool handler() {
      if (!mounted) return false;
      if (controller.index != 0) {
        controller.animateTo(0);
        return true;
      }
      return false;
    }

    _meBackHandlerRef = handler;
    Get.find<BottomBarController>().meTabBackHandler = handler;
  }

  void _clearMeTabBackHandler() {
    if (_meBackHandlerRef == null) return;
    if (Get.isRegistered<BottomBarController>()) {
      final bbc = Get.find<BottomBarController>();
      // Only clear if it's still ours — a newer screen may have replaced it.
      if (bbc.meTabBackHandler == _meBackHandlerRef) {
        bbc.meTabBackHandler = null;
      }
    }
    _meBackHandlerRef = null;
  }

  @override
  void dispose() {
    _clearMeTabBackHandler();
    super.dispose();
  }
}
