import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:get/get.dart';

/// Single entry point for opening the **logged-in user's own** profile — the
/// counterpart to [VisitProfileResolver], which opens *someone else's*.
///
/// There is no "own profile screen" to push any more. Every account lands on
/// the bottom-nav **"Me" tab**, which resolves the right screen for who they
/// are: `resolveIndividualScreen()` by profile type for individuals, and
/// `resolveBusinessScreen()` → `_buildBusinessScreen()` by business type and
/// category for businesses (Food / Grocery / School / Hospital / Hotel /
/// Product / Manufacturing / Automotive / ...). Getting there is therefore a
/// TAB SWITCH, not a route push, and that is the whole reason this needs to be
/// in one place: the switch has two branches that are easy to get subtly wrong.
///
/// This body used to be copy-pasted, byte for byte, in four places:
///   - `openMeOverview()`        in feed/widget/feed_author_header_widget.dart
///   - `_openMeOverview()`     in core/services/app_notification.dart
///   - `_redirectToMeOverview()` in notification/view/notification_screen.dart
///   - `_openMeOverview()`     in reel/widget/common_video_card.dart
/// A top-level function living in a feed *widget* file was also why half the
/// app imported a card widget purely to navigate. All four now delegate here.
class MeProfileNavigator {
  const MeProfileNavigator._();

  /// Bring the user to their own "Me" → Overview screen.
  ///
  /// Two branches, and both are needed:
  ///
  ///   • The nav shell is LIVE (the normal case — a tap from the feed, a
  ///     comment sheet, a reel). Pop whatever is stacked on top of it back to
  ///     the shell, then switch the tab. Pushing instead would bury the shell
  ///     under the pushed screen and leave Back going the wrong way.
  ///
  ///   • The shell does NOT exist yet (cold start from a notification tap,
  ///     killed app). There is no controller to ask, so route to the shell
  ///     fresh and hand it the tab index as an argument.
  ///
  /// Safe to call from anywhere, including before the first frame.
  static void openOverview() {
    if (Get.isRegistered<BottomBarController>()) {
      Get.until((route) => route.isFirst);
      Get.find<BottomBarController>().openMeOverviewTab();
    } else {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
      );
    }
  }

  /// As [openOverview], but a no-op when there is no session.
  ///
  /// Used by the notification list, where a `profile_completion_reminder` row
  /// can still be tapped after a logout — there is nothing to complete without
  /// an account, and routing a logged-out user into the Me tab shows them an
  /// empty shell.
  static void openOverviewIfLoggedIn() {
    // Same check as `isLoggedIn()`, inlined: that helper lives in
    // app_constant.dart, which imports this file, and importing it back would
    // make the two mutually dependent for a one-line null check.
    if (!(authTokenGlobal?.isNotEmpty ?? false)) return;
    openOverview();
  }

  /// Business go-live deep link: open the "Me" tab AND ask it to pop the
  /// shop-availability sheet once the profile has resolved.
  ///
  /// Used by the `go_live` notification action button and the
  /// `business_go_live_reminder` push. Both previously routed to the deleted
  /// BusinessOwnProfileScreen with `{'open_go_live': true}`, whose initState
  /// opened the sheet.
  ///
  /// The flag is set BEFORE navigating, and is static on [BottomBarController],
  /// so a tap that lands before the controller exists (cold start from a killed
  /// app) is still honoured — `_BusinessMeHost` consumes it whenever it is
  /// eventually built.
  static void openForBusinessGoLive() {
    BottomBarController.pendingBusinessGoLive = true;
    openOverview();
  }
}
