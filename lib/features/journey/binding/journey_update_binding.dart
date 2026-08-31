import 'package:get/get.dart';
import 'package:BlueEra/features/journey/controller/journey_update_planning_controller.dart';

/// Registers [JourneyUpdatePlanningController] for the UpdateJourneyScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class JourneyUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JourneyUpdatePlanningController>(
        () => JourneyUpdatePlanningController());
  }
}
