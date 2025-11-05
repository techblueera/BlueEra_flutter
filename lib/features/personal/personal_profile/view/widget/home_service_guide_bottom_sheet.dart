import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeServiceGuideBottomSheet extends StatefulWidget {
  HomeServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<HomeServiceGuideBottomSheet> createState() => _HomeServiceGuideBottomSheetState();
}

class _HomeServiceGuideBottomSheetState extends State<HomeServiceGuideBottomSheet> {
  int? selectedIndex;
  ServiceItem? selectedService;
  final List<ServiceItem> _services = [
    ServiceItem(
      label: 'Beauty Services',
      name: AppConstants.BEAUTICIAN,
      icon: AppIconAssets.beautyServiceIcon,
      bgColor: const Color(0xFFFFF2DF),
      labelColor: const Color(0xFFAF6800),
    ),
    ServiceItem(
      label: 'Tailoring',
      name: AppConstants.TAILOR,
      icon: AppIconAssets.tailoringIcon,
      bgColor: const Color(0xFFFFF2C3),
      labelColor: const Color(0xFF5D4900),
    ),
    ServiceItem(
      label: 'Digital Marketing',
      name: AppConstants.DIGITAL_MARKETING,
      icon: AppIconAssets.digitalMarketingIcon,
      bgColor: const Color(0xFFF0F4C2),
      labelColor: const Color(0xFF4E5500),
    ),
    ServiceItem(
      label: 'Interior Decor',
      name: AppConstants.INTERIOR_DESIGNER,
      icon: AppIconAssets.interiorIcon,
      bgColor: const Color(0xFFD7EAC9),
      labelColor: const Color(0xFF183A00),
    ),
    ServiceItem(
      label: 'Other',
      name: AppConstants.OTHER,
      icon: AppIconAssets.staggeredIcon,
      bgColor: const Color(0xFFCFD8DD),
      labelColor: const Color(0xFF36444D),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  'Home Services',
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

            SizedBox(height: SizeConfig.size16),
            HorizontalVideoPlayer(),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              'How To Earn With Home Services ?, consectetur adipiscing elit. Nunc vulputate libero et veli.....',
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

            // 3-column grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 20,
                ),
                itemCount: _services.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: _services[i],
                  isSelected: selectedIndex == i,
                  onTap: () {
                    setState(() {
                      if (selectedIndex == i) {
                        selectedIndex = null;
                        selectedService = null;
                      } else {
                        selectedIndex = i;
                        selectedService = _services[i];
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
                  Get.snackbar('Select Home Service', 'Please select a work type to continue',
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      colorText: Colors.white);
                  return;
                }

                showProfessionChangeDialog(
                  context: context,
                  designation: selectedService?.name ?? AppConstants.OTHER,
                  serviceSubType: EarnWithBlueEraServiceTypes.homeService,
                );

                // await showCommonDialog(
                //   context: context,
                //   text: 'Your profession and work type will be changed. Continue?',
                //   confirmText: 'Update',
                //   cancelText: 'Cancel',
                //   confirmCallback: () async {
                //     final personalCreateProfileController = Get.isRegistered<PersonalCreateProfileController>()
                //         ? Get.find<PersonalCreateProfileController>()
                //         : Get.put(PersonalCreateProfileController());
                //
                //     personalCreateProfileController
                //         .updateUserProfileProfessionDesignation(
                //       params: {
                //         ApiKeys.profession: SELF_EMPLOYED,
                //         ApiKeys.designation: selectedService?.label
                //       },
                //     ).then((value){
                //       Get.offNamedUntil(
                //         RouteHelper.getAddServicesScreenRoute(),
                //         ModalRoute.withName(RouteHelper.getEarnWithBlueEraNewScreenRoute()),
                //         arguments: {
                //           ApiKeys.providerType: ProductServiceProviderType.user,
                //           ApiKeys.isFromEarnWithBlueEraService: true,
                //           ApiKeys.designation: selectedService?.label,
                //           ApiKeys.serviceSubType: EarnWithBlueEraServiceTypes.homeService,
                //         },
                //       );
                //     });
                //
                //   },
                //   cancelCallback: () {
                //     Get.back();
                //   },
                // );

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

