import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
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
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/apiService/api_keys.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../core/api/model/type_of_business_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constant.dart';
import '../../../core/constants/regular_expression.dart';
import '../../../core/controller/location_controller.dart';
import '../../../core/routes/route_helper.dart';
import '../../../core/services/multipart_image_service.dart';
import '../../../widgets/commom_textfield.dart';
import '../../../widgets/common_box_shadow.dart';
import '../../../widgets/common_drop_down-dialoge.dart';
import '../../../widgets/common_drop_down_icon_dialoge.dart';
import '../../../widgets/custom_btn.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/horizontal_tab_selector.dart';
import '../../../widgets/local_assets.dart';
import '../../../widgets/update_live_photo_dialog.dart';
import '../../common/auth/model/get_categories_model.dart';
import '../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../common/reel/view/channel/follower_following_screen.dart';
import '../../personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import '../../personal/personal_profile/view/inventory/widget/own_product_card.dart';
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
  final locationController = Get.put(LocationController());

  // List<String> postTab = [
  //   'Overview',
  //   'My Products',
  //   'Subscription',
  //   'My Posts',
  //   // 'Shorts',
  //   // 'Videos',
  // ];

  List<String> postTabs = [
    'Profile',
    'My Products',
    //'Video',
    'My Posts',
    // 'Shorts',
    // 'Videos',
  ];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  Future<void> noLocationPermissionDialogBox() async {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          title: CustomText(
            "Current Location Unavailable",
            fontSize: 16,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
          ),
          content: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  "Blue Era needs your location while using the app to provide accurate nearby services and improve your experience.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                PositiveCustomBtn(
                  onTap: () async {
                    await openAppSettings();
                    Get.back();

                    // ✅ After returning, re-check permission
                    Future.delayed(const Duration(seconds: 1), () async {
                      await _handleLocationFlow();
                    });
                  },
                  title: "Change Location Settings",
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleLocationFlow() async {
    final locationData = await locationController.checkPermissionAndSetData();

    if (locationData != null) {
      // ✅ Permission granted and location fetched
      await updateAddressFromLocation();
    } else {
      // ❌ Permission denied — show dialog
      noLocationPermissionDialogBox();
    }
  }

  @override
  void initState() {
    selectedFilter = widget.sortBy ?? SortBy.Latest;
    viewBusinessDetailsController.selectedIndex.value =
        widget.selectedIndex ?? 0;
    // details ;

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _handleLocationFlow();
    // }); // ✅ Show after build
    setFilters();
    super.initState();
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      locationData.fullAddress;
      locationData.city;
      locationData.pinCode;
      viewBusinessDetailsController.addressLat?.value =
          double.parse(locationData.lat);
      viewBusinessDetailsController.addressLong?.value =
          double.parse(locationData.long);
    }
  }

  void setFilters() {
    filters = SortBy.values.toList();
  }

  final controllerInventory = Get.put(InventoryController());
  bool isDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewBusinessDetailsController>(builder: (controller) {
      if (controller.viewBusinessResponse.status == Status.COMPLETE) {
        BusinessProfileDetails? details = viewBusinessDetailsController
            .businessProfileDetails?.data;
        if ((!isDialogShown &&
            (details?.businessLocation == null ||
                details?.businessLocation?.lat == null ||
                details?.businessLocation?.lon == null ||
                details?.businessLocation?.lat == 0.0 ||
                details?.businessLocation?.lon == 0.0))) {
          isDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateLocationDialog(context, details,true);
          });
        }
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12,),
              HorizontalTabSelector(
                horizontalMargin: 2,
                tabs: postTabs,
                selectedIndex:
                viewBusinessDetailsController.selectedIndex.value,
                onTabSelected: (index, value) {
                  setState(() =>
                  viewBusinessDetailsController
                      .selectedIndex.value = index);
                },
                labelBuilder: (label) => label,
              ),
              SizedBox(height: 14,),


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
                  controller, viewBusinessDetailsController.selectedIndex.value,
                  details)
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

  Widget _buildTabContent(ViewBusinessDetailsController controller, int index,
      BusinessProfileDetails? details) {
    switch (postTabs[index]) {
      case 'Profile':
        return Column(
          children: [
            BusinessProfileHeader(
              details: details,
              controller: viewBusinessDetailsController,
            ),
            BusinessProfileWidget(),
          ],
        );
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
      case "My Products":
        return MyProductCardDetails();
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }

}

