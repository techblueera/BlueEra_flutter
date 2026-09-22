import 'package:get/get.dart';

/// Pops the current route without GetX's snackbar compatibility branch.
///
/// `Get.back` opens with this (extension_navigation.dart:821, marked in GetX's
/// own source as a GetX-4 compatibility shim to be removed in 5):
///
/// ```dart
/// if (isSnackbarOpen && !closeOverlays) {
///   closeCurrentSnackbar();
///   return;
/// }
/// ```
///
/// That branch carries two defects, and this app hits both.
///
///  * **It throws.** `isSnackbarOpen` reads `_snackBarQueue._isJobInProgress`,
///    which is true from the moment a snackbar is QUEUED — while
///    `SnackbarController`'s `late final AnimationController _controller` is
///    still unset. Closing it then reaches `_removeEntry` and throws
///    `LateInitializationError: Field '_controller' has not been initialized`.
///  * **It silently does not pop.** Even when the controller is ready, the
///    `return` means the route is never popped. The user taps back, the
///    snackbar disappears, and the screen stays put. No crash, no log — which
///    is why this half went unnoticed far longer than the first.
///
/// Popping through the navigator skips the shim entirely. The only behavioural
/// difference is the one that was wanted: with a snackbar on screen, back now
/// navigates instead of merely dismissing the snackbar.
///
/// Everything else matches `Get.back`: the `canPop` guard, the `result`
/// forwarding, and the nested-navigator `id` lookup are copied from it so
/// swapping one for the other changes nothing else.
void safeBack<T>({T? result, bool canPop = true, int? id}) {
  final navigator = Get.global(id).currentState;
  if (navigator == null) return;
  if (canPop && navigator.canPop() != true) return;
  navigator.pop<T>(result);
}
