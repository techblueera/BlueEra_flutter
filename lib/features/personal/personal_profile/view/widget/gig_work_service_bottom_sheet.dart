import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/change_profession_warning_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GigWorkServiceGuideBottomSheet extends StatefulWidget {
  GigWorkServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<GigWorkServiceGuideBottomSheet> createState() => _GigWorkServiceGuideBottomSheetState();
}

class _GigWorkServiceGuideBottomSheetState extends State<GigWorkServiceGuideBottomSheet> {
  int? selectedIndex;
  CollapsibleGridModel? selectedService;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Transport Work',
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.size8),
            HorizontalVideoPlayer(),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              'How To Earn With Transport Work ?, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'select Transport Work',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size16),

            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: gigWorkServiceList.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: gigWorkServiceList[i],
                  isSelected: selectedIndex == i,
                  onTap: () {
                    setState(() {
                      if (selectedIndex == i) {
                        selectedIndex = null;
                        selectedService = null;
                      } else {
                        selectedIndex = i;
                        selectedService = gigWorkServiceList[i];
                      }
                    });
                  },
                ),
              ),
            ),


            CustomBtn(
              height: SizeConfig.size40,
              title: 'Start Listing Now',
              onTap: () async {
                if (selectedService == null) {
                  Get.snackbar('Select Transport Service', 'Please select a transport to continue',
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      colorText: Colors.white);
                  return;
                }

                if(isEarnServiceOpt=='true' && selectedService?.slugId == userWorkTypeGlobal){
                  commonSnackBar(message: 'You are already ${userWorkTypeGlobal.withArticle}');
                  return;
                }


                ChangeProfessionWarningDialog.show(
                  context,
                  onConfirm: () {
                    switch (selectedService?.slugId) {
                      case DELIVERY_RIDER:
                        _handleDeliveryPartner();

                        break;

                      case CAR_TAXI:
                      // ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
                      //   context: context,
                      //   designation: CAR_DRIVER_TAXI,
                      // );
                        break;

                      case GOODS_TAXI:
                      // ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
                      //   context: context,
                      //   designation: CAR_DRIVER_TAXI,
                      // );
                        break;

                      case AUTO_TAXI:
                      // ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
                      //   context: context,
                      //   designation: CAR_DRIVER_TAXI,
                      // );
                        break;
                    }
                  },
                );


              },
              bgColor: AppColors.primaryColor,
              textColor: AppColors.white,
              radius: 10.0,
            ),

            SizedBox(height: SizeConfig.size16),
          ],
        ),
      ),
    );
  }

  void _handleDeliveryPartner() {
    final controller = getOrPut(() => DeliveryPartnerController());

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


    if (firstIncompleteEntry.key == RiderProfileStep.personalInfo) {
      Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
    } else if (firstIncompleteEntry.key == RiderProfileStep.addressInfo) {
      Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
    } else {
      Get.to(RiderProfileStatusScreen(
        screeName: '',
      ));
      // Get.toNamed(RouteHelper.getRiderProfileStatusScreenRoute());
    }

    // switch (firstIncompleteEntry.key) {
    //   case RiderProfileStep.personalInfo:
    //     Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.addressInfo:
    //     Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.personalIdentificationInfo:
    //     Get.toNamed(RouteHelper.getPersonalIdentificationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.drivingInfo:
    //     Get.toNamed(RouteHelper.getDrivingVerificationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.vehicleImagesInfo:
    //     Get.toNamed(RouteHelper.getVehicleImagesRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.vehicleInfo:
    //     Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
    //     break;
    // }
  }

}

