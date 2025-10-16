import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/store/view/store_screen_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessStoreCard extends StatelessWidget {
  final GetAllStoreResModel? getAllStoreResData;
  final double Function(double) ds;
  const BusinessStoreCard({Key? key, required this.ds, this.getAllStoreResData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              Get.to(() => VisitBusinessProfileNew(
                businessId: getAllStoreResData?.id ?? "",
                screenName: AppConstants.storeFeedScreen,
              ));
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
                          InkWell(
                            onTap: () async {
                              if (isGuestUser()) {
                                createProfileScreen();
                              } else {
                                // if (controllerVisit.isFollow.value) {
                                //   await Get.find<StoreScreenController>().unFollowBusinessUser(
                                //       candidateResumeId:
                                //       getAllStoreResData?.userId
                                //   );
                                // } else {
                                //   await Get.find<StoreScreenController>().followBusinessUser(
                                //       candidateResumeId:
                                //       getAllStoreResData?.userId
                                //   );
                                // }
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: ds(4)),
                              padding: EdgeInsets.symmetric(horizontal: ds(8), vertical: ds(4)),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(ds(20)),
                              ),
                              child: Text(
                                "Follow",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ds(11),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds(4)),
                      Row(
                        children: [
                          Text(
                            '${
                              getAllStoreResData?.categoryOfBusiness?.name ??
                                  getAllStoreResData?.natureOfBusiness ??
                                  'OTHER'
                            } ',
                            style: TextStyle(color: Colors.grey, fontSize: ds(12)),
                          ),
                          Row(
                            children: [
                              LocalAssets(
                                imagePath: AppIconAssets.star,
                                height: 12,
                                width: 12,
                              ),
                              Text(
                                ' ${
                                  ((getAllStoreResData?.totalRatings ?? 0) > 0)
                                      ? "(${getAllStoreResData?.totalRatings})"
                                      : "No "
                                }',
                                style: TextStyle(color: AppColors.orangelite, fontSize: ds(12)),
                              ),
                            ],
                          ),
                          Text(
                            " Rating",
                            style: TextStyle(color: Colors.grey, fontSize: ds(12)),
                          ),
                        ],
                      ),
                      SizedBox(height: ds(4)),
                      Wrap(
                        spacing: ds(4),
                        runSpacing: ds(4),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.whiteF1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomText(
                              '${calculateDistanceKm(
                                LocationService.lat,
                                LocationService.lng,
                                getAllStoreResData?.businessLocation?.lat?.toDouble() ?? 0.0,
                                getAllStoreResData?.businessLocation?.lon?.toDouble() ?? 0.0,
                              ).toStringAsFixed(2)} Km Away',
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),

                          if(getAllStoreResData?.address?.isNotEmpty??false)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.whiteF1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomText(
                              getAllStoreResData?.address ?? '',
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ds(10)),

          if(getAllStoreResData?.websiteUrl?.isNotEmpty??false)
          Padding(
            padding: EdgeInsets.only(bottom: ds(6)),
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

          if(getAllStoreResData?.websiteUrl?.isNotEmpty??false)
          Padding(
            padding: EdgeInsets.only(bottom: ds(12)),
            child: InkWell(
              onTap: () async {
                final Uri url = Uri.parse(getAllStoreResData?.websiteUrl??'');
                if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: CustomText(
                getAllStoreResData?.websiteUrl ?? '',
                color: AppColors.primaryColor,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),


          if(getAllStoreResData !=null && (getAllStoreResData?.livePhotos?.isNotEmpty ?? false))
          /// Image grid
          Padding(
            padding: EdgeInsets.only(bottom: ds(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ds(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.whiteFE,
                            width: 1,
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: getAllStoreResData?.livePhotos?[0] ?? '',
                        height: ds(190),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => LocalAssets(
                          imagePath:
                          AppIconAssets.place_holder_image,
                          boxFix: BoxFit.fill,
                        ),
                        errorWidget: (context, url, error) =>
                            LocalAssets(
                              imagePath:
                              AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                      ),

                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child:
                          CachedNetworkImage(
                            imageUrl: ((getAllStoreResData?.livePhotos?.length??0) > 1) ? getAllStoreResData!.livePhotos![1] : '',
                            height: ds(95),
                            fit: BoxFit.fitWidth,
                            placeholder: (context, url) => LocalAssets(
                              imagePath:
                              AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                            errorWidget: (context, url, error) =>
                                LocalAssets(
                                  imagePath:
                                  AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.fill,
                                ),
                          ),

                        ),
                        SizedBox(height: ds(1)),
                        SizedBox(
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: ((getAllStoreResData?.livePhotos?.length??0) > 2) ? getAllStoreResData!.livePhotos![2] : '',
                            height: ds(95),
                            fit: BoxFit.fitWidth,
                            placeholder: (context, url) => LocalAssets(
                              imagePath:
                              AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                            errorWidget: (context, url, error) =>
                                LocalAssets(
                                  imagePath:
                                  AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.fill,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Interaction row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.storeWatch),
                  SizedBox(width: ds(4)),
                  CustomText(
                   timeAgo(
                       (getAllStoreResData != null && getAllStoreResData?.createdAt != null)
                       ? DateTime.parse(getAllStoreResData!.createdAt!)
                       : DateTime.now()),
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: ds(10)),
                  LocalAssets(imagePath: AppIconAssets.eye_new),
                  SizedBox(width: ds(4)),
                  CustomText(
                    "25K",
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: ds(10)),


                  InkWell(
                    onTap: (){
                      Get.to(() => FollowersFollowingPage(
                        tabIndex: 1,
                        userID: getAllStoreResData?.id ?? "",
                      ));
                    },
                    child: Row(
                      children: [
                        LocalAssets(imagePath: AppIconAssets.userNew),
                        SizedBox(width: ds(4)),
                        CustomText(
                          "5K",
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: ds(10)),
                  LocalAssets(imagePath: AppIconAssets.comment_new),
                  SizedBox(width: ds(4)),
                  CustomText(
                    "0",
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: AppColors.whiteF1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(child: Icon(Icons.star_border, size: ds(13))),
                  ),
                  SizedBox(width: ds(6)),
                  InkWell(
                    onTap: () async {
                      final link = profileDeepLink(
                          userId:
                          getAllStoreResData?.userId);
                      final message =
                          "See my profile on BlueEra:\n$link\n";
                      await SharePlus.instance
                          .share(ShareParams(
                        text: message,
                        subject: getAllStoreResData?.businessName,
                      ));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: AppColors.whiteF1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: LocalAssets(
                          imagePath: AppIconAssets.share_bold,
                          height: 13,
                          width: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}