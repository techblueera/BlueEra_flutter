import 'package:get/get.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_two_controller.dart';

/// Registers [AddPlaceStepTwoController] for the addPlaceStepTwo route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class AddPlaceStepTwoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddPlaceStepTwoController>(() => AddPlaceStepTwoController());
  }
}
