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
  void Function(int index)? _meSelectTabRef;

  /// Registers a back-press interceptor that animates [controller] to its
  /// first tab (index 0) when it's currently on any other tab. Call once,
  /// right after the [TabController] is created in `initState`.
  ///
  /// Also wires up deep-link tab selection: a notification tap can ask this
  /// live "Me" screen to jump to a specific internal tab (e.g. Overview), and
  /// any Overview request that arrived before this screen was built is honoured
  /// here on first frame.
  ///
  /// [overviewTabIndex] is where Overview actually sits in THIS screen's tab
  /// order. Most "Me" screens put it second and can leave the default; a screen
  /// that orders its tabs differently must pass its own, or a deep link to
  /// Overview opens whatever tab happens to be at index 1 instead.
  void registerMeTabBackHandler(
    TabController controller, {
    int overviewTabIndex = BottomBarController.meOverviewTabIndex,
  }) {
    if (!Get.isRegistered<BottomBarController>()) return;
    final bbc = Get.find<BottomBarController>();
    bool handler() {
      if (!mounted) return false;
      if (controller.index != 0) {
        controller.animateTo(0);
        return true;
      }
      return false;
    }

    _meBackHandlerRef = handler;
    bbc.meTabBackHandler = handler;

    void selectTab(int index) {
      if (!mounted) return;
      if (index >= 0 && index < controller.length && controller.index != index) {
        controller.animateTo(index);
      }
    }

    _meSelectTabRef = selectTab;
    bbc.meTabSelectTabHandler = selectTab;
    // Published so `openMeOverviewTab()` on the LIVE screen resolves Overview
    // to this screen's own index rather than the app-wide default.
    bbc.meOverviewTabIndexOverride = overviewTabIndex;

    // A deep-link (e.g. profile_completion_reminder) that landed on the "Me"
    // tab before this screen existed leaves a pending Overview request; honour
    // it once the first frame is laid out.
    if (bbc.pendingMeOverview) {
      bbc.pendingMeOverview = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectTab(overviewTabIndex);
      });
    }
  }

  void _clearMeTabBackHandler() {
    if (_meBackHandlerRef == null && _meSelectTabRef == null) return;
    if (Get.isRegistered<BottomBarController>()) {
      final bbc = Get.find<BottomBarController>();
      // Only clear if it's still ours — a newer screen may have replaced it.
      if (bbc.meTabBackHandler == _meBackHandlerRef) {
        bbc.meTabBackHandler = null;
      }
      if (bbc.meTabSelectTabHandler == _meSelectTabRef) {
        bbc.meTabSelectTabHandler = null;
        // Only ours to clear — paired with the handler above, so a newer
        // screen's override isn't wiped by this one's dispose.
        bbc.meOverviewTabIndexOverride = null;
      }
    }
    _meBackHandlerRef = null;
    _meSelectTabRef = null;
  }

  @override
  void dispose() {
    _clearMeTabBackHandler();
    super.dispose();
  }
}
