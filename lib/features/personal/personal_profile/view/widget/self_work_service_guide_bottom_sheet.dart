import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfWorkServiceGuideBottomSheet extends StatefulWidget {
  SelfWorkServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<SelfWorkServiceGuideBottomSheet> createState() => _SelfWorkServiceGuideBottomSheetState();
}

class _SelfWorkServiceGuideBottomSheetState extends State<SelfWorkServiceGuideBottomSheet> {
  final authController = Get.find<AuthController>();
  int? selectedIndex;
  ServiceItem? selectedService;



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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Self Work',
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
              'How To Earn With Self Work ?, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'select Work Type',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size16),

            Obx((){
              if (authController.isProfessionLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              final selfEmployedData = authController.professionTypeDataList
                  .firstWhereOrNull((e) => e.tagId == SELF_EMPLOYED);

              final apiSubcategories = selfEmployedData?.subcategoriesFiledName ?? [];

              final filteredServices = selfWorkServiceList.where((service) {
                return apiSubcategories.any((api) =>
                api.tagId == service.slugId);
              }).toList();

              // 3-column grid
              return Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredServices.length,
                  itemBuilder: (_, i) => CommonServiceCard(
                    service: filteredServices[i],
                    isSelected: selectedIndex == i,
                    onTap: () {
                      setState(() {
                        if (selectedIndex == i) {
                          selectedIndex = null;
                          selectedService = null;
                        } else {
                          selectedIndex = i;
                          selectedService = filteredServices[i];
                        }
                      });
                    },
                  ),
                ),
              );
            }),

            CustomBtn(
              height: SizeConfig.size40,
              title: 'Start Listing Now',
              onTap: () async {
                if (selectedService == null) {
                  Get.snackbar('Select Home Service', 'Please select a work type to continue',
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      colorText: Colors.white);
                  return;
                }

                ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
                  context: context,
                  designation: selectedService?.slugId ?? OTHER,
                  serviceSubType: EarnWithBlueEraServiceTypes.selfWork,
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

