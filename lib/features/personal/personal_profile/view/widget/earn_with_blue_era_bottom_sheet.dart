import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
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
import 'package:get/get.dart';

class EarnWithBlueEraBottomSheet extends StatelessWidget {
  EarnWithBlueEraBottomSheet({Key? key}) : super(key: key);

  final List<ServiceItem> _services = [
    ServiceItem(
      label: 'Self Work',
      name: 'SELF_WORK',
      icon: AppIconAssets.plumberIcon,
      bgColor: const Color(0xFFCBEAFC),
      labelColor: const Color(0xFF004E7C),
    ),
    ServiceItem(
      label: 'Delivery\nPartner',
      name: 'DELIVERY_PARTNER',
      icon: AppIconAssets.deliveryPartnerIcon,
      bgColor: const Color(0xFFDAEDCF),
      labelColor: const Color(0xFF204A08),
    ),
    ServiceItem(
      label: 'Home Made\nProducts',
      name: 'HOME_MADE_PRODUCTS',
      icon: AppIconAssets.homeMadeProductIcon,
      bgColor: const Color(0xFFFDD5A4),
      labelColor: const Color(0xFF8C4D00),
    ),
    ServiceItem(
      label: 'Home Made\nFood Items',
      name: 'HOME_MADE_FOOD_ITEMS',
      icon: AppIconAssets.homeMadeFoodIcon,
      bgColor: const Color(0xFFFEF2B6),
      labelColor: const Color(0xFF856F00),
    ),
    ServiceItem(
      label: 'Home\nServices',
      name: 'HOME_SERVICES',
      icon: AppIconAssets.homeServiceIcon,
      bgColor: const Color(0xFFDBD5F7),
      labelColor: const Color(0xFF140074),
    ),
    ServiceItem(
      label: 'Rental\nServices',
      name: 'RENTAL_SERVICES',
      icon: AppIconAssets.rentalServiceIcon,
      bgColor: const Color(0xFFFAD7D3),
      labelColor: const Color(0xFF740C00),
    ),
    ServiceItem(
      label: 'Counselling /\nConsulting',
      name: 'COUNSELLING_CONSULTING',
      icon: AppIconAssets.consultingIcon,
      bgColor: const Color(0xFFBCEEE2),
      labelColor: const Color(0xFF006950),
    ),
    ServiceItem(
      label: 'Tuition Classes\nOnline/Offline',
      name: 'TUITION_CLASSES_ONLINE_OFFLINE',
      icon: AppIconAssets.teachingIcon,
      bgColor: const Color(0xFFEEBCE7),
      labelColor: const Color(0xFF8B0077),
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
                itemCount: _services.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: _services[i],
                  onTap: () => _handleServiceTap(context, _services[i]),
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
    switch (service.label) {
      case 'Self Work':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => SelfWorkServiceGuideBottomSheet(),
        );
        break;

      case 'Delivery\nPartner':
        showProfessionChangeDialog(
          context: context,
          designation: AppConstants.DELIVERY_PARTNER,
        );
        break;

      case 'Home Mad\nProducts':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ProductServiceGuideBottomSheet(),
        );
        break;

      case 'Home Made\nFood Items':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => FoodServiceGuideBottomSheet(),
        );
        break;

      case 'Home\nServices':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => HomeServiceGuideBottomSheet(),
        );
        break;

      case 'Rental\nServices':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => RentalServiceGuideBottomSheet(),
        );
        break;

      case 'Counselling /\nConsulting':
        showProfessionChangeDialog(
          context: context,
          designation: AppConstants.CONSULTANT,
          serviceSubType: EarnWithBlueEraServiceTypes.homeService,
        );

        break;

      case 'Tuition Classes\nOnline/Offline':
        showProfessionChangeDialog(
          context: context,
          designation: AppConstants.TUTOR,
          serviceSubType: EarnWithBlueEraServiceTypes.homeService,
        );

        break;

      default:
        break;
    }
  }

}
