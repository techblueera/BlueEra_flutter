import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:get/get.dart';

/// Closes a post-creation flow after the post was saved and asks the bottom
/// bar to refresh the feed.
void returnToFeedAfterPosting() {
  Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = true;
  Get.until((route) =>
      route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
}
