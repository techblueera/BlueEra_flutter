import 'package:get/get.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';

/// Registers [FoodUploadController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<FoodUploadController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class FoodUploadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FoodUploadController>(() => FoodUploadController(),
        fenix: true);
  }
}
