import 'dart:math' hide log;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/sharing_business_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';

class BusinessAllServiceCard extends StatefulWidget {
  final List<GetServiceModel> allServices;

  const BusinessAllServiceCard({super.key, required this.allServices});

  @override
  State<BusinessAllServiceCard> createState() => _BusinessAllServiceCardState();
}

class _BusinessAllServiceCardState extends State<BusinessAllServiceCard> {
  late final List<GlobalKey> _cardKey;

  @override
  void initState() {
    super.initState();
    _cardKey = List.generate(widget.allServices.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate card size - 1:1 aspect ratio
    const double maxCardSize = 400.0;
    final double cardSize = screenWidth > maxCardSize ? maxCardSize : screenWidth * 0.9;

    return ListView.builder(
      itemCount: widget.allServices.length,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(SizeConfig.size15),
      itemBuilder: (context, index) {
        final serviceData = widget.allServices[index];
        final int randomIndex = Random().nextInt(bgAssetsForServices.length);
        final String bgAsset = bgAssetsForServices[randomIndex];

        return Container(
          padding: const EdgeInsets.all(10.0),
          margin: EdgeInsets.only(bottom: index != widget.allServices.length -1 ? 10.0 : kBottomNavigationBarHeight + SizeConfig.size40),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.whiteE5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    offset: Offset(0, 1),
                    blurRadius: 2)
              ]),
          child: Column(
            children: [
              SizedBox(
                height: cardSize,
                child: SharingBusinessServiceCard(
                  cardKey: _cardKey[index],
                  serviceData: serviceData,
                  backgroundAsset: bgAsset,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomText(
                        AppStrings.shareCardToSocialMediaGrowBusiness,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.small,
                        fontFamily: AppConstants.OpenSans),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () async {
                        final currentService = widget.allServices[index];
                        await VisitingCardHelper().shareVisitingCard(
                            _cardKey[index],
                            serviceId: currentService.id
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: SizeConfig.size5,right: SizeConfig.size5,top: SizeConfig.size5),
                        child: LocalAssets(imagePath: AppIconAssets.share_bold, imgColor: AppColors.primaryColor ),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        );
      },
    );
  }

}
