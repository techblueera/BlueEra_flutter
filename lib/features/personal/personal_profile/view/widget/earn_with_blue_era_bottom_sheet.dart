import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/food_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/home_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/product_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/rental_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/self_work_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class EarnWithBlueEraBottomSheet extends StatelessWidget {
  EarnWithBlueEraBottomSheet({Key? key}) : super(key: key);

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
                  'Earn With BlueEra',
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
                itemCount: earnWithBlueEraServiceList.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: earnWithBlueEraServiceList[i],
                  onTap: () => _handleServiceTap(context, earnWithBlueEraServiceList[i]),
                ),
              ),
            ),

            SizedBox(height: SizeConfig.size16),
          ],
        ),
      ),
    );
  }

  void _handleServiceTap(BuildContext context, ServiceItem service) async {
    switch (service.slugId) {
      case AppConstants.SELF_WORK_OPTION:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: 'You can opt only one service');
        }else{
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => SelfWorkServiceGuideBottomSheet(),
          );
        }

        break;

      case AppConstants.DELIVERY_PARTNER_OPTION:
        showProfessionChangeDialog(
          context: context,
          designation: AppConstants.DELIVERY_PARTNER,
        );
        break;

      case AppConstants.HOME_MADE_PRODUCTS_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ProductServiceGuideBottomSheet(),
        );
        break;

      case AppConstants.HOME_MADE_FOOD_ITEMS_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => FoodServiceGuideBottomSheet(),
        );
        break;

      case AppConstants.HOME_SERVICES_OPTION:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: 'You can opt only one service');
        }else {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => HomeServiceGuideBottomSheet(),
          );
        }
        break;

      case AppConstants.RENTAL_SERVICES_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => RentalServiceGuideBottomSheet(),
        );
        break;

      case AppConstants.COUNSELLING_CONSULTING_OPTION:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: 'You can opt only one service');
        }else {
          showProfessionChangeDialog(
            context: context,
            designation: AppConstants.CONSULTANT,
            serviceSubType: EarnWithBlueEraServiceTypes.homeService,
          );
        }
        break;

      case AppConstants.TUITION_CLASSES_ONLINE_OFFLINE_OPTION:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: 'You can opt only one service');
        }else {
          showProfessionChangeDialog(
            context: context,
            designation: AppConstants.TUTOR,
            serviceSubType: EarnWithBlueEraServiceTypes.homeService,
          );
        }
        break;

      default:
        break;
    }
  }

}
