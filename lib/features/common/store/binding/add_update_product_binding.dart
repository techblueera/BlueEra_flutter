import 'package:get/get.dart';
import 'package:BlueEra/features/common/store/controller/add_update_product_controller.dart';

/// Registers [AddUpdateProductController] for the addUpdateProductScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class AddUpdateProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddUpdateProductController>(() => AddUpdateProductController());
  }
}
