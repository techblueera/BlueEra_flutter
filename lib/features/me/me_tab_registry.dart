import 'package:flutter/material.dart';

/// Lightweight registry that lets external flows (e.g. the subscription
/// payment success handler) jump whichever Me-tab screen is currently
/// mounted to its final tab — by convention the "Statistics" tab on
/// every Me screen, regardless of how many tabs that screen has.
///
/// Only one Me-screen is mounted at a time (each user-profile type maps
/// to a single Me screen via [BottomNavigationBarScreen.resolveBusinessScreen]
/// / [resolveIndividualScreen]), so a single static field is sufficient.
/// No GetX, no list — keep this dependency-free so any Me screen can
/// register without pulling in extra controllers.
class MeTabRegistry {
  static TabController? _active;

  /// Called by a Me-screen as soon as it has built its [TabController].
  /// Pass the same instance to [unregister] in `dispose()` so we don't
  /// hand out a destroyed controller later.
  ///
  /// Safe to call multiple times — e.g. when a screen rebuilds its
  /// controller after a state change (see [SocialMainScreen]).
  static void register(TabController controller) {
    _active = controller;
  }

  /// Clears the entry only if [controller] is the one currently held.
  /// Guards against an out-of-order dispose from a previous screen
  /// stomping on a freshly registered new screen.
  static void unregister(TabController controller) {
    if (identical(_active, controller)) _active = null;
  }

  /// Animates the active Me-screen TabController to its final tab.
  /// No-op if no Me screen is currently mounted or the controller has
  /// no tabs. Returns whether the jump actually happened so callers can
  /// decide on a fallback (e.g. snackbar).
  static bool goToStatisticsTab() {
    final c = _active;
    if (c == null || c.length == 0) return false;
    c.animateTo(c.length - 1);
    return true;
  }
}