class MyProductCardDetails extends StatelessWidget {
  const MyProductCardDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final earnWithBlueEraController = Get.put(EarnWithBlueEraController())
      ..fetchOwnProducts();

    final productList = earnWithBlueEraController.ownProductDataList;

    return Column(
      children: [
        (productList.isEmpty) ?
        Center(
          child: EmptyStateWidget(
            message: 'No Products available.',
          ),
        )
            : SizedBox(
          height: 600,
          child: ListView.builder(

            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: productList.length,
            itemBuilder: (context, index) {
              final productData = productList[index];

              return Padding(
                padding: EdgeInsets.only(
                    bottom: SizeConfig.size8,
                    left: SizeConfig.size8,
                    right: SizeConfig.size8
                ),
                child: OwnProductCard(
                  product: productData,
                  isGridShow: false,
                  deleteProductApi: () {
                    // earnWithBlueEraController.deleteProduct();
                  },
                ),
              );
            },
          ),
        ),

        if (earnWithBlueEraController.isOwnProductDataLoadingMore.value)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
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
    bool _isBottomSheetOpen = false;

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
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                      (controller.coverImage?.value != null &&
                          controller.coverImage!.value!.isNotEmpty)
                          ? controller.coverImage!.value!
                          : (controller.coverImage?.value ?? ''),
                      width: double.infinity,
                      height: 130,
                      //height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox();
                      },
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
                            controller.imagePath?.value
                                .split('/')
                                .last ?? "";
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
                          try {
                            final newPath = await SelectProfilePictureDialog
                                .showLogoDialog(
                                context,
                                "Edit Cover Picture",
                                cropAspectRatio: CropAspectRatio(
                                    width: 3, height: 1)
                              // cropAspectRatio: CropAspectRatio(width: 16, height: 9)
                            ).catchError((_) => null);

                            if (newPath == null || newPath.isEmpty) {
                              commonSnackBar(message: "No image selected");
                              return;
                            }

                            controller.coverImage?.value = newPath;

                            // Compress before upload
                            final file = File(newPath);
                            final compressed = await FlutterImageCompress
                                .compressAndGetFile(
                              file.absolute.path,
                              "${file.path}_compressed.jpg",
                              quality: 75,
                            );

                            final dataImage = await multiPartImage(
                              imagePath: compressed?.path ?? newPath,
                            );

                            if (dataImage == null) {
                              commonSnackBar(
                                  message: "Image processing failed");
                              return;
                            }

                            final reqProfile = {

                              ApiKeys.businessId: businessId,
                              ApiKeys.business_name: details?.businessName,

                              "coverPicture": dataImage};
                            await controller.updateBusinessProfileDetails(
                                reqProfile);
                          } catch (e, s) {
                            debugPrint(
                                "❌ Crash in cover picture upload: $e\n$s");
                            commonSnackBar(
                                message: "Something went wrong while updating picture");
                          }
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 5),
                            decoration: BoxDecoration(
                              color: Color(0xffC5FFC9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomText(
                              "Verified Profile",
                              color: AppColors.secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                            : Flexible(
                          child: BlinkingVerifyButton(
                            onTap: () {
                              commonSnackBar(message: "Coming soon....");
                            },
                          ),
                        ),

                        SizedBox(width: SizeConfig.size10,),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BusinessDetailsEditPageOne(
                                        prevBusinessDetails: details,),
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
                  fontSize: SizeConfig.size24,
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
                      child: Row(
                        children: [
                          CustomText(
                            "${details?.categoryDetails?.name ?? ''}",
                            color: AppColors.secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          SizedBox(width: SizeConfig.size10),

                          GestureDetector(

                            onTap: () {
                              TextEditingController ownerNameCtrl = TextEditingController(
                                text: details!.ownerDetails?.first.name ?? '',
                              );

                              TextEditingController ownerRoleCtrl = TextEditingController(
                                text: details?.ownerDetails?.first
                                    .role_in_business ?? '',
                              );

                              TextEditingController ownerEmailCtrl = TextEditingController(
                                text: details?.ownerDetails?.first.email ??
                                    '',
                              );

                              openBusinessDetailsEditSheet(context);
                            },


                            child: LocalAssets(
                              imagePath: AppIconAssets.editIcon,
                              height: SizeConfig.size12,
                              width: SizeConfig.size12,
                              imgColor: AppColors.primaryColor,
                            ),
                          )
                        ],
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
                            color: AppColors.secondaryTextColor,
                          )),
                      child: Row(

                        children: [
                          CustomText(
                            "${details!.ownerDetails?.first.name ??
                                ''} (${details?.ownerDetails?.first
                                .role_in_business})",
                            color: AppColors.secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          SizedBox(width: SizeConfig.size10),

                          GestureDetector(

                            onTap: () {
                              TextEditingController ownerNameCtrl = TextEditingController(
                                text: details!.ownerDetails?.first.name ?? '',
                              );

                              TextEditingController ownerRoleCtrl = TextEditingController(
                                text: details?.ownerDetails?.first
                                    .role_in_business ?? '',
                              );

                              TextEditingController ownerEmailCtrl = TextEditingController(
                                text: details?.ownerDetails?.first.email ??
                                    '',
                              );

                              openOwnerEditSheet(
                                context: context,
                                nameController: ownerNameCtrl,
                                roleController: ownerRoleCtrl,
                                emailController: ownerEmailCtrl,
                                onSave: () async {
                                  if (!GetUtils.isEmail(
                                      ownerEmailCtrl.text.trim())) {
                                    commonSnackBar(
                                        message: "Enter valid email");
                                    return;
                                  } else {
                                    Map<String, dynamic> updatedParams = {
                                      ApiKeys.owner_details: jsonEncode([
                                        {
                                          ApiKeys.name: ownerNameCtrl.text,
                                          ApiKeys.role_in_business:
                                          ownerRoleCtrl.text,
                                          ApiKeys.email: ownerEmailCtrl.text
                                        }
                                      ]),
                                    };


                                    await Get.find<
                                        ViewBusinessDetailsController>()
                                        .updateBusinessDetails(updatedParams);
                                    Get.back();
                                  }
                                },
                              );
                            },


                            child: LocalAssets(
                              imagePath: AppIconAssets.editIcon,
                              height: SizeConfig.size12,
                              width: SizeConfig.size12,
                              imgColor: AppColors.primaryColor,
                            ),
                          ),
                        ],
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
                        onPressed: (){
                          if((controller.businessProfileDetails?.data?.livePhotos ?? []).length < 3){
                            showLivePhotoDialog(
                              context: context,
                            );
                          }else{
                            Get.toNamed(RouteHelper.getInventoryScreenRoute());

                          }
                        },
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
                                "My Store",
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
                        onPressed: () async {
                          if (_isBottomSheetOpen)
                            return; // ✅ Block second tap instantly
                          _isBottomSheetOpen = true; // ✅ Lock immediately

                          await _showVisitingCardDialog(
                              context); // Wait for sheet to close

                          _isBottomSheetOpen = false; //
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
                                "★ ${(details?.rating ?? 0).toStringAsFixed(
                                    1)}"),
                            SizedBox(
                              height: SizeConfig.size12,
                            ),
                            buildInfo("Views",
                                "${formatIndianNumber(
                                    details?.total_views ?? 0)}"),
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
                                    Get.to(() =>
                                        FollowersFollowingPage(
                                          tabIndex: 1,
                                          userID: details?.id ?? "",
                                        ));
                                  },
                                  child: buildInfo("Followers",
                                      "${formatIndianNumber(
                                          details?.total_followers ?? 0)}")),
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
                            formattedCreatedAt(details?.createdAt),
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

