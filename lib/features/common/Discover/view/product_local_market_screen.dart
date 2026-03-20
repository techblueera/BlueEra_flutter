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
import 'package:BlueEra/features/common/store/view/new_store/all_product_store_screen.dart';
import 'package:BlueEra/features/common/store/view/new_store/business_store_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/update_live_photo_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductLocalMarketScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> businessProductsCategories;
  final List<OnboardingCategoryModel> businessProductStoreCategories;

  const ProductLocalMarketScreen({
    super.key,
    required this.businessProductsCategories,
    required this.businessProductStoreCategories,
  });

  @override
  State<ProductLocalMarketScreen> createState() =>
      _ProductLocalMarketScreenState();
}

class _ProductLocalMarketScreenState extends State<ProductLocalMarketScreen> {
  late PageController _pageController;
  int selectedTabIndex = 0;
  late List<OnboardingCategoryModel> _businessProductsCategories;
  late List<OnboardingCategoryModel> _businessProductStoreCategories;

  @override
  void initState() {
    super.initState();
    _businessProductsCategories = List.from(widget.businessProductsCategories);
    _businessProductStoreCategories = List.from(widget.businessProductStoreCategories);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 4. Handle Tab Click (Animates Page)
  void _onTabTapped(int index) {
    setState(() {
      selectedTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 5. Handle Page Swipe (Updates Tab)
  void _onPageChanged(int index) {
    setState(() {
      selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 6. Dynamic Grid Height Calculation ---
    // This ensures the PageView has a defined height based on content
    double screenWidth = MediaQuery.of(context).size.width;
    // Subtracted padding: Size8(body) + Size10(card) * 2 sides
    double contentWidth = screenWidth - (SizeConfig.size18 * 2);
    double itemWidth = (contentWidth - 12) / 3; // 12 is CrossAxisSpacing * 2

    // 1. Get the text scale factor (e.g., if user has Large Fonts enabled in settings)
    //  Calculate Text Height Dynamically
    // Font size * Line Height * Max Lines * Text Scale
    // double fontSize = SizeConfig.extraSmall;
    // double scaledFontSize = MediaQuery.of(context).textScaler.scale(fontSize);
    // double lineHeight = 1.2; // Standard line height
    // int maxLines = 2;
    //
    // double textBlockHeight = (lineHeight * maxLines * scaledFontSize);

    double textBlockHeight = SizeConfig.size26;

   // 2. Define your content constants (match your widget code)
    double imageHeight = SizeConfig.size60; // Your LocalAssets height
    double verticalPadding = SizeConfig.size10; // Top + Bottom padding inside card
    double spacing = SizeConfig.paddingXSL; // Space between image and text
    double borderWidth = 2.0; // Top + Bottom border width

    // 3. Sum it all up for the REAL minimum height
    double minRequiredHeight = imageHeight + textBlockHeight + verticalPadding + spacing + borderWidth;

    // 4. Compare with Proportional Height
    // We keep proportional height to ensure it looks good on big screens,
    // but minRequiredHeight ensures it never crashes on small screens/large fonts.
    double proportionalHeight = itemWidth / 1.2;

    print('Dynamic Min Height: $minRequiredHeight');
    print('Proportional Height: $proportionalHeight');

    double itemHeight = max(minRequiredHeight, proportionalHeight);

    // Calculate rows needed. Limiting to 4 rows max (12 items) for initial view if needed
    // or use _businessProductsCategories.length for full height.
    int itemCount = _businessProductsCategories.length;
    int rows = (itemCount / 3).ceil();

    // Total Height = (Rows * ItemHeight) + (Spacing * (Rows-1)) + Padding
    double gridHeight = (rows * itemHeight) + ((rows > 0 ? rows - 1 : 0) * 6) + 20;

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
                  final controller = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

                  if (controller.personalProfileDetails.value.isProfileCreated ==
                      false) {
                    Get.to(() => CreateProfileScreen());
                  } else {
                    if (userProfessionGlobal == DELIVERY_RIDER||userDesignationGlobal == BIKE_RIDER) {
                      Get.toNamed(RouteHelper.getEarnServiceAvailableOptionsScreenRoute());
                    } else {
                      Get.toNamed(
                          RouteHelper.getEarnServiceScreenRoute());
                    }
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
                    final chat = ChatViewController.inventoryAiChatListSearchModule;
                    Get.to(() => AiCommonSearchScreen(
                      chatType: AppConstants.askInventory_Chat_Type,
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
                                      const TextSpan(text: 'Your Product From '),
                                      TextSpan(
                                        text: 'Local Market.',
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
                                    hintText: 'Search Product....',
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

                // --- CATEGORY TABS & GRID SECTION ---
                CustomFormCard(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                    child: Column(
                      children: [
                        // --- 1. Top Tab Selector ---
                        Container(
                          margin: EdgeInsets.only(bottom: SizeConfig.size10),
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                          child: Row(
                            children: [
                              _buildTabButton("Product", 0),
                              const SizedBox(width: 10),
                              _buildTabButton("Shop Via Store", 1),
                            ],
                          ),
                        ),

                        // --- 2. Swipeable PageView ---
                        SizedBox(
                          height: gridHeight, // Apply calculated height
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            children: [
                              // Page 0: Product Grid
                              _buildGridPage(isStore: false),

                              // Page 1: Store Grid
                              _buildGridPage(isStore: true),
                            ],
                          ),
                        ),

                        // --- 3. Bottom Indicator ---
                        SizedBox(height: SizeConfig.size10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(2, (index) => _buildIndicator(index)),
                        ),
                      ],
                    )),

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
  Widget _buildGridPage({required bool isStore}) {
    return MasonryGridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      itemCount: !isStore ? _businessProductsCategories.length : _businessProductStoreCategories.length,
      itemBuilder: (context, index) {
        if(!isStore){
          var productData = _businessProductsCategories[index];
          return _buildCategoryItem(
            productData: productData,
            onTap: (c) {
              Get.to(() => AllProductStoreScreen(
                isShowInGrid: true,
                // providerType: ProviderType.business,
                productCategoryName: productData.name,
                productCategory: productData.slugId,
              ));
            },
          );
        }else{
          var productStores = _businessProductStoreCategories[index];
          return _buildCategoryItem(
            productData: productStores,
            onTap: (c) {
              // Handle Store Logic
              Get.to(() => BusinessStoreScreen(
                typeOfBusiness: AppConstants.product,
                selectedStoreCategoryId: c.slugId,
                selectedStoreCategoryName: c.name,
              ));
            },
          );
        }


      },
    );
  }

  // --- Widget: Tab Button ---
  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTabIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index), // Use method that triggers animation
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
              width: 0.5),
        ),
        child: CustomText(
          title,
          color: isSelected ? AppColors.white : AppColors.secondaryTextColor,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.small,
        ),
      ),
    );
  }

  // --- Widget: Animated Bottom Indicator ---
  Widget _buildIndicator(int index) {
    bool isActive = selectedTabIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isActive ? 24 : 8, 
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // --- Widget: Category Card ---
  Widget _buildCategoryItem({
    required OnboardingCategoryModel productData,
    required Function(OnboardingCategoryModel item)? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap(productData);
      },
      borderRadius: BorderRadius.circular(12),
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
              imagePath: productData.icon ?? '',
              height: SizeConfig.size60,
            ),
            SizedBox(height: SizeConfig.paddingXS),
            Container(
              height: SizeConfig.size26,
              alignment: Alignment.center,
              child: CustomText(
                productData.name,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}