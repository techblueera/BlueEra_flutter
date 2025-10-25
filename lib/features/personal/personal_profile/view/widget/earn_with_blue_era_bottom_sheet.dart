import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ConsultBottomSheet extends StatelessWidget {
  ConsultBottomSheet({Key? key}) : super(key: key);

  final List<_Service> _services = [
    _Service('Self Work',  AppIconAssets.selfWorkIcon, Color(0xFFCBEAFC)),
    _Service('Delivery\nPartner', AppIconAssets.deliveryPartnerIcon, Color(0xFFDAEDCF)),
    _Service('Home Mad\nProducts', AppIconAssets.homeMadeProductIcon, Color(0xFFFDD5A4)),
    _Service('Home Made\nFood Items', AppIconAssets.homeMadeFoodIcon, Color(0xFFFEF2B6)),
    _Service('Home\nServices', AppIconAssets.homeServiceIcon, Color(0xFFDBD5F7)),
    _Service('Rental\nServices', AppIconAssets.rentalServiceIcon, Color(0xFFFAD7D3)),
    _Service('Counselling /\nConsulting ', AppIconAssets.consultingIcon, Color(0xFFBCEEE2)),
    _Service('Tuition Classes\nOnline/Ofline', AppIconAssets.teachingIcon, Color(0xFFEEBCE7)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          const SizedBox(height: 16),

          // 3-column grid
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.68,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _services.length,
              itemBuilder: (_, i) => _ServiceCard(service: _services[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Service {
  final String label;
  final String icon;
  final Color color;
  const _Service(this.label, this.icon, this.color);
}

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard({Key? key, required this.service}) : super(key: key);

  void _handleServiceTap() async {
    switch (service.label) {
      case 'Home Mad\nProducts':
        await Get.offNamed(
          RouteHelper.getAddProductScreenRoute(),
          arguments: {
            ApiKeys.id: userId,
            ApiKeys.providerType: ProductServiceProviderType.user,
          },
        );
        break;

      case 'Home Made\nFood Items':
        Get.off(() => FoodUploadScreen(
          providerType: ProductServiceProviderType.user,
        ));
        break;

      case 'Home\nServices':
        Get.offNamed(
            RouteHelper.getAddServicesScreenRoute(),
            arguments: {
              ApiKeys.providerType: ProductServiceProviderType.user,
            }
        );
        break;

      case 'Rental\nServices':
      // Different screen or same with other args
      //   await Get.toNamed(
      //     RouteHelper.getAddProductScreenRoute(),
      //     arguments: {
      //       ApiKeys.id: userId,
      //       ApiKeys.providerType: ProductServiceProviderType.channel,
      //     },
      //   );
        break;

      case 'Home\nStay':
        // await Get.toNamed(
        //   RouteHelper.getAddProductScreenRoute(),
        //   arguments: {
        //     ApiKeys.id: userId,
        //     ApiKeys.providerType: ProductServiceProviderType.business,
        //   },
        // );
        break;

      case 'Content\nconsulting':
        // await Get.toNamed(
        //   RouteHelper.getAddProductScreenRoute(),
        //   arguments: {
        //     ApiKeys.id: userId,
        //     ApiKeys.providerType: ProductServiceProviderType.channel,
        //   },
        // );
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        // Navigator.pop(context, service.label);
        _handleServiceTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                      color: service.color,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [AppShadows.textFieldShadow]
                  ),
                  alignment: Alignment.center,
                  child: LocalAssets(imagePath: service.icon)),
            ),
            const SizedBox(height: 12),
            CustomText(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
// onTap: (){
// Navigator.push(context, MaterialPageRoute(builder: (context) => RentalScreen(),));
// },