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
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // `route` is what was just pushed; when that is the menu itself,
    // `previousRoute` is the ordinary page underneath and nothing happens.
    _dismiss(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss(oldRoute);
  }

  void _dismiss(Route<dynamic>? route) {
    if (route == null || !_isAnchoredMenu(route)) return;
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
