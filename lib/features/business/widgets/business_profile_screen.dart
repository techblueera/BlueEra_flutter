import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/visiting_cardlist_screen.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_keys.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constant.dart';
import '../../../core/services/multipart_image_service.dart';
import '../../../widgets/common_box_shadow.dart';
import '../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../common/reel/view/channel/follower_following_screen.dart';
import '../auth/controller/view_business_details_controller.dart';
import '../auth/model/viewBusinessProfileModel.dart';
import '../visit_business_profile/view/business_profile_header.dart';

import '../visiting_card/view/business_details_edit_page_one.dart';
import 'package:dio/dio.dart' as dio;

class BusinessProfileScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;

  BusinessProfileScreen({super.key, this.selectedIndex, this.sortBy});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  BusinessProfileDetails? details;

  List<String> postTab = [
    'Overview',
    'My Products',
    'Subscription',
    'My Posts',
    // 'Shorts',
    // 'Videos',
  ];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  @override
  void initState() {
    selectedFilter = widget.sortBy ?? SortBy.Latest;
    viewBusinessDetailsController.selectedIndex.value =
        widget.selectedIndex ?? 0;
    details = viewBusinessDetailsController.businessProfileDetails?.data;

    setFilters();
    super.initState();
  }

  void setFilters() {
    filters = SortBy.values.toList();
  }

  final controllerInventory = Get.put(InventoryController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewBusinessDetailsController>(builder: (controller) {
      if (controller.viewBusinessResponse.status == Status.COMPLETE) {
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
          child: Column(
            children: [
              BusinessProfileHeader(
                details: details,
                controller: viewBusinessDetailsController,
              ),

              // HorizontalTabSelector(
              //   tabs: postTab,
              //   selectedIndex:
              //       viewBusinessDetailsController.selectedIndex.value,
              //   onTabSelected: (index, value) {
              //     setState(() => viewBusinessDetailsController
              //         .selectedIndex.value = index);
              //   },
              //   labelBuilder: (label) => label,
              // ),
              // if (viewBusinessDetailsController.selectedIndex.value ==
              //         postTab.indexOf('Shorts') ||
              //     viewBusinessDetailsController.selectedIndex.value ==
              //         postTab.indexOf('Videos')) ...[
              //   _filterButtons(),
              // ],
              // SizedBox(
              //   height: SizeConfig.size10,
              // ),
              _buildTabContent(
                  controller, viewBusinessDetailsController.selectedIndex.value)
            ],
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(left: 40, top: 20),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
    });
  }

  Widget _buildTabContent(ViewBusinessDetailsController controller, int index) {
    switch (postTab[index]) {
      case 'Overview':
        return BusinessProfileWidget();
      case 'My Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_my_posts'),
            postFilterType: PostType.myPosts,
            id: businessId,
            isInParentScroll: true);
      case 'Shorts':
        return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: userId,
          showShortsInGrid: true,
          sortBy: selectedFilter,
          postVia: PostVia.profile,
        );
      case "Videos":
        return VideoChannelSection(
          isOwnVideos: true,
          channelId: '',
          authorId: userId,
          postVia: PostVia.profile,
          sortBy: selectedFilter,
        );
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }

}



