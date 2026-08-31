import 'package:get/get.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/rental_controller.dart';

/// Registers [RentalController] for the rentalServiceScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class RentalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentalController>(() => RentalController());
  }
}
