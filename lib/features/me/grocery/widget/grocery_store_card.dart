import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_address_pill.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                        size: SizeConfig.size50,
                        borderColor: Colors.white,
                        borderRadius: SizeConfig.size25,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              store.businessName ?? 'Unknown Business',
                              fontSize: SizeConfig.large,
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
                      DiscoverChatIcon(userId: store.userId ?? ''),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  // --- Address & Distance Pill (Tappable) ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: DiscoverAddressPill(
                      destLat:
                          store.businessLocation?.lat?.toDouble() ?? 0.0,
                      destLng:
                          store.businessLocation?.lon?.toDouble() ?? 0.0,
                      address: store.address,
                      onTap: () => _showMapBottomSheet(context),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // --- Categories — real names from response, in the same
                  // accent-rail "info section" style used on the hospital
                  // list card so the visual language stays consistent.
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _infoSection(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      count: store.totalCategoryCount ??
                          (store.categories?.length ?? 0),
                      pills: (store.categories ?? [])
                          .map((c) => c.name ?? '')
                          .where((s) => s.trim().isNotEmpty)
                          .toList(),
                      emptyLabel: 'No categories listed',
                    ),
                  ),

                  // --- Products — count chip only for now; pills can be
                  // wired in once the listing API surfaces top products.
                  SizedBox(height: SizeConfig.size10),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _infoSection(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      count: store.totalProductCount ?? 0,
                      pills: const [],
                      emptyLabel: '${store.totalProductCount ?? 0} products in store',
                    ),
                  ),

                  SizedBox(height: SizeConfig.size6),

                  // --- Live Photos / Logo ---
                  if (store.livePhotos?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: StoreLivePhotoWidget(
                        livePhotos: store.livePhotos ?? [],
                        natureOfBusiness: store.categoryOfBusiness?.name ??
                            store.natureOfBusiness ??
                            'OTHER',
                        onViewFullScreen: ({
                          required int index,
                          required List<String> storeImage,
                          required String natureOfBusiness,
                        }) {
                          _viewImageOnFullScreen(
                            index: index,
                            storeImage: storeImage,
                            natureOfBusiness: natureOfBusiness,
                          );
                        },
                      ),
                    ),
                  ] else if ((store.logo ?? '').isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => _viewImageOnFullScreen(
                            index: 0,
                            storeImage: [store.logo!],
                            natureOfBusiness: store.categoryOfBusiness?.name ??
                                store.natureOfBusiness ??
                                'OTHER',
                          ),
                          child: CachedNetworkImage(
                            imageUrl: store.logo!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 600,
                            memCacheHeight: 600,
                            placeholder: (_, __) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                            errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],


                ],
              ),
            ),

            // --- Footer: Quirky Message ---
            if (store.quirkyMessage != null && store.quirkyMessage!.isNotEmpty) ...[
              const Divider(height: 0.5, color: AppColors.greyE5),
              InkWell(
                onTap: () {
                  Get.toNamed(RouteHelper.getVisitGroceryStoreScreenRoute(), arguments: {
                    ApiKeys.userId: store.userId,
                    ApiKeys.businessId: store.id,
                  });
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.08),
                        AppColors.primaryColor.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Flexible(
                        child: CustomText(
                          store.quirkyMessage!,
                          fontSize: SizeConfig.small,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  /// Rating badge — gradient gold pill, bold rating numeral, soft amber
  /// glow. Reads as a badge of quality rather than a tag.
  Widget _buildRatingBadge(String rating) {
    const goldFg = Color(0xFFB8860B);
    const goldBg = Color(0xFFFFF3D1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, goldBg],
        ),
        border: Border.all(
          color: goldFg.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: goldFg.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(
            rating,
            fontSize: 11,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  /// Subcategory badge — gradient mint pill with a leading color dot,
  /// visually paired with the rating badge beside it.
  Widget _buildCategoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.greenCB],
        ),
        border: Border.all(
          color: AppColors.green2C.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green2C.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.green2C,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: CustomText(
              text,
              fontSize: 11,
              color: AppColors.green2C,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _viewImageOnFullScreen({
    required int index,
    required List<String> storeImage,
    required String natureOfBusiness,
  }) {
    navigatePushTo(
      Get.context!,
      ImageViewScreen(
        subTitle: natureOfBusiness,
        appBarTitle: AppStrings.imageViewer,
        imageUrls: storeImage,
        initialIndex: index,
      ),
    );
  }

  void _openStore() {
    Get.toNamed(
      RouteHelper.getVisitGroceryStoreScreenRoute(),
      arguments: {
        ApiKeys.userId: store.userId,
        ApiKeys.businessId: store.id,
      },
    );
  }

  /// Section block — left accent rail, icon-in-disc header with inline
  /// count, and a wrap of soft-gradient pills below. Mirrors the hospital
  /// list card layout so business cards across discover share one visual
  /// language.
  Widget _infoSection({
    required IconData icon,
    required String title,
    required int count,
    required List<String> pills,
    required String emptyLabel,
  }) {
    final accent = AppColors.primaryColor;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            margin: EdgeInsets.only(
                top: 4, bottom: 4, right: SizeConfig.size10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child:
                          Icon(icon, size: SizeConfig.size14, color: accent),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      title,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '·',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '$count',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                if (pills.isEmpty)
                  _sectionEmpty(emptyLabel)
                else
                  Wrap(
                    spacing: SizeConfig.size6,
                    runSpacing: SizeConfig.size6,
                    children: [
                      ...pills.take(4).map(_gradientChip),
                      if (pills.length > 4) _overflowChip(pills.length - 4),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientChip(String label) {
    final accent = AppColors.primaryColor;
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              accent.withValues(alpha: 0.09),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: CustomText(
          label,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ),
    );
  }

  Widget _overflowChip(int extra) {
    final accent = AppColors.primaryColor;
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              '+$extra more',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward_rounded, size: 11, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _sectionEmpty(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: AppColors.greyE5.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 12, color: AppColors.grey9B),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 11,
            color: AppColors.grey9B,
            fontWeight: FontWeight.w500,
          ),
        ],
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