import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessStoreCard extends StatelessWidget {
  final GetAllStoreResModel? getAllStoreResData;
  final double Function(double) ds;
  const BusinessStoreCard({Key? key, required this.ds, this.getAllStoreResData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool selfBusiness = getAllStoreResData?.userId == userId;

    return Container(
      padding: EdgeInsets.all(ds(10)),
      decoration: BoxDecoration(
        color: AppColors.whiteFE,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: ds(1.4),
            offset: const Offset(0, 0.7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Store info row
          InkWell(
            onTap: (){
              if(!selfBusiness){
                Get.to(() => VisitBusinessProfileNew(
                  businessId: getAllStoreResData?.id ?? "",
                  screenName: AppConstants.storeFeedScreen,
                ));
              }else{
                Get.to(() =>  BusinessOwnProfileScreen());
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedAvatarWidget(
                  imageUrl: getAllStoreResData?.logo,
                  size: ds(40),
                  borderRadius: ds(20),
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

                          if(!selfBusiness)
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
                            CustomText(
                              '${
                                getAllStoreResData?.subCategoryOfBusiness?.name ??
                                    getAllStoreResData?.natureOfBusiness ??
                                    'OTHER'
                              } ',
                                color: Colors.grey, fontSize: ds(12)
                            ),
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

          SizedBox(height: ds(10)),

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
                            getAllStoreResData?.businessLocation?.lat?.toDouble() ?? 0.0,
                            getAllStoreResData?.businessLocation?.lon?.toDouble() ?? 0.0,
                          ).toStringAsFixed(2)} Km Away',
                          fontSize: 13.0,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          getAllStoreResData?.address ?? AppStrings.na,
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

          SizedBox(height: ds(6)),

          if(getAllStoreResData?.websiteUrl?.isNotEmpty??false)
          Padding(
            padding: EdgeInsets.only(top: ds(10)),
            child: ExpandableText(
              text: "${getAllStoreResData?.businessDescription ?? ''}",
              trimLines: 3,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.mainTextColor,
                fontFamily: AppConstants.OpenSans,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: ds(5)),

          if(getAllStoreResData !=null && (getAllStoreResData?.livePhotos?.isNotEmpty ?? false))
          /// Image grid
            StoreLivePhotoWidget(
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

          SizedBox(height: ds(5)),

          // --- Stats: Category & Product ---
          Row(
            children: [
              _buildStatBox(
                icon: AppIconAssets.staggeredIcon,
                count: '${getAllStoreResData?.totalCategoryCount ?? 0}',
                label: 'Category',
                iconColor: const Color(0xFF9964F4),
                bgColor: AppColors.purpleFD,
              ),
              SizedBox(width: SizeConfig.size6),
              _buildStatBox(
                icon: AppIconAssets.productCartIcon,
                count: '${getAllStoreResData?.totalProductCount ?? 0}',
                label: 'Product',
                iconColor: const Color(0xFF6179CD),
                bgColor: AppColors.purpleFF,
              ),
            ],
          ),


        ],
      ),
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
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: LocalAssets(
                imagePath: icon,
                imgColor: iconColor,
                height: 18,
                width: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    count,
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  CustomText(
                    label,
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ],
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
      destinationName: getAllStoreResData?.businessName ?? 'Store',
      destinationAddress: getAllStoreResData?.address ?? '',
      destinationLat: getAllStoreResData?.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: getAllStoreResData?.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: getAllStoreResData?.livePhotos,
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