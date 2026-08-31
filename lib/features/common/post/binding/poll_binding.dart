import 'package:get/get.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';

/// Registers [PollController] for the PollInputScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class PollBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PollController>(() => PollController());
  }
}
