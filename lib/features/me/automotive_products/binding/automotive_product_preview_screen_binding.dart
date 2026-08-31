import 'package:get/get.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';

/// Bindings for the automotiveProductPreviewScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class AutomotiveProductPreviewScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AutomotiveProductController>(
        () => AutomotiveProductController(),
        fenix: true);
  }
}
