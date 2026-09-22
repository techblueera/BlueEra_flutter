import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Not exported from `package:get/get.dart` — only the bottom sheet route is.
// Reaching into src is deliberate: it keeps the check below a compile-time
// type test, so a `get` upgrade that moves this file breaks the build instead
// of silently turning the exclusion into a no-op in production.
import 'package:get/get_navigation/src/dialog/dialog_route.dart';

/// Closes an open anchor-positioned menu — `PopupMenuButton`, `DropdownButton`
/// — when a route is pushed over it.
///
/// Flutter recomputes a popup menu's position on *every* layout of the menu
/// route, in `PopupMenuButtonState._positionBuilder`. That closure guards
/// `mounted` and `RenderBox.attached`, but not "has this been laid out". So a
/// menu that survives into a frame where its anchor's page has gone offstage
/// reaches `button.localToGlobal()` against a subtree with no size and throws
/// `RenderBox was not laid out: RenderFractionalTranslation` — the
/// `FractionalTranslation` being the page's slide transition.
///
/// A page goes offstage for exactly one frame without being unmounted:
/// `_ModalScopeState` wraps every route in `Offstage(offstage: route.offstage)`
/// and `HeroController.startTransition` sets that flag to measure where heroes
/// land. Mounted and attached both still hold, so all three framework guards
/// pass. See https://github.com/flutter/flutter/issues/171422 for the partial
/// fix this gap survives.
///
/// Dismissing on push closes the window, and matches what a user expects when
/// they navigate away with a menu open.
class AnchoredMenuDismissObserver extends NavigatorObserver {
  /// The anchored menu currently on top, if any.
  ///
  /// Tracked rather than derived from each callback's arguments, because for
  /// half the navigation events the menu is not one of them. `didPush` hands
  /// over the pushed route and the one under it, so an open menu IS the
  /// `previousRoute` and can be recognised — but `didPop` and `didRemove` hand
  /// over the route that went and the one revealed, and when something else in
  /// the history is popped or removed out from under a menu, the menu is
  /// neither. `NavigatorObserver` exposes no way to enumerate history, so the
  /// only way to reach it is to have kept a reference from when it was pushed.
  ///
  /// The earlier version of this class only overrode `didPush`/`didReplace`
  /// and looked at the arguments, so `Get.offAll`, `Get.until` and a
  /// programmatic `removeRoute` on the page beneath an open menu all slipped
  /// through — which is why the crash survived into 14.0.88+347.
  Route<dynamic>? _openMenu;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isAnchoredMenu(route)) {
      _openMenu = route;
      return;
    }
    _dismissOpenMenu();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _forget(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _forget(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null && identical(oldRoute, _openMenu)) {
      _openMenu = null;
    }
    if (newRoute != null && _isAnchoredMenu(newRoute)) {
      _openMenu = newRoute;
      return;
    }
    _dismissOpenMenu();
  }

  /// The menu leaving by itself — dismissed by a tap outside, or a selection —
  /// is the ordinary case and needs no action beyond dropping the reference.
  /// Anything else leaving while a menu is open is the dangerous one.
  void _forget(Route<dynamic> route) {
    if (identical(route, _openMenu)) {
      _openMenu = null;
      return;
    }
    _dismissOpenMenu();
  }

  void _dismissOpenMenu() {
    final Route<dynamic>? route = _openMenu;
    if (route == null) return;
    _openMenu = null;
    // Not synchronously: observers run inside the navigator's history flush,
    // and mutating history from there re-enters it. A microtask still lands
    // before the next frame builds and lays out, which is the frame that would
    // crash — a post-frame callback would be one frame too late.
    scheduleMicrotask(() {
      if (route.isActive) navigator?.removeRoute(route);
    });
  }

  /// Dialogs and bottom sheets are `PopupRoute`s too, but they have no anchor
  /// to measure, and app flows legitimately push routes from inside them, so
  /// tearing them down here would break those. What is left is the anchored
  /// set: `_PopupMenuRoute`, `_DropdownRoute`, `_SearchViewRoute` — all
  /// private, hence the exclusions rather than a positive test.
  static bool _isAnchoredMenu(Route<dynamic> route) =>
      route is PopupRoute &&
      route is! RawDialogRoute &&
      route is! ModalBottomSheetRoute &&
      route is! GetDialogRoute &&
      route is! GetModalBottomSheetRoute;
}