  Future<void> _showVisitingCardDialog(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                  const SizedBox(height: 12),

                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VisitingCardPreview(details: details),
                        SizedBox(height: SizeConfig.size20),

                        // visiting card designs
                        buildCard1(details!),
                        SizedBox(height: 20),
                        buildCard2(details!),
                        SizedBox(height: 20),
                       buildCard3(details!),
                        SizedBox(height: 20),
                        buildCard4(details!),
                        SizedBox(height: 20),
                        buildCard5(details!),
                        SizedBox(height: 20),
                        buildCard6(details!),
                        SizedBox(height: 20),
                        buildCard7(details!),
                        SizedBox(height: 20),

                        buildCard8(details!),
                        SizedBox(height: 20),
                        buildCard9(details!),
                        SizedBox(height: 20),

                        buildCard10(details!),
                        SizedBox(height: 20),
                        buildCard11(details!),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void openOwnerEditSheet({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController roleController,
  required TextEditingController emailController,
  required VoidCallback onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // important
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // close keyboard on tap outside
        child: Padding(
          // this ensures the bottom sheet moves *above* the keyboard

          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Owner Detail",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),

                CommonTextField(
                  textEditController: nameController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression: RegularExpressionUtils
                      .alphabetSpacePattern,
                  title: "Your Name",
                  hintText: "Eg., Rahul Sharma",
                  isValidate: false,
                ),

                const SizedBox(height: 16),

                CommonTextField(
                  textEditController: roleController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression: RegularExpressionUtils
                      .alphabetSpacePattern,
                  title: "Your Role in the Business",
                  hintText: "Eg., Co-founder / Owner",
                  isValidate: false,
                ),

                const SizedBox(height: 16),

                CommonTextField(
                  textEditController: emailController,
                  inputLength: 50,
                  keyBoardType: TextInputType.emailAddress,
                  regularExpression: RegularExpressionUtils.emailPattern,
                  title: "Email",
                  hintText: "Eg., yourname@email.com",
                  isValidate: false,
                ),

                const SizedBox(height: 24),

                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: "Save",
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void openBusinessDetailsEditSheet(BuildContext context) {
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();

  // Controllers pre-filled with existing data
  TextEditingController specializationCtrl = TextEditingController(
    text: viewBusinessDetailsController
        .businessProfileDetails?.data?.specification ??
        '',
  );
  final appLocalizations = AppLocalizations.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard on tap outside
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      // this ensures bottom padding adjusts dynamically with keyboard
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  "Edit Business Details",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CloseButton(),
                              ],
                            ),
                            const SizedBox(height: 20),

                            CustomText(
                              "Type of the Business",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size10),

                            CommonDropdownIconDialog<BusinessCategory>(
                              items: typeOfBusinessList,
                              selectedValue: viewBusinessDetailsController
                                  .selectedTypeOfBusiness.value,
                              hintText: appLocalizations
                                  ?.selectNatureOfTheBusiness ??
                                  "",
                              displayValue: (profession) => profession.title,
                              title: "Type of the Business",
                              onChanged: (value) {
                                viewBusinessDetailsController
                                    .selectedTypeOfBusiness.value = value!;
                                if (value.type == BusinessType.Product.name) {
                                  viewBusinessDetailsController
                                      .selectedBusinessType?.value =
                                      BusinessType.Product;
                                } else if (value.type ==
                                    BusinessType.Service.name) {
                                  viewBusinessDetailsController
                                      .selectedBusinessType?.value =
                                      BusinessType.Service;
                                } else if (value.type ==
                                    BusinessType.Food.name) {
                                  viewBusinessDetailsController
                                      .selectedBusinessType?.value =
                                      BusinessType.Food;
                                } else {
                                  viewBusinessDetailsController
                                      .selectedBusinessType?.value =
                                      BusinessType.Both;
                                }
                                viewBusinessDetailsController
                                    .selectedCategoryOfBusiness.value = null;
                                viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew.value = null;
                                viewBusinessDetailsController
                                    .businessSubCategoriesList.clear();
                              },
                              displayValueSubTitle: (profession) =>
                              profession.subTitle,
                              displayValueImagePath: (profession) =>
                              profession.icon,
                            ),

                            const SizedBox(height: 16),

                            CustomText(
                              "Category of Business ${viewBusinessDetailsController.selectedBusinessType?.value.name}",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                            ),
                            SizedBox(height: SizeConfig.size10),

                            // [log] value categoryy id--> 68ce990eeac48e6b0d4972ad
                            // [log] value categoryy name --> Education & Training Services
                            CommonDropdownDialog<CategoryData>(
                              items: viewBusinessDetailsController
                                  .businessCategoriesList,
                              title: "Category of Business Service",
                              selectedValue: viewBusinessDetailsController
                                  .selectedCategoryOfBusiness.value,
                              hintText: "Select Business Category",
                              displayValue: (category) => "${category.name}",
                              onChanged: (value) {
                                log('value categoryy id--> ${value?.id}');
                                log('value categoryy name --> ${value?.name}');
                                viewBusinessDetailsController
                                    .businessSubCategoriesList.clear();
                                viewBusinessDetailsController
                                    .businessSubCategoriesList
                                    .addAll(value?.subCategories ?? []);
                                viewBusinessDetailsController
                                    .selectedCategoryOfBusiness.value = value!;
                                viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew.value = null;
                              },
                            ),

                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                appLocalizations?.subCategory,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size10),

                            CommonDropdownDialog<SubCategories>(
                              items: viewBusinessDetailsController
                                  .businessSubCategoriesList,
                              title: "Sub-Category",
                              selectedValue: viewBusinessDetailsController
                                  .selectedSubCategoryOfBusinessNew.value,
                              hintText: "Select Sub Category",
                              displayValue: (sub) => "${sub.name}",
                              onChanged: (value) {
                                viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew.value =
                                    value;

                                log('selectedSubCategoryOfBusinessNew categoryy id -- ${viewBusinessDetailsController.selectedSubCategoryOfBusinessNew.value?.sId}');
                                log('selectedSubCategoryOfBusinessNew categoryy name-- ${viewBusinessDetailsController.selectedSubCategoryOfBusinessNew.value?.name}');

                              },
                            ),

                            const SizedBox(height: 16),

                            CommonTextField(
                              textEditController: specializationCtrl,
                              title: "Business Specialization (Optional)",
                              hintText: "Eg. South Indian Restaurant",
                              keyBoardType: TextInputType.text,
                              maxLine: 1,
                              maxLength: 24,
                              isValidate: false,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [


                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText("Shop Open Time",
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.black,
                                      ),
                                      SizedBox(height: SizeConfig.size10,),
                                      _buildDropdown(
                                          hint: "Shop Open Time",

                                          value:  viewBusinessDetailsController.shopOpenTime.value,
                                          items: List.generate(
                                            48,
                                                (i) =>
                                            "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
                                          ),
                                          onChanged: (val) {
                                            viewBusinessDetailsController.shopOpenTime.value=val??'';
                                          }
                                        // addServiceController.startTime.value = val!,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText("Shop Close Time",
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.black,

                                      ),
                                      SizedBox(height: SizeConfig.size10,),
                                      _buildDropdown(
                                          hint: "Shop Close Time",
                                          value: viewBusinessDetailsController.shopCloseTime.value,
                                          items: List.generate(
                                            48,
                                                (i) =>
                                            "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
                                          ),
                                          onChanged: (val) {
                                            viewBusinessDetailsController.shopCloseTime.value=val??'';
                                          }
                                        // addServiceController.startTime.value = val!,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            CustomBtn(
                              radius: 10,
                              bgColor: AppColors.primaryColor,
                              title: "Save",
                              onTap: () async {
                                if (viewBusinessDetailsController
                                    .selectedCategoryOfBusiness.value?.id ==
                                    null) {
                                  commonSnackBar(
                                      message: "Please select category");
                                  return;
                                }

                                if (viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew
                                    .value
                                    ?.sId ==
                                    null) {
                                  commonSnackBar(
                                      message: "Please select sub-category");
                                  return;
                                }

                                Map<String, dynamic> updatedParams = {
                                  ApiKeys.businessId: businessId,
                                  ApiKeys.category: viewBusinessDetailsController
                                      .selectedCategoryOfBusiness.value?.id,
                                  ApiKeys.sub_category:
                                  viewBusinessDetailsController
                                      .selectedSubCategoryOfBusinessNew
                                      .value
                                      ?.sId,
                                  ApiKeys.specification:
                                  specializationCtrl.text.trim(),
                                  ApiKeys.category_Of_Business: (viewBusinessDetailsController
                                      .selectedBusinessType?.value.name
                                      .toLowerCase() ==
                                      "both")
                                      ? "68a80b766fdb4e82b42b77c0"
                                      : viewBusinessDetailsController
                                      .selectedCategoryOfBusiness
                                      .value
                                      ?.id,
                                };
                                await Get.find<ViewBusinessDetailsController>()
                                    .updateBusinessDetails(updatedParams);
                              },
                            ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

}
Widget _buildDropdown({
  required String hint,
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.greyE5),
      boxShadow: [AppShadows.textFieldShadow],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        value: value.isEmpty ? null : value,
        hint: Text(hint,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        style: TextStyle(color: Colors.black87, fontSize: 14),
        items: items.map((String t) {
          return DropdownMenuItem<String>(
            value: t,
            child: Text(t),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
class BlinkingVerifyButton extends StatefulWidget {
  final VoidCallback onTap;

  const BlinkingVerifyButton({super.key, required this.onTap});

  @override
  State<BlinkingVerifyButton> createState() => _BlinkingVerifyButtonState();
}

class _BlinkingVerifyButtonState extends State<BlinkingVerifyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // speed
    )
      ..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.redLite,
                  borderRadius: BorderRadius.circular(8)),
              child: const CustomText(
                "Verify Now",
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget buildInfo(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        title + ":",
        fontSize: SizeConfig.size12,
        color: AppColors.grayText,
        fontWeight: FontWeight.w400,
      ),
      SizedBox(width: SizeConfig.size6),
      Flexible(
        child: CustomText(
          value,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ),
    ],
  );
}
