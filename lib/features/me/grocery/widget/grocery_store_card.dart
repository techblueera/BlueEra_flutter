import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';

class GroceryStoreCard extends StatelessWidget {
  final GetAllStoreResModel store;
  final Color bgColor;

  const GroceryStoreCard({
    super.key,
    required this.store,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.toNamed(RouteHelper.getVisitGroceryStoreScreenRoute(), arguments: {
          ApiKeys.userId: store.userId,
          ApiKeys.businessId: store.id,
        });
      },
      child: Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: bgColor,
          border: Border.all(color: AppColors.greyE5, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: Logo & Name ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedAvatarWidget(
                        imageUrl: store.logo ?? '',
                        size: SizeConfig.size40,
                        borderColor: Colors.white,
                        borderRadius: SizeConfig.size20,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              store.businessName ?? 'Unknown Business',
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                            SizedBox(height: SizeConfig.size6),
                            Row(
                              children: [
                                _buildRatingBadge(store.avgRating.toString()),
                                const SizedBox(width: 6),
                                _buildCategoryBadge(store.subCategoryOfBusiness?.name ?? AppStrings.na),
                              ],
                            )
                          ],
                        ),
                      ),
                      _buildChatIcon(),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  // --- Address & Distance Card (Tappable) ---
                  GestureDetector(
                    onTap: () => _showMapBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: AppColors.greyE5, width: 0.5),
                        color: AppColors.white,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildIconContainer(AppIconAssets.location_outline),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  '${calculateDistanceKm(
                                    LocationService.lat,
                                    LocationService.lng,
                                    store.businessLocation?.lat?.toDouble() ?? 0.0,
                                    store.businessLocation?.lon?.toDouble() ?? 0.0,
                                  ).toStringAsFixed(2)} Km Away',
                                  fontSize: 13.0,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                SizedBox(height: SizeConfig.size4),
                                CustomText(
                                  store.address ?? AppStrings.na,
                                  fontSize: 11.0,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.directions_rounded, size: 20, color: Colors.blue.shade400),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size6),

                  // --- Stats: Category & Product ---
                  Row(
                    children: [
                      _buildStatBox(
                        icon: AppIconAssets.staggeredIcon,
                        count: '${store.totalCategoryCount}',
                        label: 'Category',
                        iconColor: const Color(0xFF9964F4),
                        bgColor: AppColors.purpleFD,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _buildStatBox(
                        icon: AppIconAssets.productCartIcon,
                        count: '${store.totalProductCount}',
                        label: 'Product',
                        iconColor: const Color(0xFF6179CD),
                        bgColor: AppColors.purpleFF,
                      ),
                    ],
                  )
                ],
              ),
            ),

            // --- Footer: Quirky Message ---
            if (store.quirkyMessage != null && store.quirkyMessage!.isNotEmpty) ...[
              const Divider(height: 0.5, color: AppColors.greyE5),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CustomText(
                    store.quirkyMessage!,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.lightYellowShade,
        border: Border.all(color: AppColors.lightYellowShade, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(rating, fontSize: 10, color: AppColors.blue2D, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.greenCB,
        border: Border.all(color: AppColors.greenCB, width: 0.5),
      ),
      child: CustomText(text, fontSize: 10, color: AppColors.green2C, fontWeight: FontWeight.w400),
    );
  }

  Widget _buildStatBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6.0)),
              child: LocalAssets(imagePath: icon, imgColor: iconColor, height: 18, width: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(count, fontSize: SizeConfig.medium, color: AppColors.secondaryTextColor, fontWeight: FontWeight.w600),
                  CustomText(label, fontSize: SizeConfig.extraSmall, color: AppColors.secondaryTextColor, fontWeight: FontWeight.w400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatIcon() {
    return GestureDetector(
      onTap: () {
        if (isGuestUser()) {
          createProfileScreen();
          return;
        }
        final chatViewController = getOrPut(() => ChatViewController());
        chatViewController.checkChatConnectionAndOpenChat(
          userId: store.userId ?? '',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primaryColor, width: 0.5),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 18,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildIconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2.0,
          )
        ],
      ),
      child: LocalAssets(
        imagePath: iconPath,
        imgColor: AppColors.secondaryTextColor,
        height: 24,
        width: 20,
      ),
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? 'Store',
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
        storeBusinessID:store.id??"" ,storeUserID: store.userId??""

    );
  }
}