import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/widget/other_profile_details_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/profile_summary_card.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../model/store_list_model.dart';

class StoreListWidget extends StatelessWidget {
  final bool isPlaceService;
  final StoreDataModel storeList;

  const StoreListWidget({super.key,  required this.isPlaceService,required this.storeList});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CommonDraggableBottomSheet(
            builder: (scrollController) =>
                OtherProfileDetailsBottomSheet(scrollController: scrollController, isUserProfile: true, isPlaceService: false, placeId: storeList.id!,),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fillColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: CachedNetworkImage(
                height: 170,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fill,
                imageUrl: "${storeList.logo}",
                placeholder: (context, url) =>
                    Center(child: const CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Icon(Icons.error),
              ),
            ),

            /// Profile Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ProfileSummaryCard(
                      name: '${storeList.businessName}',
                      imageUrl: 'https://randomuser.me/api/portraits/men/30.jpg',
                      rating: 4.6,
                      reviews: 48,
                      distance: '1.2 km',
                      imageSize: SizeConfig.size35,
                      imageBorderRadius: SizeConfig.size20,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  !isPlaceService ?
                  LocalAssets(imagePath: AppIconAssets.uploadIcon)
                      : Row(
                    children: [
                      _buildAction(icon: AppIconAssets.directionIcon),
                      SizedBox(width: SizeConfig.size10),
                      _buildAction(icon: AppIconAssets.uploadIcon),
                    ],
                  ),
                ],
              ),
            ),

            if(!isPlaceService)
            /// Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonIconContainerButton(
                        onTap: () {},
                        icon: LocalAssets(
                          imagePath: AppIconAssets.chat,
                          imgColor: AppColors.black,
                        ),
                        label: "Connect",
                        backgroundColor: AppColors.skyBlueFF,
                        height: SizeConfig.size30,
                        fontSize: SizeConfig.size12,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size7),
                    Expanded(
                      child: CommonIconContainerButton(
                        onTap: () {},
                        icon: LocalAssets(imagePath: AppIconAssets.directionIcon),
                        label: "Direction",
                        backgroundColor: AppColors.skyBlueFF,
                        height: SizeConfig.size30,
                        fontSize: SizeConfig.size12,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size7),
                    Expanded(
                      child: CommonIconContainerButton(
                        onTap: () {},
                        icon: LocalAssets(imagePath: AppIconAssets.catalogIcon),
                        label: "Catalog",
                        backgroundColor: AppColors.skyBlueFF,
                        height: SizeConfig.size30,
                        fontSize: SizeConfig.size12,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size7),
                    Expanded(
                      child: CommonIconContainerButton(
                        onTap: () {},
                        icon: LocalAssets(imagePath: AppIconAssets.reviewIcon),
                        label: "Reviews",
                        backgroundColor: AppColors.skyBlueFF,
                        height: SizeConfig.size30,
                        fontSize: SizeConfig.size12,
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }


  Widget _buildAction({required String icon}){
    return Container(
      height: SizeConfig.size35,
      width: SizeConfig.size35,
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.skyBlueFF
      ),
      child: LocalAssets(imagePath: icon),
    );
  }
}
