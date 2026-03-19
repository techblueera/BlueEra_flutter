import 'dart:math';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/view/new_store/business_store_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/update_live_photo_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ServicesNearMeScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> businessServicesCategories;

  const ServicesNearMeScreen({
    super.key,
    required this.businessServicesCategories,
  });

  @override
  State<ServicesNearMeScreen> createState() =>
      _ServicesNearMeScreenState();
}

class _ServicesNearMeScreenState extends State<ServicesNearMeScreen> {
  late PageController _pageController;
  late List<OnboardingCategoryModel> _businessServicesCategories;
  int _activeGridPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _businessServicesCategories = widget.businessServicesCategories;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // const int itemsPerPage = 12;
    // int totalPages = (_businessServicesCategories.length / itemsPerPage).ceil();
    //
    // // ---  Dynamic Grid Height Calculation ---
    // double screenWidth = MediaQuery.of(context).size.width;
    // double contentWidth = screenWidth - (SizeConfig.size18 * 2);
    // // Calculate width per item
    // double itemWidth = (contentWidth - 12) / 3;
    //
    // double minRequiredHeight = 100.0;
    // double proportionalHeight = itemWidth / 1.1; // Tweaked ratio slightly
    // double itemHeight = max(minRequiredHeight, proportionalHeight);
    //
    // // Calculate rows needed. Limiting to 4 rows max (12 items) for initial view if needed
    // // or use _businessProductsCategories.length for full height.
    // int itemCount = min(12, _businessServicesCategories.length); // returns 12 if length is > 12, otherwise returns actual length
    // int rows = (itemCount / 3).ceil();
    //
    // // Total Height = (Rows * ItemHeight) + (Spacing * (Rows-1)) + Padding
    // double gridHeight = (rows * itemHeight) + ((rows > 0 ? rows - 1 : 0) * 6) + 20;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: SizeConfig.size10,
        title: Row(
          children: [
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Get.back(),
                icon: LocalAssets(
                  imagePath: AppIconAssets.back_arrow,
                  height: SizeConfig.paddingL,
                  width: SizeConfig.paddingL,
                  imgColor: Colors.black,
                )),
            LocalAssets(
              imagePath: AppIconAssets.currentLocationIcon,
              height: SizeConfig.size24,
              width: SizeConfig.size24,
            ),
            SizedBox(width: SizeConfig.paddingXSL),
            Expanded(
              child: CustomText(
                [
                  LocationService.userCurrentAddress.value.city,
                  LocationService.userCurrentAddress.value.state,
                ].where((e) => e.isNotEmpty).join(', '),
                fontSize: SizeConfig.large,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (isBusinessUser()) {
                  final controller =
                  getOrPut(() => ViewBusinessDetailsController());

                  if ((controller.businessProfileDetails?.data?.livePhotos ??
                      [])
                      .length <
                      3) {
                    showLivePhotoDialog(context: context);
                  } else {
                    Get.toNamed(RouteHelper.getInventoryScreenRoute());
                  }
                } else {
                  final controller =
                  getOrPut(() => ViewPersonalDetailsController(), permanent: true);

                  if (controller.personalProfileDetails.value.isProfileCreated ==
                      false) {
                    Get.to(() => CreateProfileScreen());
                  } else {
                    if (userProfessionGlobal == DELIVERY_RIDER) {
                      Get.toNamed(RouteHelper.getEarnServiceAvailableOptionsScreenRoute());
                    } else {
                      Get.toNamed(
                          RouteHelper.getEarnServiceScreenRoute());
                    }
                    // if (userProfessionGlobal == DELIVERY_RIDER) {
                    //   Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
                    // } else {
                    //   Get.toNamed(
                    //       RouteHelper.getEarnServiceScreenRoute());
                    // }
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                child: LocalAssets(
                  imagePath: AppIconAssets.cartIcon,
                ),
              ),
            ),
          ),
          SizedBox(width: SizeConfig.paddingXSL),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8, vertical: SizeConfig.size15),
            child: Column(
              children: [
                // --- Header Card ---
                InkWell(
                  onTap: (){
                    final chat = ChatViewController.serviceAiChatListSearchModule;
                    Get.to(() => AiCommonSearchScreen(
                      chatType: AppConstants.askService_Chat_Type,
                      profileImage: chat?.sender?.profileImage,
                      name: chat?.sender?.name,
                      contactNo: chat?.sender?.contactNo,
                      conversationId: '',
                      userId: '',
                      businessId: '',
                      type: chat?.sender?.accountType,
                      isInitialMessage: false,
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: SizeConfig.size14,
                      right: SizeConfig.size14,
                      top: SizeConfig.size14,
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: AppColors.blueShade.withValues(alpha: 0.1)),
                        gradient: LinearGradient(colors: [
                          AppColors.blueShade.withValues(alpha: 0.02),
                          AppColors.blueShade.withValues(alpha: 0.3)
                        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    child: Row(
                      children: [
                        LocalAssets(
                            imagePath: AppImageAssets.sampleGirlImage,
                            width: SizeConfig.size90,
                            boxFix: BoxFit.cover),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: CustomText('Hi!',
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.mainTextColor,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                height: SizeConfig.size5,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.mainTextColor,
                                        fontWeight: FontWeight.w400),
                                    children: [
                                      const TextSpan(text: 'May I '),
                                      TextSpan(
                                        text: 'Help You',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      const TextSpan(text: ' to Find Out'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: SizeConfig.size5,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.mainTextColor,
                                        fontWeight: FontWeight.w400),
                                    children: [
                                      const TextSpan(text: 'Your Near By '),
                                      TextSpan(
                                        text: 'Services.',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: SizeConfig.size12),
                              Container(
                                height: SizeConfig.size32,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                alignment: Alignment.center,
                                child: TextFormField(
                                  autofocus: false,
                                  enabled: false,
                                  controller: TextEditingController(),
                                  style: TextStyle(
                                      color: AppColors.mainTextColor,
                                      fontSize: SizeConfig.medium),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: 'Search Service....',
                                    hintStyle: TextStyle(
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.secondaryTextColor),
                                    isDense: true,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        top: SizeConfig.size5,
                                        bottom: SizeConfig.size5,
                                      ),
                                      child: Icon(Icons.search,
                                          color: AppColors.secondaryTextColor,
                                          size: SizeConfig.paddingXL),
                                    ),
                                    suffixIcon: Padding(
                                      padding: EdgeInsets.only(
                                          left: SizeConfig.size8,
                                          right: SizeConfig.size16,
                                          top: SizeConfig.size5,
                                          bottom: SizeConfig.size5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.mic_none_outlined,
                                              color: AppColors.secondaryTextColor,
                                              size: SizeConfig.paddingXL),
                                          SizedBox(width: SizeConfig.size10),
                                          Icon(Icons.camera_alt_outlined,
                                              color: AppColors.secondaryTextColor,
                                              size: SizeConfig.paddingXL),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.paddingXSL),

                // // --- CATEGORY TABS & GRID SECTION ---
                // CustomFormCard(
                //     padding: EdgeInsets.all(SizeConfig.size10),
                //     child: Column(
                //       children: [
                //
                //         SizedBox(
                //             height: gridHeight,
                //             child: PageView.builder(
                //                 controller: _pageController,
                //                 itemCount: totalPages,
                //                 onPageChanged: (int index) {
                //                   setState(() {
                //                     _activeGridPage = index;
                //                   });
                //                 },
                //                 itemBuilder: (context, pageIndex) {
                //                   // 4. Calculate Slicing Indices
                //                   final int startIndex = pageIndex * itemsPerPage;
                //                   final int endIndex = (startIndex + itemsPerPage < _businessServicesCategories.length)
                //                       ? startIndex + itemsPerPage
                //                       : _businessServicesCategories.length;
                //
                //                   print("Page: $pageIndex | Range: $startIndex - $endIndex | Total Items: ${_businessServicesCategories.length}");
                //
                //                   // 5. Get the sublist for this specific page
                //                   final List<OnboardingCategoryModel> pageItems = _businessServicesCategories.sublist(startIndex, endIndex);
                //
                //                   return _buildGridPage(pageItems);
                //                 },
                //             )
                //         ),
                //
                //         // --- Bottom Indicator ---
                //         if (totalPages > 1) ...[
                //           SizedBox(height: SizeConfig.size10),
                //           Row(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: List.generate(
                //               totalPages,
                //                   (index) => _buildIndicator(index),
                //             ),
                //           ),
                //         ],
                //       ],
                //     )
                // ),

                CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child:  _buildGridPage(_businessServicesCategories)
                ),

                SizedBox(height: SizeConfig.paddingXSL),

                // --- Bottom Banner ---
                CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText('Best Deal In Your City',
                            fontSize: SizeConfig.medium,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w600),
                        SizedBox(height: SizeConfig.paddingXSL),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: SizeConfig.size180,
                            width: SizeConfig.screenWidth,
                            child: LocalAssets(
                              imagePath: AppImageAssets.medicalHealthService,
                              boxFix: BoxFit.cover,
                            ),
                          ),
                        )
                      ],
                    ))
              ],
            ),
          )),
    );
  }

  // --- Widget: Grid Page (Reusable) ---
  Widget _buildGridPage(List<OnboardingCategoryModel> items) {
    return MasonryGridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      primary: false,
      itemCount: items.length,
      itemBuilder: (context, index) {
        var serviceData = items[index];
        return _buildCategoryItem(
          serviceCategory: serviceData,
          onTap: (c) {
            Get.to(() => BusinessStoreScreen(
              typeOfBusiness: AppConstants.service,
              selectedStoreCategoryId: c.slugId,
              selectedStoreCategoryName: c.name,
            ));
          },
        );
      },
    );
  }

  // // --- Widget: Animated Bottom Indicator ---
  // Widget _buildIndicator(int index) {
  //   bool isActive = _activeGridPage == index;
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     margin: const EdgeInsets.symmetric(horizontal: 4),
  //     height: 4,
  //     width: isActive ? 24 : 8,
  //     decoration: BoxDecoration(
  //       color: isActive ? AppColors.primaryColor : Colors.grey.shade300,
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //   );
  // }

  // --- Widget: Category Card ---
  Widget _buildCategoryItem({
    required OnboardingCategoryModel serviceCategory,
    required Function(OnboardingCategoryModel item)? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap(serviceCategory);
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: AppColors.greyE5,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: serviceCategory.icon??'',
              height: SizeConfig.size60,
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            CustomText(
              serviceCategory.name,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}