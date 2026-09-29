import 'package:BlueEra/features/common/notification/controller/notification_hub_controller.dart';
import 'package:get/get.dart';

/// Scopes a [NotificationHubController] to the notification hub route
/// (NotificationScreen); GetX deletes it when that screen closes. The list
/// itself stays in the permanent NotificationCacheService.
class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationHubController());
  }
}
