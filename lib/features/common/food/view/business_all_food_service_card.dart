import 'dart:math' hide log;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/view/sharing_business_food_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';

class BusinessAllFoodServiceCard extends StatefulWidget {
  final List<GetFoodDetailsModel> allFoodServices;

  const BusinessAllFoodServiceCard({super.key, required this.allFoodServices});

  @override
  State<BusinessAllFoodServiceCard> createState() => _BusinessAllFoodServiceCardState();
}

class _BusinessAllFoodServiceCardState extends State<BusinessAllFoodServiceCard> {
  late final List<GlobalKey> _cardKey;

  @override
  void initState() {
    super.initState();
    _cardKey = List.generate(widget.allFoodServices.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate card size - 1:1 aspect ratio
    const double maxCardSize = 400.0;
    final double cardSize = screenWidth > maxCardSize ? maxCardSize : screenWidth * 0.9;


    return ListView.builder(
      itemCount: widget.allFoodServices.length,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(SizeConfig.size15),
      itemBuilder: (context, index) {
        final foodServiceData = widget.allFoodServices[index];
        final int randomIndex = Random().nextInt(bgAssetsForServices.length);
        final String bgAsset = bgAssetsForServices[randomIndex];

        return Container(
          padding: const EdgeInsets.all(10.0),
          margin: EdgeInsets.only(bottom: index != widget.allFoodServices.length -1 ? 10.0 : kBottomNavigationBarHeight + SizeConfig.size40),
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
                child: SharingBusinessFoodServiceCard(
                  cardKey: _cardKey[index],
                  foodServiceData: foodServiceData,
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
                        final currentFoodServices = widget.allFoodServices[index];
                        await VisitingCardHelper().shareVisitingCard(
                            _cardKey[index],
                            serviceId: currentFoodServices.id
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
