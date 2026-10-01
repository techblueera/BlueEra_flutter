import 'package:BlueEra/features/common/Discover/controller/stay_discover_controller.dart';
import 'package:get/get.dart';

/// Scopes a [StayDiscoverController] to the stays listing route
/// (AllStayServiceScreen); GetX deletes it when that screen closes.
class StayDiscoverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StayDiscoverController());
  }
}
