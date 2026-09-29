import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
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

    // What GetX does when the route that registered them closes.
    Get.delete<PersonalCreateProfileController>();
    Get.delete<EarnProfileController>();
    Get.delete<MyDocumentsController>();

    expect(PersonalCreateProfileController.to, same(profile));
    expect(EarnProfileController.to, same(earn));
    expect(MyDocumentsController.to, same(documents));
  });

  test('resetting the account drops them for the next account', () {
    PersonalCreateProfileController.to;
    EarnProfileController.to;
    MyDocumentsController.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<PersonalCreateProfileController>(), isFalse);
    expect(Get.isRegistered<EarnProfileController>(), isFalse);
    expect(Get.isRegistered<MyDocumentsController>(), isFalse);
  });
}
