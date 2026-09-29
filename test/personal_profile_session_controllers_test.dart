import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the profile, earn and document controllers outlive the screen that '
      'first used them', () {
    final profile = PersonalCreateProfileController.to;
    final earn = EarnProfileController.to;
    final documents = MyDocumentsController.to;
    final earnServices = EarnServiceController.to;

    // What GetX does when the route that registered them closes.
    Get.delete<PersonalCreateProfileController>();
    Get.delete<EarnProfileController>();
    Get.delete<MyDocumentsController>();
    Get.delete<EarnServiceController>();

    expect(PersonalCreateProfileController.to, same(profile));
    expect(EarnProfileController.to, same(earn));
    expect(MyDocumentsController.to, same(documents));
    expect(EarnServiceController.to, same(earnServices));
  });

  test('resetting the account drops them for the next account', () {
    PersonalCreateProfileController.to;
    EarnProfileController.to;
    MyDocumentsController.to;
    EarnServiceController.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<PersonalCreateProfileController>(), isFalse);
    expect(Get.isRegistered<EarnProfileController>(), isFalse);
    expect(Get.isRegistered<MyDocumentsController>(), isFalse);
    expect(Get.isRegistered<EarnServiceController>(), isFalse);
  });
}
