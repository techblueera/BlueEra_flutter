import 'package:get/get.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';

/// Bindings for the manufacturerStoreDetailsScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class ManufacturerStoreDetailsScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManufacturerProductController>(
        () => ManufacturerProductController(),
        fenix: true);
  }
}
