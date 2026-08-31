import 'package:get/get.dart';
import 'package:BlueEra/features/journey/controller/journey_planning_controller.dart';

/// Registers [JourneyPlanningController] for the journeyPlanningScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class JourneyPlanningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JourneyPlanningController>(() => JourneyPlanningController());
  }
}
