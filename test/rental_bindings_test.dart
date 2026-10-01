import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/binding/rental_bindings.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/add_flat_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/home_stay_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/stay_images_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the flat form shares its StayImagesController with the screen', () {
    AddFlatRentalBinding().dependencies();

    final form = Get.find<AddFlatRentalServiceController>();
    expect(form.stayImagesController, same(Get.find<StayImagesController>()));
    expect(Get.isRegistered<CommonMultipleImageSectionController>(), isTrue);
  });

  test('a stay listing is complete only when every photo section is uploaded',
      () {
    HomeStayRentalBinding().dependencies();
    final form = Get.find<HomeStayRentalServiceController>();
    final images = Get.find<StayImagesController>();

    expect(form.validateStepFour(images), isFalse);

    for (final section in images.sectionUploadStatus.keys.toList()) {
      images.sectionUploadStatus[section] = true;
    }
    expect(form.validateStepFour(images), isTrue);
  });

  test('a vehicle listing is complete only when every photo section is '
      'uploaded', () {
    VehicleRentalBinding().dependencies();
    final form = Get.find<VehicleRentalServiceController>();

    expect(form.validateStepFive(), isFalse);

    for (final section in form.vehicleImagesUploadStatus.keys.toList()) {
      form.vehicleImagesUploadStatus[section] = true;
    }
    expect(form.validateStepFive(), isTrue);
  });
}
