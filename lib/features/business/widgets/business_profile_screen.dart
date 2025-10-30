import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_keys.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constant.dart';
import '../../../core/services/multipart_image_service.dart';
import '../../../widgets/common_box_shadow.dart';
import '../../../widgets/horizontal_tab_selector.dart';
import '../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../common/reel/view/channel/follower_following_screen.dart';
import '../auth/controller/view_business_details_controller.dart';
import '../auth/model/viewBusinessProfileModel.dart';
import '../visit_business_profile/view/business_profile_header.dart';

import '../visiting_card/view/business_details_edit_page_one.dart';

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
              SizedBox(
                height: SizeConfig.size22,
              ),
              HorizontalTabSelector(
                tabs: postTab,
                selectedIndex:
                    viewBusinessDetailsController.selectedIndex.value,
                onTabSelected: (index, value) {
                  setState(() => viewBusinessDetailsController
                      .selectedIndex.value = index);
                },
                labelBuilder: (label) => label,
              ),
              if (viewBusinessDetailsController.selectedIndex.value ==
                      postTab.indexOf('Shorts') ||
                  viewBusinessDetailsController.selectedIndex.value ==
                      postTab.indexOf('Videos')) ...[
                _filterButtons(),
              ],
              SizedBox(
                height: SizeConfig.size10,
              ),
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

  Widget _filterButtons() {
    return SingleChildScrollView(
        padding: EdgeInsets.only(
            left: SizeConfig.large,
            right: SizeConfig.large,
            top: SizeConfig.size20),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters!.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      child: CustomText(
                        filter.label, // use .label for display text
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor:
                            isSelected ? Colors.blue : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ));
  }
}

void _showPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black38, // dim background
    builder: (context) {
      return Center(
        child: Container(
          width: 172,
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _popupItem(
                icon: Icons.share_outlined,
                text: "Share",
                onTap: () {
                  Navigator.pop(context);
                  // your share logic
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _popupItem(
                icon: Icons.block_outlined,
                text: "Report",
                onTap: () {
                  Navigator.pop(context);
                  // your report logic
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _popupItem({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 20),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class BusinessProfileHeader extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const BusinessProfileHeader(
      {super.key, required this.details, required this.controller});

  @override
  Widget build(BuildContext context) {
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
            height: 150,
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
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(
                          controller.imagePath?.value ?? "",
                        ),
                      ),
                    ),
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
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessDetailsEditPageOne(),));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
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
                      const Icon(
                        Icons.more_vert,
                        color: AppColors.mainTextColor,
                        size: 20,
                      ),
                    ],
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
                Text(
                  "${details?.businessName ?? ''}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
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
                Text(
                  "${details?.businessDescription}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                // TextButton(
                //   onPressed: () {},
                //   child: const Text("Read More"),
                // ),
                const SizedBox(height: 16),

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
}
