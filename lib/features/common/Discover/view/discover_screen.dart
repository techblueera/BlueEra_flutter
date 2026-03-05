import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ask_chat_screen.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/find_contact_with_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/all_education_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_professional_consultant_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_self_profession_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_banner_slider.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/health_care_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_product_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/product_local_market_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/choose_deliivery_option_dialog.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../me/grocery/widget/grocery_data.dart';
import 'book_your_transport/book_transport_main.dart';


class ResponsiveSearchBar extends StatelessWidget {
  const ResponsiveSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        return Container(
          width: Get.width,
          padding: EdgeInsets.only(bottom: 10, top: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xff0085FE).withValues(alpha: 0.20), // Bottom color
                Color(0xff0085FE).withValues(alpha: 0), // Bottom color
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: width > 600 ? 600 : width * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryColor, width: 0.5),
              ),
              child: Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.search),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: CustomText(
                      AppStrings.searchAnything,
                      fontSize: 16,
                    ),
                  ),
                  LocalAssets(
                    imagePath: AppIconAssets.mic,
                    width: 20,
                    height: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 10),
                  LocalAssets(
                    imagePath: AppIconAssets.camera_black,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible)? onHeaderVisibilityChanged;

  const DiscoverScreen(
      {super.key,
      required this.isHeaderVisible,
      this.onHeaderVisibilityChanged});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => DiscoverController());
  TabController? _tabController;

  // late MapplsMapController mapController;
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  late final double userLat;
  late final double userLng;
  // bool isMapLoading = true;
  // BitmapDescriptor? _customIcon;

  @override
  void initState() {
    userLat = LocationService.lat;
    userLng = LocationService.lng;
    _tabController = TabController(length: 3, vsync: this);
    // _loadMarkerAsset();
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = View.of(context).physicalSize.width < 400;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android Black
        statusBarBrightness: Brightness.light,    // iOS Black
      ),
      child: Scaffold(
          backgroundColor: AppColors.whiteF3,
          body: SafeArea(child: Obx(() => _buildMainBody(isSmallScreen)))),
    );
  }

  void chooseDeliveryOption() {
    Get.dialog(
      ChooseDeliveryOptionDialog(),
      barrierDismissible: false,
    );
  }

  Widget _buildMainBody(bool isSmallScreen) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          widget.onHeaderVisibilityChanged?.call(false);
        } else if (notification.direction == ScrollDirection.forward) {
          widget.onHeaderVisibilityChanged?.call(true);
        }
        return true; // Stop the notification from bubbling further
      },
      child: NestedScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: false,
              floating: true,
              snap: true,
              forceElevated: innerBoxIsScrolled,
              // Adds shadow when content slides under
              title: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.currentLocationIcon,
                    height: SizeConfig.size24,
                    width: SizeConfig.size24,
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomText(
                      [
                        LocationService.userCurrentAddress.value.subLocality,
                        LocationService.userCurrentAddress.value.city,
                      ].where((e) => e.isNotEmpty).join(', '),
                      fontSize: SizeConfig.medium,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size16),
                  child: InkWell(
                    onTap: () {
                      // ... your existing tap logic ...
                    },
                    child: LocalAssets(
                      imagePath: AppIconAssets.location_new,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size16),
                  child: InkWell(
                    onTap: () {
                      commonSnackBar(message: "Coming soon....");
                      // ... your existing tap logic ...
                    },
                    child: LocalAssets(imagePath: AppIconAssets.cartIcon),
                  ),
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: isSmallScreen,
                  tabAlignment:
                  isSmallScreen ? TabAlignment.start : TabAlignment.fill,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.secondaryTextColor,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 3.0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: AppStrings.overview.tr),
                    Tab(text: AppStrings.contact.tr),
                    Tab(text: AppStrings.bestDeal.tr),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _discoverWidget(),
            FindContactWithService(fromBottomNav: true),
            // FavouriteCategoryListScreen(),
            SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _discoverWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ResponsiveSearchBar()),
          _buildGap(),

          SliverToBoxAdapter(child: DiscoverBannerSlider()),
          _buildGap(gap: SizeConfig.paddingM),

          /// Delivery Option
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
                bgImage: "discover_bg_card_green.png",
                padding: EdgeInsets.all(SizeConfig.size10),
                child: InkWell(
                  onTap: () => chooseDeliveryOption(),
                      // Get.toNamed(RouteHelper.getRiderStoreScreenRoute()),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _title(AppStrings.bookYourGroceryNdFood),
                          ),
                          SizedBox(width: SizeConfig.paddingXSL),
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      _buildMasonryGridWithIcons(
                          items: [
                            ...GroceryData.grocerySuperCategories.take(3).toList(),
                            ...foodCategories.take(3).toList()
                          ],
                          crossAxisCount: 3,
                          getName: (item) => item.name,
                          getIcon: (item) => item.image,
                          onTap: (item) => chooseDeliveryOption(),
                        // onTap: (item) => Get.toNamed(
                        //     RouteHelper.getRiderStoreScreenRoute())),
                        )

                    ],
                  ),
                )),
          ),

          _buildGap(),

          /// Product
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
                padding: EdgeInsets.all(SizeConfig.size10),
                bgImage: "discover_bg_card_cream.png",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _title(AppStrings.shopping.tr),
                        ),
                        SizedBox(
                          width: SizeConfig.size8,
                        ),
                        _viewAll(
                              () => Get.to(() => ProductLocalMarketScreen(
                            businessProductsCategories:
                            businessProductsCategories,
                            businessProductStoreCategories:
                            businessProductStoreCategories,
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _buildProductMasonryGrid(),
                  ],
                )),
          ),

          _buildGap(),

          /// Medical
          SliverToBoxAdapter(
            child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(AppStrings.bookHealthService),
                  SizedBox(height: SizeConfig.paddingXSL),
                  Stack(
                    children: [
                      // The background image
                      _bannerWidget(
                        bannerImage: AppImageAssets.medicalHealthService,
                        bannerHeight: SizeConfig.size180,
                      ),
                      // Gradient Overlay (Optional: Makes text/buttons more readable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3)
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Scrollable Buttons
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: _buildHorizontalTabs([
                          'Hospitals',
                          'Pharmacy',
                          'Labs Test',
                          'Doctors',
                          'Wellness'
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Self work
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_blue.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.bookHomeServices),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(() => Get.to(() => AllSelfProfessionScreen(
                        selfEmployedCategories:
                        individualSkillWorkList.toList(),
                      ))),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildBookHomeServiceMasonryGrid(),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Home made food, product, service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_yellow.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(AppStrings.homemadeProducts),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildHomeMadeFoodServiceMasonryGrid(),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Stay Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_green.png",
              // color: AppColors.blueF4,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.bookYourStay),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      // _viewAll(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: stayItemsCategories,
                      crossAxisCount: 2,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon,
                      onTap: (c) {
                        Get.to(() => AllStayServiceScreen(
                            stayCategories: stayItemsCategories,
                            selectedStayCategory: c));
                      }),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Consultation Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_cream.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.professionals),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(
                            () => Get.to(() => AllProfessionConsultantScreen(
                          professionalConsultantCategories:
                          individualOnboardingConsultationList,
                        )),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildProfConsultantServiceMasonryGrid(),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Transport
          SliverToBoxAdapter(
            child: InkWell(
              onTap: () {
                Get.to(BookTransportMain());
              },
              child: CustomFormCardBGImg(
                bgImage: "discover_bg_card_blue.png",
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(AppStrings.bookYourTransport),
                    SizedBox(height: SizeConfig.paddingXSL),
                    CustomFormCard(
                      isBorderAvailable: true,
                      padding: EdgeInsets.all(SizeConfig.size10),
                      // IntrinsicHeight ensures the vertical line stretches to match the fields
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // 1. LEFT SECTION: Icons and Dotted Line
                            Column(
                              children: [
                                const Icon(Icons.home_outlined,
                                    color: AppColors.secondaryTextColor,
                                    size: 16),

                                // The Dotted Line
                                Expanded(
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                    child: CustomPaint(
                                      size: const Size(1, double.infinity),
                                      painter: DottedLinePainter(),
                                    ),
                                  ),
                                ),

                                const Icon(Icons.location_on_outlined,
                                    color: AppColors.redLite, size: 16),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // 2. MIDDLE SECTION
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // From
                                  CustomText(
                                      "${LocationService.userCurrentAddress.value.formattedAddress}",
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.greyBf,
                                      fontWeight: FontWeight.w400),

                                  SizedBox(height: SizeConfig.paddingS),

                                  // Divider
                                  CommonHorizontalDivider(
                                      height: 1, color: AppColors.greyBf),

                                  SizedBox(height: SizeConfig.paddingS),

                                  // To
                                  CustomText("To",
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.greyBf,
                                      fontWeight: FontWeight.w400)
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // 3. RIGHT SECTION: Swap Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: AppColors.greyE5),
                                boxShadow: [AppShadows.textFieldShadow],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.swap_vert,
                                    color: AppColors.secondaryTextColor),
                                onPressed: () {
                                  // Add swap logic here
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _buildMasonryGridWithIcons(
                        items: transportItemsCategories,
                        crossAxisCount: 2,
                        getName: (item) => item.name,
                        getIcon: (item) => item.icon,
                        onTap: (item) {
                          Get.to(()=> BookTransportMain(
                            vehicleType: item.slugId,
                          ));
                        }),
                  ],
                ),
              ),
            ),
          ),
          _buildGap(),

          /// Stay Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_yellow.png",
              // color: AppColors.blueF4,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.rentalServices),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      // _viewAll(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: stayHomeItemsCategories,
                      crossAxisCount: 2,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon,
                      onTap: (c) {
                        Get.to(() => AllStayServiceScreen(
                            stayCategories: stayHomeItemsCategories,
                            selectedStayCategory: c));
                      }),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_green.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.findServices),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      InkWell(
                        onTap: () => Get.to(() => ServicesNearMeScreen(
                          businessServicesCategories: businessOnboardingServicesCategories,
                        )),
                        child: _viewAll(),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildFindServiceMasonryGrid(),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Financial Sectors
          SliverToBoxAdapter(
            child: CustomFormCard(
              border: Border.all(
                  color: AppColors.greyA5
              ),
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: _title(AppStrings.financialSectors),
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildFinancialSectorUi()
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Automotive Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_cream.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(AppStrings.automotiveShowroom),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: automotiveServiceItemsCategories,
                      crossAxisCount: 3,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon,
                      onTap: (_) {
                        commonSnackBar(message: "Coming Soon...");
                      }),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Restorent
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_blue.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.restaurantNearby),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildRestaurantNearServiceMasonryGrid(),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Education Service
          SliverToBoxAdapter(
            child: CustomFormCardBGImg(
              bgImage: "discover_bg_card_yellow.png",
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title(AppStrings.educationTraining),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: businessOnboardingEducationTrainingCategories,
                      crossAxisCount: 3,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon,
                      onTap: (c) {
                        Get.to(() => AllEducationServiceScreen(
                            professionalConsultantCategories:
                            businessOnboardingEducationTrainingCategories,
                            selectedProfessionConsultantData: c));
                      }),
                ],
              ),
            ),
          ),

          _buildGap(),

          /// Near By Jobs
          SliverToBoxAdapter(
            child: InkWell(
              onTap: () {
                Widget dest =
                isGuestUser() ? GuestDashBoardScreen() : JobsScreen();

                Get.to(() => dest);
              },
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(AppStrings.findDreamJob),
                    SizedBox(height: SizeConfig.paddingXSL),
                    Stack(
                      children: [
                        _bannerWidget(
                            bannerImage: AppImageAssets.jobBanner,
                            bannerHeight: SizeConfig.size180),
                        Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: _buildHorizontalJobTabs([
                              'Full-Time',
                              'Part-Time',
                              'Online',
                              'Offline',
                              'Near By'
                            ]))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildGap(),

          SliverToBoxAdapter(child: searchProductsViaAiWidget()),

          _buildGap(),

          SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
            sliver: SliverToBoxAdapter(
              child: Builder(builder: (_) {
                getOrPut(() => EmergencyProfileController());
                return EmergencyQrWidget(key: ValueKey('emergency_qr'));
              }),
            ),
          ),
          
        ]


      ),
    );
  }

  Widget _title(String title) {
    return CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600);
  }

  Widget _viewAll([VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: CustomText(AppStrings.viewAll,
          fontSize: SizeConfig.medium,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600),
    );
  }

  Widget _buildGap({double? gap}) {
    return SliverToBoxAdapter(child: SizedBox(height: gap ?? SizeConfig.paddingXSL));
  }

  Widget _bannerWidget(
      {required String bannerImage, required double bannerHeight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        // Using SizedBox is more lightweight than Container
        height: bannerHeight,
        width: SizeConfig.screenWidth,
        child: LocalAssets(
          imagePath: bannerImage,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

  Widget genericSquareRow<T>({
    required List<T> items,
    required String Function(T item) labelBuilder,
    required String Function(T item) iconBuilder,
    required Function(T item) onTap,
    int itemsPerRow = 5,
    double spacing = 6.0,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalSpacing = spacing * (itemsPerRow - 1);
        final double itemSize =
            (constraints.maxWidth - totalSpacing) / itemsPerRow;

        return SizedBox(
          height: itemSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: items
                .asMap()
                .entries
                .map((entry) {
                  final int index = entry.key;
                  final T item = entry.value;

                  return Row(
                    children: [
                      _buildContainer(
                        size: itemSize,
                        text: labelBuilder(item),
                        icon: iconBuilder(item),
                        onTap: () => onTap(item),
                      ),
                      if (index != items.take(itemsPerRow).length - 1)
                        SizedBox(width: spacing),
                    ],
                  );
                })
                .take(itemsPerRow)
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildContainer({
    required double size,
    required String text,
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: size,
        // Calculated Width
        height: size,
        // Same as Width = Square
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
          // boxShadow: [AppShadows.textFieldShadow]
        ),
        padding: EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: icon,
              height: size * 0.3,
              width: size * 0.3,
            ),
            SizedBox(height: SizeConfig.size3),
            CustomText(
              text,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalTabs(List<String> arrTabs) {
    final displayTabs = arrTabs.length > 5 ? arrTabs.sublist(0, 5) : arrTabs;

    return SizedBox(
      height: SizeConfig.size30,
      width: SizeConfig.screenWidth,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayTabs.asMap().entries.map((entry) {
            int index = entry.key;
            String title = entry.value;
            return Expanded(
              child: InkWell(
                onTap: () {
                  OnboardingCategoryModel? onboardingCategoryModel;
                  if (title == "Hospitals") {
                    onboardingCategoryModel = OnboardingCategoryModel(
                        name: 'Hospitals',
                        icon: '',
                        slugId: HOSPITAL,
                        accountType: '');
                  } else if (title == "Pharmacy") {
                    onboardingCategoryModel = OnboardingCategoryModel(
                        name: 'Pharmacy',
                        icon: '',
                        slugId: PHARMACY,
                        accountType: '');
                  } else if (title == "Labs Test") {
                    onboardingCategoryModel = OnboardingCategoryModel(
                        name: 'Labs',
                        icon: '',
                        slugId: LABTEST,
                        accountType: '');
                  } else if (title == "Doctors") {
                    onboardingCategoryModel = OnboardingCategoryModel(
                        name: 'Doctors',
                        icon: '',
                        slugId: CLINIC_DOCTORS,
                        accountType: '');
                  } else if (title == "Wellness") {
                    onboardingCategoryModel = OnboardingCategoryModel(
                        name: 'Wellness',
                        icon: '',
                        slugId: ALTERNATIVE_WELLNESS,
                        accountType: '');
                  }
                  Get.to(HealthCareListingScreen(
                    selectedProfessionConsultantData: onboardingCategoryModel,
                  ));
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    right:
                        index == displayTabs.length - 1 ? 0 : SizeConfig.size6,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            title,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.white,
                            fontWeight: FontWeight.w400,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHorizontalJobTabs(List<String> arrTabs) {
    final displayTabs = arrTabs.length > 5 ? arrTabs.sublist(0, 5) : arrTabs;

    return SizedBox(
      height: SizeConfig.size30,
      width: SizeConfig.screenWidth,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayTabs.asMap().entries.map((entry) {
            int index = entry.key;
            String title = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == displayTabs.length - 1 ? 0 : SizeConfig.size6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.white,
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildProductMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: businessProductsCategories.take(9).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = businessProductsCategories[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon ?? '',
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            Get.to(() => ProductLocalMarketScreen(
                  businessProductsCategories: businessProductsCategories,
                  businessProductStoreCategories:
                      businessProductStoreCategories,
                ));
          },
        );
      },
    );
  }

  Widget _buildBookHomeServiceMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: individualSkillWorkList.take(6).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = individualSkillWorkList[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon ?? '',
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            var categoryItem = individualSkillWorkList[index];

            Get.to(() => AllSelfProfessionScreen(
                selfEmployedCategories: individualSkillWorkList,
                selectedSelfProfessionData: categoryItem));
          },
        );
      },
    );
  }

  Widget _buildRestaurantNearServiceMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: businessOnboardingFoodsCategories.take(6).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = businessOnboardingFoodsCategories[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon ?? '',
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            commonSnackBar(message: "Coming soon...");
          },
        );
      },
    );
  }

  Widget _buildFindServiceMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: businessOnboardingServicesCategories.take(6).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = businessOnboardingServicesCategories[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon ?? '',
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            Get.to(() => ServicesNearMeScreen(
                  businessServicesCategories: businessOnboardingServicesCategories,
                ));
          },
        );
      },
    );
  }

  Widget _buildProfConsultantServiceMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: individualOnboardingConsultationList.take(6).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = individualOnboardingConsultationList[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon ?? '',
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            var categoryItem = individualOnboardingConsultationList[index];

            Get.to(() => AllProfessionConsultantScreen(
                professionalConsultantCategories:
                    individualOnboardingConsultationList,
                selectedProfessionConsultantData: categoryItem));
          },
        );
      },
    );
  }

  Widget _buildHomeMadeFoodServiceMasonryGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: homeMadeItemsCategories.take(3).length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var categoryItem = homeMadeItemsCategories[index];
        return InkWell(
          onTap: () {
            if (categoryItem.slugId == SERVICE) {
              Get.to(() => HomeServiceScreen());
            } else if (categoryItem.slugId == FOOD) {
              Get.to(() => HomeMadeFoodScreen());
            } else if (categoryItem.slugId == PRODUCT) {
              Get.to(() => HomeMadeProductScreen());
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LocalAssets(
                  imagePath: categoryItem.icon ?? '',
                  height: SizeConfig.size140,
                  width: double.maxFinite,
                  boxFix: BoxFit.cover,
                ),
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              Container(
                height: SizeConfig.size30,
                alignment: Alignment.center,
                child: CustomText(
                  categoryItem.name,
                  fontSize: SizeConfig.small11,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialSectorUi() {
    return SizedBox(
      height: SizeConfig.size124,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
        shrinkWrap: true,
        primary: false,
        itemCount: financeCategories.length,
        scrollDirection: Axis.horizontal,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          var categoryItem = financeCategories[index];
          return InkWell(
            onTap: (){
              commonSnackBar(message: "Coming Soon...");
            },
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size10),
              margin: EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [AppShadows.textFieldShadow],
                border: Border.all(
                    color: AppColors.greyE5,
                    width:  1.0
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LocalAssets(
                    imagePath: categoryItem.icon??'',
                    height: SizeConfig.size60,
                    width: SizeConfig.size80,
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  Container(
                    height: SizeConfig.size30,
                    alignment: Alignment.center,
                    child: CustomText(
                      categoryItem.name,
                      fontSize: SizeConfig.small11,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
          // return CommonServiceCard(
          //   service: categoryItem,
          //   getName: (item) => item.name,
          //   getIcon: (item) => item.icon ?? '',
          //   iconHeight: SizeConfig.size60,
          //   margin: EdgeInsets.only(right: 6),
          //   onTap: (item) {
          //     commonSnackBar(message: "Coming Soon...");
          //   },
          // );
        },
      ),
    );
  }

  Widget _buildMasonryGridWithIcons<T>(
      {required List<T> items,
      required Function(T) getName,
      required Function(T) getIcon,
      required Function(T) onTap,
      required int crossAxisCount}) {
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: items.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var item = items[index];
        return CommonServiceCard(
          service: item,
          getName: (item) => getName(item),
          getIcon: (item) => getIcon(item),
          iconHeight: SizeConfig.size60,
          onTap: (item) => onTap(item),
        );
      },
    );
  }

  Widget searchProductsViaAiWidget() {
    return InkWell(
      onTap: () {
        final chat = ChatViewController.inventoryAiChatListSearchModule;
        Get.to(() => AskChatScreen(
              // profileImage: AppImageAssets.sampleGirlImage,
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
            border:
                Border.all(color: AppColors.blueShade.withValues(alpha: 0.1)),
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
                    child: CustomText(AppStrings.hi,
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
                          TextSpan(text: AppStrings.mayI.tr),
                          TextSpan(
                            text: AppStrings.helpYou.tr,
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                            ),
                          ),
                          TextSpan(text: AppStrings.toFindOut.tr),
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
                          TextSpan(text: AppStrings.yourProductFrom.tr),
                          TextSpan(
                            text: AppStrings.localMarket.tr,
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
                      enabled: false,
                      autofocus: false,
                      controller: TextEditingController(),
                      style: TextStyle(
                          color: AppColors.mainTextColor,
                          fontSize: SizeConfig.medium),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: AppStrings.searchProductPlaceholder.tr,
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
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppColors.secondaryTextColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double dashHeight = 2;
    double dashSpace = 3;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
