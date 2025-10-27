import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
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

  final List<ServiceItem> _services = [
    ServiceItem('Electrician', AppIconAssets.electricianIcon,
        id: '68ad6204dafb4bca58cf55d7',
        bgColor: const Color(0xFFFFF2DF),
        labelColor: const Color(0xFFAF6800)),
    ServiceItem('Plumber', AppIconAssets.plumberIcon,
        id: '68ad6204dafb4bca58cf55d8',
        bgColor: const Color(0xFFFFF2C3),
        labelColor: const Color(0xFF5D4900)),
    ServiceItem('Technician', AppIconAssets.technicianIcon,
        id: '68ad6204dafb4bca58cf55d9',
        bgColor: const Color(0xFFF0F4C2),
        labelColor: const Color(0xFF4E5500)),
    ServiceItem('Maid - Cleaner', AppIconAssets.mainCleanerIcon,
        id: '68ad6204dafb4bca58cf55da',
        bgColor: const Color(0xFFD7EAC9),
        labelColor: const Color(0xFF183A00)),
    ServiceItem('Carpenter', AppIconAssets.carpenterIcon,
        id: '68ad6204dafb4bca58cf55dc',
        bgColor: const Color(0xFFE1FCB3),
        labelColor: const Color(0xFF375700)),
    ServiceItem('Taxi - Car Driver', AppIconAssets.taxiDriverIcon,
        id: '68ad6204dafb4bca58cf55dd',
        bgColor: const Color(0xFFB2DFDC),
        labelColor: const Color(0xFF00625C)),
    ServiceItem('Mechanic', AppIconAssets.mechanicIcon,
        id: '68ad6204dafb4bca58cf55df',
        bgColor: const Color(0xFFB3E5FC),
        labelColor: const Color(0xFF003E5B)),
    ServiceItem('Home Renovator', AppIconAssets.mistryIcon,
        id: '68ad6204dafb4bca58cf55e2',
        bgColor: const Color(0xFFD0C4E8),
        labelColor: const Color(0xFF24006D)),
    ServiceItem('Painter', AppIconAssets.painterIcon,
        id: '68ad6204dafb4bca58cf55e3',
        bgColor: const Color(0xFFF9BBD0),
        labelColor: const Color(0xFF84002D)),
    ServiceItem('Gardener', AppIconAssets.gardenerIcon,
        id: '68ad6204dafb4bca58cf55e4',
        bgColor: const Color(0xFFA3E7A3),
        labelColor: const Color(0xFF006300)),
    ServiceItem('Security Person', AppIconAssets.securityPersonIcon,
        id: '68f8b41e0c46204861b3b312',
        bgColor: const Color(0xFFD7CCC8),
        labelColor: const Color(0xFF5B3F38)),
    ServiceItem('Other', AppIconAssets.securityPersonIcon,
        id: '68ad6204dafb4bca58cf55e5',
        bgColor: const Color(0xFFD7CCC8),
        labelColor: const Color(0xFF5B3F38)),
  ];


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

              final filteredServices = _services.where((service) {
                return apiSubcategories.any((api) =>
                api.id == service.id);
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

                await showCommonDialog(
                context: context,
                text: 'Your profession and work type will be changed. Continue?',
                confirmText: 'Confirm',
                cancelText: 'Cancel',
                confirmCallback: () async {
                  final personalCreateProfileController = Get.isRegistered<PersonalCreateProfileController>()
                    ? Get.find<PersonalCreateProfileController>()
                     : Get.put(PersonalCreateProfileController());

                  await personalCreateProfileController
                      .updateUserProfileDetails(
                    params: {
                      ApiKeys.profession: SELF_EMPLOYED,
                      ApiKeys.designation: selectedService?.label
                    },
                    isFromProfileOnly: true
                  );

                  Get.offNamed(
                      RouteHelper.getAddServicesScreenRoute(),
                      arguments: {
                        ApiKeys.providerType: ProductServiceProviderType.user,
                        ApiKeys.isSelfEmployement: true,
                        ApiKeys.designation: selectedService?.label
                      }
                  );

                },
                cancelCallback: () {
                  Get.back();
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

