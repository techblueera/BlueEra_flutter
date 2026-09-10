import 'package:flutter/foundation.dart';

/// The go-live action belonging to the Me screen that is currently on show.
///
/// The "You're offline" nudge sheet and the Go-Live pill must do THE SAME
/// THING. They didn't: the pill on a catalogue screen (food, grocery, product,
/// manufacturing, pharmacy, auto parts, vehicles) runs
/// `ensureCatalogueBeforeGoLive` before `toggleLiveNow()`, while the sheet
/// called `toggleLiveNow()` directly — so a merchant with an empty shop could
/// go live from the sheet but not from the pill two inches above it, and land
/// live with nothing for a customer to order.
///
/// The obvious fix — teach the nudge host about catalogues — doesn't work: the
/// host sits ABOVE the per-type screen and has no access to the catalogue
/// controller, the spec or the "add items" callback, all of which differ per
/// screen. So the screen publishes its own handler instead, and it does it
/// from [GoLivePill] rather than from thirteen `initState`s: every one of
/// those screens already hands the pill exactly the callback the sheet wants.
///
/// A screen that renders no pill registers nothing, and the nudge falls back to
/// the plain toggle — which is precisely right for the un-gated screens
/// (school, hotel, lab, hospital, other services), whose pill IS the plain
/// toggle.
class GoLiveAction {
  const GoLiveAction._();

  static VoidCallback? _current;
  static Object? _owner;

  /// The visible pill's action, or null when nothing has registered one.
  static VoidCallback? get current => _current;

  /// Called by [GoLivePill] on mount. Last one wins: a screen that has just
  /// been built is the one the user is looking at.
  static void register(Object owner, VoidCallback action) {
    _owner = owner;
    _current = action;
  }

  /// Called by [GoLivePill] on dispose — but only clears if [owner] is still
  /// the registered one.
  ///
  /// The ownership test matters because Flutter builds the incoming screen
  /// BEFORE disposing the outgoing one. Clearing unconditionally would let a
  /// screen being torn down wipe the registration its replacement just made,
  /// leaving the nudge on the fallback toggle for a screen that needs a gate.
  static void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _current = null;
  }
}
