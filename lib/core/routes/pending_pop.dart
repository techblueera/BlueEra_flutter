import 'package:flutter/material.dart';

/// A route captured before an `await`, so it can be closed after one without
/// touching a `BuildContext` that may no longer be valid.
///
/// ## Why this exists
///
/// `Navigator.pop(context)` after an await is wrong in two independent ways,
/// and both have produced fatals in this app:
///
///  * **The context may be gone.** `Navigator.of` walks up from the element,
///    and if that element was disposed while the await ran it reads
///    `State.context` on a dead `State` — `_element!` — which throws "Null
///    check operator used on a null value" rather than doing nothing.
///  * **It pops whatever is on top, not you.** `pop` targets the navigator's
///    topmost route. Anything pushed over the dialog while the request was in
///    flight takes the pop instead, and if it is typed differently the result
///    is cast to ITS type: "type 'bool' is not a subtype of type 'TimeOfDay?'".
///
/// Capturing the `NavigatorState` fixes the first. Capturing the `ModalRoute`
/// and checking `isCurrent` fixes the second. They have to be captured
/// together, before the await, which is what this type is for — the two halves
/// were easy to get half-right when written by hand at each call site.
///
/// ## When NOT to use it
///
/// [close] is a no-op when the route is no longer on top, so it is wrong
/// wherever the pop *must* happen:
///
///  * a pop whose result the caller is awaiting — skipping it leaves them
///    hanging. Clear the routes above and then pop (see the availability
///    screens' `popUntil`), or redesign so nothing can be pushed meanwhile.
///  * popping more than one route, where the second pop is by definition not
///    of the captured route.
class PendingPop {
  const PendingPop._(this._navigator, this._route);

  /// Captures the route [context] currently sits in. Call this BEFORE the
  /// await — capturing afterwards defeats the whole point.
  factory PendingPop.of(BuildContext context) =>
      PendingPop._(Navigator.of(context), ModalRoute.of(context));

  final NavigatorState _navigator;
  final ModalRoute<dynamic>? _route;

  /// Whether the captured route is still live and still on top.
  ///
  /// `canPop()` is NOT a substitute for the [ModalRoute.isCurrent] half. `pop`
  /// closes whatever is on TOP, and once a dialog has been dismissed the thing
  /// on top is the screen behind it — so a "safe" pop guarded only by `canPop`
  /// cheerfully closes that screen instead.
  bool get isStillCurrent =>
      _navigator.mounted && _route?.isCurrent == true;

  /// Pops the captured route, or does nothing if it is gone or no longer on
  /// top. Safe to call from anywhere, including after several awaits.
  void close([Object? result]) {
    if (!isStillCurrent) return;
    _navigator.pop(result);
  }
}
