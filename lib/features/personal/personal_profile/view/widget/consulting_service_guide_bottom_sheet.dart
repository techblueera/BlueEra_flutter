import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/change_profession_warning_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ConsultingServiceGuideBottomSheet extends StatefulWidget {
  ConsultingServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<ConsultingServiceGuideBottomSheet> createState() => _ConsultingServiceGuideBottomSheetState();
}

class _ConsultingServiceGuideBottomSheetState extends State<ConsultingServiceGuideBottomSheet> {
  final authController = Get.find<AuthController>();
  int? selectedIndex;
  ProfessionTypeData? selectedService;

  @override
  void initState() {
    authController.getAllProfessionController();
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
        padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 5
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  AppStrings.counsellingConsulting,
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
              'How To Earn With Consulting Service ?, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'Select consulting service',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size16),

            Flexible(
              child: MasonryGridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: Get.find<AuthController>().individualOnboardingConsultationList.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: Get.find<AuthController>().individualOnboardingConsultationList[i],
                  getName: (item) => item.name ?? '',
                  getIcon: (item) => getIndividualProfessionIcon(item.tagId),
                  isSelected: selectedIndex == i,
                  spacing: 8.0,
                  onTap: (item) {
                    setState(() {
                      if (selectedIndex == i) {
                        selectedIndex = null;
                        selectedService = null;
                      } else {
                        selectedIndex = i;
                        selectedService = item;
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
                  Get.snackbar('Select Self Service', 'Please select a work type to continue',
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      colorText: Colors.white);
                  return;
                }

                // if(isEarnServiceOpt=='true' && selectedService?.tagId == userProfessionGlobal){
                //   commonSnackBar(message: 'You are already ${userProfessionGlobal.withArticle}');
                //   return;
                // }


                ChangeProfessionWarningDialog.show(
                  context,
                  onConfirm: () {
                  //   Get.toNamed(
                  //   RouteHelper.getAddSelfServiceRoute(),
                  //   arguments: {
                  //     ApiKeys.designation: selectedService?.slugId ?? OTHER,
                  //     ApiKeys.serviceSubType: EarnServiceTypes.selfWork,
                  //   },
                  // );
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

}

