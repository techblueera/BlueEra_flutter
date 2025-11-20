import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/new_store/business_store_screen.dart';
import 'package:BlueEra/features/common/store/widget/StoreCategory.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
                    CommonSearchBar(
                      controller: controller.searchController,
                      height: SizeConfig.size48,
                      onSearchTap: () {
                        // handle search
                      },
                      onClearCallback: () {
      
                      },
                      backgroundColor: AppColors.white,
                      hintText: AppStrings.searchAnything,
                      borderRadius: 10.0,
                      boxBorder: Border.all(
                        color: AppColors.greyE5
                      )
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
                                seeMoreTap: () {}
                            ),
                            SizedBox(height: SizeConfig.size15),
                            _iconGrid(mainCategories)
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(),
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
                            _iconGrid(providerCategories)
      
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(),
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
                            _iconGrid(
                                serviceCategories,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.service,
                                    selectedStoreCategoryId: category.slugId,
                                    selectedStoreCategoryName: category.name,
                                ));
                              },
                            )
      
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(),
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
                            _iconGrid(
                                productCategories,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.product,
                                    selectedStoreCategoryId: category.slugId,
                                  selectedStoreCategoryName: category.name,
                                ));
                              },
                            )
                          ],
                        )
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _bannerWidget(),
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
                            _iconGrid(
                                foodCategories,
                              onTap: (category) {
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");
                                Get.to(()=> BusinessStoreScreen(
                                    typeOfBusiness: AppConstants.food,
                                    selectedStoreCategoryId: category.slugId,
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
                    isStoreProfile: true,
                    title: isBusinessUser() ? businessNameGlobal : userNameGlobal,
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
  Widget _iconGrid(
      List<StoreFeedCategory> items, {
        void Function(StoreFeedCategory category)? onTap,
      }) {
    const crossAxisCount = 4;
    const mainAxisSpacing = 16.0;

    // Split into rows of 4
    final rows = <List<StoreFeedCategory>>[];

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
              // Even index → actual item
              // Odd index → spacing
              if (i.isEven) {
                final itemIndex = i ~/ 2;

                if (itemIndex < rowItems.length) {
                  final category = rowItems[itemIndex];

                  return Expanded(
                    child: IconGridItem(
                      label: category.name,
                      icon: category.icon,
                      onTap: () {
                        if (onTap != null) onTap(category);
                        print("Tapped: ${category.slugId}");
                      },
                    ),
                  );
                } else {
                  return const Expanded(child: SizedBox());
                }
              } else {
                // spacing between items
                return SizedBox(width: SizeConfig.size8);
              }
            }),
          ),
        );
      }),
    );
  }

  // ---------------- REUSABLE BANNER WIDGET ---------------- //
  Widget _bannerWidget(){
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: SizeConfig.size160,
        width: SizeConfig.screenWidth,
        child: LocalAssets(
          imagePath: AppImageAssets.sampleProductImage,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

}
