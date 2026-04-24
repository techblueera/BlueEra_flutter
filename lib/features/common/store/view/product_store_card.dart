import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/view/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_address_pill.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductStoreCard extends StatelessWidget {
  final GetAllStoreResModel? getAllStoreResData;
  final double Function(double) ds;
  const ProductStoreCard({Key? key, required this.ds, this.getAllStoreResData}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.all(ds(10)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.shadowColor,
        //     blurRadius: ds(1.4),
        //     offset: const Offset(0, 0.7),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Store info row
          InkWell(
            onTap: (){
              Get.to(() => VisitProductStoreDetailsScreen(
                visitBusinessId: getAllStoreResData?.id ?? "",
              ));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedAvatarWidget(
                  imageUrl: getAllStoreResData?.logo,
                  size: ds(50),
                  borderRadius: ds(25),
                ),
                SizedBox(width: ds(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name and follow
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: CustomText(
                                    getAllStoreResData?.businessName??'',
                                    fontSize: ds(14),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryTextColor,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: ds(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.whiteF1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: CustomText(
                                      getAllStoreResData?.dateOfIncorporation == null
                                          ? ""
                                          : "Since ${getAllStoreResData?.dateOfIncorporation?.year ?? ""}",
                                      fontSize: 10,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          InkWell(
                            onTap: () async {
                              if (isGuestUser()) {
                                createProfileScreen();
                              } else {
                                final controller = getOrPut(() => NewStoreController());
                                if (getAllStoreResData?.isFollowed ?? false) {
                                  await controller.unFollowBusinessUser(
                                      businessId: getAllStoreResData?.userId,
                                      store: getAllStoreResData ?? GetAllStoreResModel()
                                  );
                                } else {
                                  await controller.followBusinessUser(
                                      businessId: getAllStoreResData?.userId,
                                      store: getAllStoreResData ?? GetAllStoreResModel()
                                  );
                                }
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: ds(4)),
                              padding: EdgeInsets.symmetric(horizontal: ds(8), vertical: ds(4)),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(ds(20)),
                              ),
                              child: CustomText(
                                (getAllStoreResData?.isFollowed ?? false) ? AppStrings.unfollow : AppStrings.follow,
                                color: Colors.white,
                                fontSize: ds(11),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds(4)),
                      FittedBox(
                        child: Row(
                          children: [
                            BusinessCommonSubCategoryWidget(
                              label: '${
                                  getAllStoreResData?.subCategoryOfBusiness?.name ??
                                      getAllStoreResData?.natureOfBusiness ??
                                      'OTHER'
                              } ',
                            ),
                            SizedBox(width: ds(4)),
                            Row(
                              children: [
                                LocalAssets(
                                  imagePath: AppIconAssets.star,
                                  height: 12,
                                  width: 12,
                                ),
                                CustomText(
                                  ' ${
                                      (getAllStoreResData?.avgRating ?? 0) > 0
                                        ? "(${getAllStoreResData?.avgRating})"
                                        : "${AppStrings.no.tr} "
                                  }',
                                  color: AppColors.orangelite, fontSize: ds(12)
                                ),
                              ],
                            ),
                            CustomText(
                              AppStrings.ratings,
                                color: Colors.grey, fontSize: ds(12)
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ds(4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if(getAllStoreResData?.websiteUrl?.isNotEmpty??false) ...[
            SizedBox(height: ds(6)),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: InkWell(
                onTap: ()=> launchUrl(Uri.parse(getAllStoreResData?.websiteUrl??'')),
                child: CustomText(
                  getAllStoreResData?.websiteUrl ?? AppStrings.na,
                  fontSize: 12.0,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ExpandableText(
            //   text: "${getAllStoreResData?.businessDescription ?? ''}",
            //   trimLines: 2,
            //   expandMode: ExpandMode.dialog,
            //   style: TextStyle(
            //     color: AppColors.secondaryTextColor,
            //     fontFamily: AppConstants.OpenSans,
            //     fontWeight: FontWeight.w400,
            //   ),
            // ),
          ],

          SizedBox(height: ds(8)),

          // --- Address & Distance Pill (Tappable) ---
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: DiscoverAddressPill(
              destLat: getAllStoreResData?.businessLocation?.lat?.toDouble() ?? 0.0,
              destLng: getAllStoreResData?.businessLocation?.lon?.toDouble() ?? 0.0,
              address: getAllStoreResData?.address,
              onTap: () => _showMapBottomSheet(context),
            ),
          ),

          SizedBox(height: ds(10)),

          // --- Categories — names from response, accent-rail "info section"
          // styling that matches hospital / grocery / restaurant cards.
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _infoSection(
              icon: Icons.category_outlined,
              title: 'Category',
              count: getAllStoreResData?.totalCategoryCount ??
                  (getAllStoreResData?.categories?.length ?? 0),
              pills: (getAllStoreResData?.categories ?? [])
                  .map((c) => c.name ?? '')
                  .where((s) => s.trim().isNotEmpty)
                  .toList(),
              emptyLabel: 'No categories listed',
            ),
          ),

          SizedBox(height: ds(8)),

          // --- Products — count chip; pills wire in once the listing API
          // surfaces a top-products array.
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _infoSection(
              icon: Icons.shopping_bag_outlined,
              title: 'Product',
              count: getAllStoreResData?.totalProductCount ?? 0,
              pills: const [],
              emptyLabel:
                  '${getAllStoreResData?.totalProductCount ?? 0} products in store',
            ),
          ),

          SizedBox(height: ds(8)),
          if(getAllStoreResData !=null && (getAllStoreResData?.livePhotos?.isNotEmpty ?? false)) ...[
            /// Image grid
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: StoreLivePhotoWidget(
                livePhotos: getAllStoreResData?.livePhotos ?? [],
                natureOfBusiness: getAllStoreResData?.categoryOfBusiness?.name ??
                    getAllStoreResData?.natureOfBusiness ??
                    'OTHER',
                onViewFullScreen: ({
                  required int index,
                  required List<String> storeImage,
                  required String natureOfBusiness,
                }) {
                  viewImageOnFullScreen(
                    index: index,
                    storeImage: storeImage,
                    natureOfBusiness: natureOfBusiness,
                  );
                },
              ),
            ),
          ] else if ((getAllStoreResData?.logo ?? '').isNotEmpty) ...[
            /// Single logo photo fallback
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => viewImageOnFullScreen(
                    index: 0,
                    storeImage: [getAllStoreResData!.logo!],
                    natureOfBusiness: getAllStoreResData?.categoryOfBusiness?.name ??
                        getAllStoreResData?.natureOfBusiness ??
                        'OTHER',
                  ),
                  child: CachedNetworkImage(
                    imageUrl: getAllStoreResData!.logo!,
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
    );
  }

  void _openStore() {
    Get.to(() => VisitProductStoreDetailsScreen(
          visitBusinessId: getAllStoreResData?.id ?? "",
        ));
  }

  /// Section block — left accent rail, icon-in-disc header with inline
  /// count, and a wrap of soft-gradient pills below. Mirrors the hospital
  /// list / grocery store / restaurant card layout for one shared
  /// discover-card visual language.
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
                      child: Icon(icon,
                          size: SizeConfig.size14, color: accent),
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
      destinationName: getAllStoreResData?.businessName ?? 'Store',
      destinationAddress: getAllStoreResData?.address ?? '',
      destinationLat: getAllStoreResData?.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: getAllStoreResData?.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: getAllStoreResData?.livePhotos,
      storeBusinessID: getAllStoreResData?.id??"" ,storeUserID: getAllStoreResData?.userId??""
    );
  }

  void viewImageOnFullScreen(
      {required int index, required List<String> storeImage, required String natureOfBusiness}) {
    navigatePushTo(
      Get.context!,
      ImageViewScreen(
        subTitle: natureOfBusiness,
        appBarTitle:
        AppStrings.imageViewer,
        imageUrls: storeImage,
        initialIndex: index,
      ),
    );
  }
}