import 'package:get/get.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';

/// Bindings for the vehicleInformationRidingScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class VehicleInformationRidingScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryPartnerController>(() => DeliveryPartnerController(),
        fenix: true);
  }
}
