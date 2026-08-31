import 'package:get/get.dart';
import 'package:BlueEra/features/common/map/controller/category_controller.dart';

/// Registers [CategoryController] for the categorySelectionScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class CategorySelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryController>(() => CategoryController());
  }
}
