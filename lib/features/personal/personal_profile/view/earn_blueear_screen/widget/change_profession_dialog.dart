import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showProfessionChangeDialog({
  required BuildContext context,
  required String designation,
  required EarnWithBlueEraServiceTypes serviceSubType,
}) async {
  await showCommonDialog(
    context: context,
    text: 'Your profession and work type will be changed. Continue?',
    confirmText: 'Update',
    cancelText: 'Cancel',
    confirmCallback: () async {
      final personalCreateProfileController =
      Get.isRegistered<PersonalCreateProfileController>()
          ? Get.find<PersonalCreateProfileController>()
          : Get.put(PersonalCreateProfileController());

      await personalCreateProfileController
          .updateUserProfileProfessionDesignation(
        params: {
          ApiKeys.profession: SELF_EMPLOYED,
          ApiKeys.designation: designation,
        },
      );

      Get.offNamedUntil(
        RouteHelper.getAddServicesScreenRoute(),
        ModalRoute.withName(RouteHelper.getEarnWithBlueEraNewScreenRoute()),
        arguments: {
          ApiKeys.providerType: ProductServiceProviderType.user,
          ApiKeys.isFromEarnWithBlueEraService: true,
          ApiKeys.designation: designation,
          ApiKeys.serviceSubType: serviceSubType,
        },
      );
    },
    cancelCallback: () {
      Get.back();
    },
  );
}
