import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalServiceGuideBottomSheet extends StatefulWidget {
  RentalServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<RentalServiceGuideBottomSheet> createState() => _RentalServiceGuideBottomSheetState();
}

class _RentalServiceGuideBottomSheetState extends State<RentalServiceGuideBottomSheet> {
  int? selectedIndex;
  ServiceItem? selectedService;
  final List<ServiceItem> _services = [
    ServiceItem(
      label: 'Home Stay',
       name: 'HOME_STAY',
      icon: AppIconAssets.homeStayIcon,
      bgColor: const Color(0xFFFFF2DF),
      labelColor: const Color(0xFFAF6800),
    ),
    ServiceItem(
      label: 'Flat/Room',
      name: 'FLAT_ROOM',
      icon: AppIconAssets.roomIcon,
      bgColor: const Color(0xFFF0F4C2),
      labelColor: const Color(0xFF4E5500),
    ),
    ServiceItem(
      label: 'Vehicle',
      name: 'VEHICLE',
      icon: AppIconAssets.vehicleIcon,
      bgColor: const Color(0xFFD7EAC9),
      labelColor: const Color(0xFF183A00),
    ),
    ServiceItem(
      label: 'Other',
      name: 'OTHER',
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
                  'Rental Services',
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
              'How To Earn With Home Made Food Items ? consectetur adipiscing elit. Nunc vulputate li.....',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'select Rental Type',
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
              onTap: () {
                if (selectedService == null) {
                  Get.snackbar('Select Rental Type', 'Please select a rental type to continue',
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      colorText: Colors.white);
                  return;
                }

                _handleServiceTap();
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

  void _handleServiceTap() async {
    switch (selectedIndex) {
      case 0:
        Get.toNamed(RouteHelper.getHomeStayRentalServiceRoute());
        break;

      case 1:
        Get.toNamed(RouteHelper.getAddFlatRoomRentalServiceScreenRoute());
        break;

      case 2:
        Get.toNamed(RouteHelper.getVehicleRentalServiceRoute());
        break;

      default:
        break;
    }
  }

}