class BusinessProfileHeader extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const BusinessProfileHeader(
      {super.key, required this.details, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black12,
        //     blurRadius: 5,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          // Banner + Profile Image
          Container(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    child: Image.network(
                      controller.imagePath?.value ?? "",
                      width: double.infinity,
                      height: 130,
                      //height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Profile image overlapping banner bottom
                Positioned(
                  left: 20,
                  top: 90, // makes it overlap smoothly
                  child: CommonProfileImage(
                    imagePath: controller.imagePath?.value ?? "",
                    onImageUpdate: (image) async {
                      controller.imagePath?.value = image;
                      dio.MultipartFile? imageByPart;
                      // if (viewBusinessDetailsController.isImageUpdated.value) {
                      if (controller.imagePath?.value.isNotEmpty ?? false) {
                        String fileName =
                            controller.imagePath?.value.split('/').last ?? "";
                        imageByPart = await dio.MultipartFile.fromFile(
                            controller.imagePath?.value ?? "",
                            filename: fileName);
                      }
                      // }
                      dynamic reqData = {
                        ApiKeys.businessId: businessId,
                        ApiKeys.logo_image: imageByPart,
                      };

                      await controller.updateBusinessDetails(reqData);
                    },
                    dialogTitle: 'Upload Business Logo',
                  ),
                ),
                Positioned(
                    right: 10,
                    top: 8,
                    child: InkWell(
                        onTap: () async {
                          final newPath =
                              await SelectProfilePictureDialog.showLogoDialog(
                            context,
                            "Edit Cover Picture",
                            isOnlyCamera: true,
                            isGallery: true,
                          );
                          dynamic dataImage =
                              await multiPartImage(imagePath: newPath);
                          var reqProfile = {ApiKeys.profile_image: dataImage};
                          await controller.uploadLiveStoreImage(
                            reqProfile,
                          );
                          // personalCreateProfileController.imagePath?.value = image;
                          // dynamic dataImage = await multiPartImage(imagePath: image);
                          // var reqProfile = {ApiKeys.profile_image: dataImage};
                          // await personalCreateProfileController.updateUserProfileDetails(
                          //     params: reqProfile, isFromProfileOnly: true);
                        },
                        child: Image.asset('assets/diwali_card/camera.png'))),

                // Follow button & menu

                Positioned(
                  right: 12,
                  top: 140,
                  child: Container(
                    width: Get.width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        (details?.businessIsVerified ?? false)
                            ? Flexible(
                              child:  Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 5),
                                decoration: BoxDecoration(
                                  color:  Color(0xffC5FFC9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:  CustomText(
                                  "Verified Profile",
                                  color:  AppColors.secondaryTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            : Flexible(
                                child: InkWell(
                                  onTap: () {
                                    commonSnackBar(message: "Coming soon....");
                                    // Navigator.pushNamed(
                                    //     context, RouteHelper.getBusinessVerificationScreenRoute());

                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 5),
                                    decoration: BoxDecoration(
                                        color:  theme.colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    child:  CustomText(
                                      "Verify Now",
                                      color:  AppColors.secondaryTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                        SizedBox(width: SizeConfig.size10,),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BusinessDetailsEditPageOne(),
                                ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                )),
                            child: const CustomText(
                              "Edit Profile",
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // const Icon(
                        //   Icons.more_vert,
                        //   color: AppColors.mainTextColor,
                        //   size: 20,
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Business name and buttons
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${details?.businessName ?? ''}",
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.size20,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondaryTextColor,
                          )),
                      child: const CustomText(
                        "Shop",
                        color: AppColors.secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.red,
                          )),
                      child: const CustomText(
                        "Close",
                        color: AppColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Set your desired radius here
                            ),
                            side: BorderSide(color: theme.colorScheme.primary),
                            backgroundColor: theme.colorScheme.primary),
                        onPressed: null,
                        // onPressed: _captureAndShareCard,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: SizeConfig.paddingXSmall,
                              ),
                              CustomText(
                                "Your Orders" ,
                                color: theme.colorScheme.surface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size10,
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Set your desired radius here
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                            )),
                        onPressed: () {
                          _showVisitingCardDialog(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: CustomText(
                            AppLocalizations.of(context)!.visitingCard,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // TextButton(
                //   onPressed: () {},
                //   child: const Text("Read More"),
                // ),
                 SizedBox(height: SizeConfig.size10,),

                Container(
                  // margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(
                      color: AppColors.whiteE5, // #E5E5E5 border
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    boxShadow: [AppShadows.textFieldShadow],
                    // color: Colors.white, // optional background
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfo("Rating",
                                "★ ${(details?.rating ?? 0).toStringAsFixed(1)}"),
                            SizedBox(
                              height: SizeConfig.size12,
                            ),
                            buildInfo("Views",
                                "${formatIndianNumber(details?.total_views ?? 0)}"),
                          ],
                        ),
                      ),
                      // SizedBox(
                      //   width: 100,
                      // ),
                      Expanded(
                        child: SizedBox(
                          height: SizeConfig.size50,
                          child: VerticalDivider(
                            color: AppColors.coloGreyText,
                            width: 12,
                            thickness: 1.2,
                          ),
                        ),
                      ),
                      // SizedBox(
                      //   width: SizeConfig.size24,
                      // ),
                      Flexible(
                        flex: 2,
                        child: Container(
                          // color: Colors.red,
                          width: Get.width,
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildInfo("Inquiries", formatIndianNumber(0)),
                              SizedBox(
                                height: SizeConfig.size12,
                              ),
                              InkWell(
                                  onTap: () {
                                    Get.to(() => FollowersFollowingPage(
                                          tabIndex: 1,
                                          userID: details?.id ?? "",
                                        ));
                                  },
                                  child: buildInfo("Followers",
                                      "${formatIndianNumber(details?.total_followers ?? 0)}")),
                            ],
                          ),
                        ),
                      ),
                      // SizedBox(
                      //   width: SizeConfig.size20,
                      // ),
                      SizedBox(
                        height: SizeConfig.size50,
                        child: VerticalDivider(
                          color: AppColors.coloGreyText,
                          width: 12,
                          thickness: 1.2,
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.size15,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            "Joined",
                            fontSize: SizeConfig.size12,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            details?.dateOfIncorporation == null
                                ? ""
                                : "${details?.dateOfIncorporation?.date ?? ""}/${(details?.dateOfIncorporation?.month ?? 1)}/${details?.dateOfIncorporation?.year ?? ""}",
                            fontSize: SizeConfig.size12,
                            maxLines: 1,
                            fontWeight: FontWeight.w400,
                          ),
                          SizedBox(height: SizeConfig.size10),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Section
        ],
      ),
    );
  }

  void _showVisitingCardDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SingleChildScrollView(
              child: Column(children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                    // color: AppColors.pinkE2,
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SizedBox(height: SizeConfig.size12),

                        // Theme selector (4 themes) as pill chips
                        // Row(
                        //   mainAxisSize: MainAxisSize.max,
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     CustomText(
                        //       'Visiting Card',
                        //       fontWeight: FontWeight.w600,
                        //       fontSize: SizeConfig.size14,
                        //       color: AppColors.black,
                        //     ),
                        //     InkWell(
                        //       onTap: () {
                        //         Get.back();
                        //         Get.to(() => VisitingCardlistScreen(),
                        //             arguments: details);
                        //         // Get.to(()=>VisitingCardlistScreen());
                        //       },
                        //       child: CustomText('View All',
                        //           fontWeight: FontWeight.w600,
                        //           fontSize: SizeConfig.size14,
                        //           color: AppColors.black),
                        //     ),
                        //   ],
                        // ),

                        VisitingCardPreview(details: details),
                        SizedBox(height: SizeConfig.size20),
                        Column(
                          children: [
                            buildCard1(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard2(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard3(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard4(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard5(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard6(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard7(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard8(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard9(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard10(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard11(details!),
                          ],
                        )
                        //
                        //                   // Footer actions
                        //                   Align(
                        //                     alignment: Alignment.center,
                        //                     child: ElevatedButton.icon(
                        //                       style: ElevatedButton.styleFrom(
                        //                         shape: const StadiumBorder(),
                        //                         // backgroundColor: accentChip, // per theme
                        //                         foregroundColor: Colors.white,
                        //                       ),
                        //                       onPressed: () {
                        //                         Navigator.of(context).maybePop();
                        //                       },
                        //                       icon: const Icon(Icons.ios_share,color: AppColors.black,),
                        //                       label: Text(
                        //                           AppLocalizations.of(context)!.shareVisitingCard,style: TextStyle(color: AppColors.black),
                        //                           ),
                        //                     ),
                        //                   ),
                      ],
                    )))
              ]),
            ),
          ),
        );
      },
    );
  }
}
