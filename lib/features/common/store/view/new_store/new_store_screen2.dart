import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/map/view/customize_map_screen.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/new_store/all_food_store_screen.dart';
import 'package:BlueEra/features/common/store/view/new_store/all_product_store_screen.dart';
import 'package:BlueEra/features/common/store/view/new_store/business_store_screen.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/gradient_floating_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mappls_gl/mappls_gl.dart';

class NewStoreScreen2 extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  const NewStoreScreen2({
    super.key,
    required this.isHeaderVisible,
    this.onHeaderVisibilityChanged
  });

  @override
  State<NewStoreScreen2> createState() => _NewStoreScreen2State();
}

class _NewStoreScreen2State extends State<NewStoreScreen2> {
  final NewStoreController controller = Get.put(NewStoreController());
  late MapplsMapController mapController;
  late final double userLat;
  late final double userLng;
  
  @override
  void initState() {
    userLat = LocationService.lat;
    userLng = LocationService.lng;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _calculateHeaderHeight();
    });
    super.initState();
  }

  void _calculateHeaderHeight() {
    final renderBox =
    controller.headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() => controller.headerHeight = renderBox.size.height);
    }
  }

  
  @override
  void didUpdateWidget(covariant NewStoreScreen2 oldWidget) {
    if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
      controller.isHeaderVisible.value = widget.isHeaderVisible;
      super.didUpdateWidget(oldWidget);
    }
  }

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
      // Add marker
      await mapController.addSymbol(
        SymbolOptions(
            geometry: LatLng(userLat, userLng),
            iconSize: 1.5
        ),
      );

      // Move camera to the location
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(userLat, userLng),
          14.0,
        ),
      );

    } catch (e) {
      print('Error adding marker: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
              bottom: kBottomNavigationBarHeight + SizeConfig.size10
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.size35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10.0),
              child: GradientFloatingButton(
                height: SizeConfig.size70,
                width: SizeConfig.size70,
                borderRadius: SizeConfig.size35,
                borderWidth: 1.0,
                padding: EdgeInsets.all(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.30),
                      blurRadius: 4.0,
                      offset: Offset(0, 2)
                    )
                  ],
                backgroundGradientColors: const [
                  Color(0xFFFFFFFF),
                  Color(0xFFCCE0FF),
                ],
                borderGradientColors: const [
                  Color(0xFF004FCE),
                  Color(0xFF5C9BFF),
                ],
                onPressed: () {
                  print('ai chat bot btn pressed');
                },
                child: LocalAssets(imagePath: AppIconAssets.aiChatbotIcon),
              ),
            ),
          ),
        ),
        body: Obx(()=> setupScrollVisibilityNotification(
          controller: controller.scrollController,
          onVisibilityChanged: (visible, offset) {
            final currentOffset = controller.headerOffset.value;
      
            // Linear animation step (same speed up/down)
            const step = 0.25;
      
            double newOffset = currentOffset;
            if (visible) {
              // show header
              newOffset = (currentOffset - step).clamp(0.0, 1.0);
            } else {
              // hide header
              newOffset = (currentOffset + step).clamp(0.0, 1.0);
            }
      
            controller.headerOffset.value = newOffset;
            controller.isHeaderVisible.value = visible;
            widget.onHeaderVisibilityChanged?.call(visible);
          },
          child: Stack(
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: EdgeInsets.only(
                    top:  controller.headerHeight *
                        (1 - controller.headerOffset.value)),
                child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size10
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap:(){
                        Widget dest = isGuestUser()
                            ? GuestDashBoardScreen()
                            : JobsScreen();

                        Get.to(()=> dest);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size8,
                            horizontal: SizeConfig.size10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: AppColors.greyE5
                          ),
                          boxShadow: [AppShadows.textFieldShadow]
                        ),
                        child: Row(
                          children: [
                            LocalAssets(
                                imagePath: AppImageAssets.searchJobImage,
                               height: SizeConfig.size30,
                               width: SizeConfig.size30,
                            ),
                            SizedBox(width: SizeConfig.size10),
                            CustomText(
                                'Find Your Dream Job Now',
                                fontSize: SizeConfig.medium,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w400
                            ),
                          ],
                        ),
                      ),
                    ),

      
                    SizedBox(height: SizeConfig.size10),
      
                    /// Mapple map
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: double.infinity,
                          height: SizeConfig.size160,
                          child: Stack(
                            children: [
                              MapplsMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(userLat, userLng),
                                  zoom: 14.0,
                                ),
                                myLocationEnabled: false,
                                compassEnabled: false,
                                rotateGesturesEnabled: true,
                                tiltGesturesEnabled: true,
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                onStyleLoadedCallback: _onStyleLoadedCallback,
                              ),
                              Positioned(
                                right: SizeConfig.size10,
                                bottom: SizeConfig.size10,
                                child: InkWell(
                                  onTap: () async {
                                    openGoogleMaps(latitude: userLat, longitude: userLng);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(SizeConfig.size8),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.skyBlueDF, width: 1),
                                    ),
                                    child: Transform.rotate(
                                      angle: -0.6,
                                      child: const Icon(
                                        Icons.send_outlined,
                                        color: AppColors.skyBlueDF,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    SizedBox(height: SizeConfig.size10),
      
                    /// Near Me
                    CustomFormCard(
                        padding: EdgeInsets.only(
                            left: SizeConfig.size15,
                            right: SizeConfig.size15,
                            bottom: SizeConfig.size15,
                            top:  SizeConfig.size5,
                        ),
                        child: Column(
                          children: [
                            _sectionHeader(
                                title: "Near Me",
                                seeMoreTap: () {

                                }
                            ),
                            SizedBox(height: SizeConfig.size15),
                            genericIconGrid<BusinessProfileCategory>(
                                items: mainCategories,
                                labelBuilder: (c) => c.name,
                                iconBuilder: (c) => c.icon,
                                onTap: (category) => _handleNearMeCategoryTap(category)
                            )
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(AppImageAssets. sampleStoreImage1),
                    SizedBox(height: SizeConfig.size10),
      
                    /// Professionals
                    CustomFormCard(
                        padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          bottom: SizeConfig.size15,
                          top:  SizeConfig.size5,
                        ),
                        child: Column(
                          children: [
                            _sectionHeader(
                                title: "Professionals",
                                seeMoreTap: () {}
                            ),
                            SizedBox(height: SizeConfig.size15),
                            genericIconGrid<IndividualProfileCategory>(
                                items: providerCategories,
                                labelBuilder: (c) => c.name,
                                iconBuilder: (c) => c.icon,
                                onTap: (category){
                                  print("You tapped → ${category.slugId}");
                                  print("You tapped category name → ${category.name}");
                                  Get.to(()=> CustomizeMapScreen(
                                    selectedMapCategoryType: MapServiceCategory.services.label,
                                  ));
                                }
                            )
      
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(AppImageAssets.sampleStoreImage2),
                    SizedBox(height: SizeConfig.size10),
      
                    /// Services
                    CustomFormCard(
                        padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          bottom: SizeConfig.size15,
                          top:  SizeConfig.size5,
                        ),
                        child: Column(
                          children: [
                            _sectionHeader(
                                title: "Services",
                                seeMoreTap: () {}
                            ),
                            SizedBox(height: SizeConfig.size15),
                            genericIconGrid<BusinessProfileCategory>(
                              items:  businessServicesCategories,
                              labelBuilder: (c) => c.name,
                              iconBuilder: (c) => c.icon,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");
                                print("You tapped category data → ${category.categoryData}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.service,
                                    selectedStoreCategoryId: category.categoryData?.id,
                                    selectedStoreCategoryName: category.name,
                                ));
                              },
                            )
      
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(AppImageAssets.sampleStoreImage3),
                    SizedBox(height: SizeConfig.size10),
      
                    /// Store Near Me
                    CustomFormCard(
                        padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          bottom: SizeConfig.size15,
                          top:  SizeConfig.size5,
                        ),
                        child: Column(
                          children: [
                            _sectionHeader(
                                title: "Stores Near Me",
                                seeMoreTap: () {}
                            ),
                            SizedBox(height: SizeConfig.size15),
                            genericIconGrid<BusinessProfileCategory>(
                              items:  businessProductsCategories,
                              labelBuilder: (c) => c.name,
                              iconBuilder: (c) => c.icon,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");
                                print("You tapped category data → ${category.categoryData}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.product,
                                    selectedStoreCategoryId: category.categoryData?.id,
                                    selectedStoreCategoryName: category.name,
                                ));
                              },
                            )
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(AppImageAssets.sampleStoreImage4),
                    SizedBox(height: SizeConfig.size10),
      
                    /// Food & Restaurant
                    CustomFormCard(
                        padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          bottom: SizeConfig.size15,
                          top:  SizeConfig.size5,
                        ),
                        child: Column(
                          children: [
                            _sectionHeader(
                                title: "Food & Restaurant",
                                seeMoreTap: () {}
                            ),
                            SizedBox(height: SizeConfig.size15),
                            genericIconGrid<BusinessProfileCategory>(
                              items: businessFoodsCategories,
                              labelBuilder: (c) => c.name,
                              iconBuilder: (c) => c.icon,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category data → ${category.categoryData}");
                                print("You tapped category name → ${category.name}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.food,
                                    selectedStoreCategoryId: category.categoryData?.id,
                                  selectedStoreCategoryName: category.name,
                                ));
                              },
                            )
      
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
      
                  ],
                ),
              ),
            ),
      
              /// Header stays same
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                top: -controller.headerOffset.value * controller.headerHeight,
                left: 0,
                right: 0,
                child: KeyedSubtree(
                  key: controller.headerKey,
                  child: CommonBackAppBar(
                    isLeading: false,
                    isCurrentAddress: true,
                    isCartIconShow: true,
                  ),
                ),
              ),
            ],
          ),
         ),
        )
      ),
    );
  }

  // ---------------- REUSABLE SECTION HEADER ---------------- //
  Widget _sectionHeader({required String title, required VoidCallback seeMoreTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(
            title,
            fontSize: SizeConfig.large,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600
        ),
        TextButton(
          onPressed: seeMoreTap,
          child: CustomText(
              "See More",
              fontSize: SizeConfig.small,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

// ---------------- REUSABLE ICON GRID ---------------- //
  Widget genericIconGrid<T>({
    required List<T> items,
    required String Function(T item) labelBuilder,
    required String Function(T item) iconBuilder,
    void Function(T item)? onTap,
  }) {
    const crossAxisCount = 4;
    const mainAxisSpacing = 16.0;

    // Split into rows of 4
    final rows = <List<T>>[];

    for (int i = 0; i < items.length; i += crossAxisCount) {
      rows.add(
        items.sublist(
          i,
          (i + crossAxisCount).clamp(0, items.length),
        ),
      );
    }

    return Column(
      children: List.generate(rows.length, (rowIndex) {
        final rowItems = rows[rowIndex];
        final isLastRow = rowIndex == rows.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(crossAxisCount * 2 - 1, (i) {
              if (i.isEven) {
                final itemIndex = i ~/ 2;

                if (itemIndex < rowItems.length) {
                  final item = rowItems[itemIndex];

                  return Expanded(
                    child: IconGridItem(
                      label: labelBuilder(item),
                      icon: iconBuilder(item),
                      onTap: () {
                        if (onTap != null) onTap(item);
                      },
                    ),
                  );
                } else {
                  return const Expanded(child: SizedBox());
                }
              } else {
                return SizedBox(width: SizeConfig.size8);
              }
            }),
          ),
        );
      }),
    );
  }

  // ---------------- REUSABLE BANNER WIDGET ---------------- //
  Widget _bannerWidget(String bannerImage){
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: SizeConfig.size160,
        width: SizeConfig.screenWidth,
        child: LocalAssets(
          imagePath: bannerImage,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

  void _handleNearMeCategoryTap(BusinessProfileCategory category) {
    print("You tapped slug Id→ ${category.slugId}");
    print("You tapped category name → ${category.name}");
    print("You tapped category data → ${category.categoryData}");

    switch (category.slugId) {
      case AppConstants.storeServices:
        Get.to(() => BusinessStoreScreen(
          selectedStoreCategoryName: category.name,
        ));
        break;

      case AppConstants.foodServices:
        Get.to(() => AllFoodStoreScreen(
            isShowInGrid: true
        ));
        break;

      case AppConstants.productsServices:
        Get.to(() => AllProductStoreScreen(
            isShowInGrid: true
        ));
        break;

      case AppConstants.groceryVegetablesDairy:
        Get.to(() => BusinessStoreScreen(
          typeOfBusiness: AppConstants.food,
          selectedStoreCategoryId: '68ce9917eac48e6b0d4973bf',
          // selectedStoreCategoryId: category.categoryData?.id,
          selectedStoreCategoryName: category.name,
        ));
        break;

      case AppConstants.rentalServices:
        Get.to(() => CustomizeMapScreen(
          selectedMapCategoryType: MapServiceCategory.rental.label,
        ));
        break;

      case AppConstants.homeServices:
        Get.to(() => CustomizeMapScreen(
          selectedMapCategoryType: MapServiceCategory.homeService.label,
        ));
        break;
      case AppConstants.riderServices:
        break;

      default:
        print("⚠ Unknown category tapped: ${category.name}");
    }
  }


}
