import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/add_flat_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/home_stay_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/stay_images_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:get/get.dart';

// Each rental listing form owns its controllers through its route: GetX
// deletes them when the form closes, so the next listing starts empty.

/// The flat / room listing form's controllers.
class AddFlatRentalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StayImagesController());
    Get.lazyPut(() => CommonMultipleImageSectionController());
    Get.lazyPut(() => AddFlatRentalServiceController(
        stayImagesController: Get.find<StayImagesController>()));
  }
}

/// The home-stay listing form's controllers.
class HomeStayRentalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StayImagesController());
    Get.lazyPut(() => CommonMultipleImageSectionController());
    Get.lazyPut(() => HomeStayRentalServiceController(
        stayImagesController: Get.find<StayImagesController>()));
  }
}

/// The vehicle listing form's controllers.
class VehicleRentalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CommonMultipleImageSectionController());
    Get.lazyPut(() => VehicleRentalServiceController());
  }
}
