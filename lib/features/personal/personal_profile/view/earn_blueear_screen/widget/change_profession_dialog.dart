import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showProfessionChangeDialog({
  required BuildContext context,
  required String designation,
  EarnWithBlueEraServiceTypes? serviceSubType,
}) async {

  final viewPersonalDetailsController = Get.isRegistered<ViewPersonalDetailsController>()
      ? Get.find<ViewPersonalDetailsController>()
      : Get.put(ViewPersonalDetailsController());

  final controller = Get.isRegistered<PersonalCreateProfileController>()
      ? Get.find<PersonalCreateProfileController>()
      : Get.put(PersonalCreateProfileController());


  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Obx(() {
        final isLoading = controller.updateBtnLoading.value;

        return AbsorbPointer(
          absorbing: isLoading,
          child: Dialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: Get.width,
                      color: AppColors.primaryColor,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                      ),
                      child: CustomText(
                        AppStrings.confirm,
                        color: Colors.white,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Message text
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                      ),
                      child: CustomText(
                        AppStrings.professionChangeMsg,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Buttons
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              bgColor: isLoading
                                  ? AppColors.grey9A.withValues(alpha: 0.4)
                                  : AppColors.white,
                              borderColor: isLoading
                                  ? Colors.grey.shade400
                                  : AppColors.primaryColor,
                              textColor: isLoading
                                  ? Colors.grey
                                  : AppColors.primaryColor,
                              onTap: isLoading
                                  ? null
                                  : () async {
                                await controller.updateUserProfileDetails(
                                  params: {
                                    ApiKeys.profession: SELF_EMPLOYED,
                                    ApiKeys.designation: designation,
                                  },
                                );

                                if(designation == AppConstants.DELIVERY_PARTNER){
                                  _onDeliveryPartnerOnClick();
                                }else{
                                  await Get.offNamedUntil(
                                    RouteHelper.getAddServicesScreenRoute(),
                                    ModalRoute.withName(
                                      RouteHelper
                                          .getEarnWithBlueEraNewScreenRoute(),
                                    ),
                                    arguments: {
                                      ApiKeys.providerType: ProductServiceProviderType.user,
                                      ApiKeys.isFromEarnWithBlueEraService: true,
                                      ApiKeys.designation: designation,
                                      ApiKeys.serviceSubType: serviceSubType,
                                    },
                                  );

                                  log('change and update is earn service added or not');
                                  viewPersonalDetailsController.getEarnServiceStatus();
                                }
                              },
                              title: AppStrings.updating,
                              // isLoading ? AppStrings.updating : AppStrings.update,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: PositiveCustomBtn(
                              onTap: () {
                                if (!isLoading) Get.back();
                              },
                              title: AppStrings.cancel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size15),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    },
  );
}

void _onDeliveryPartnerOnClick() {
  final controller = Get.find<DeliveryPartnerController>();
  final stepStatus = controller.stepStatus;

  if (stepStatus.isEmpty) {
    Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
    return;
  }

  // Check if all completed
  final allCompleted = stepStatus.values.every((status) => status == true);

  if (allCompleted) {
    commonSnackBar(message: AppStrings.allStepsSubmitted.tr);
    return;
  }

  // Find first incomplete step
  final firstIncompleteEntry =
  stepStatus.entries.firstWhere((entry) => entry.value == false);

  switch (firstIncompleteEntry.key) {
    case RiderProfileStep.personalInfo:
      Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
      break;
    case RiderProfileStep.addressInfo:
      Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
      break;
    case RiderProfileStep.personalIdentificationInfo:
      Get.toNamed(RouteHelper.getPersonalIdentificationRidingScreenRoute());
      break;
    case RiderProfileStep.drivingInfo:
      Get.toNamed(RouteHelper.getDrivingVerificationRidingScreenRoute());
      break;
    case RiderProfileStep.vehicleImagesInfo:
      Get.toNamed(RouteHelper.getVehicleImagesRidingScreenRoute());
      break;
    case RiderProfileStep.vehicleInfo:
      Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
      break;
  }
}
