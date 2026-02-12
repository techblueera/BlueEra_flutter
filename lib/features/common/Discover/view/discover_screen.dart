import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ask_chat_screen.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/find_contact_with_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/all_professional_consultant_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_self_profession_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/favourite_category_list_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_product_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/product_local_market_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'book_your_transport/book_transport_main.dart';

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

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => DiscoverController());
  // late MapplsMapController mapController;
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  late final double userLat;
  late final double userLng;
  bool isMapLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    userLat = LocationService.lat;
    userLng = LocationService.lng;
    _tabController = TabController(length: 4, vsync: this);
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
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
      controller.isHeaderVisible.value = widget.isHeaderVisible;
      super.didUpdateWidget(oldWidget);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    try {
      final markerBytes = await getBytesFromSvgAsset(
        AppIconAssets.locationMarkerIcon,
        35,
      );

      if (markerBytes.isEmpty) {
        throw Exception("Marker bytes are empty");
      }

      final markerIcon = BitmapDescriptor.bytes(markerBytes);


      final Marker customMarker = Marker(
        markerId: const MarkerId("custom_marker_id"),
        position: LatLng(userLat, userLng),
        icon: markerIcon,
        onTap: () {
          debugPrint("📍 Marker tapped");
          Get.to(() => FranchiseHome());
        },
      );


      setState(() {
        _markers.add(customMarker);
        isMapLoading = false;
      });

      debugPrint("🎉 Marker added successfully");

    } catch (e, stackTrace) {
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
    }
  }


  // Future<void> _onStyleLoadedCallback() async {
  //   try {
  //     // 1. Create the combined image
  //     final Uint8List markerBytes = await TooltipGenerator.createTooltipWithSvg(
  //       title: "BlueEra Partner\nNear you",
  //       svgAssetPath: AppIconAssets.locationMarkerIcon,
  //     );
  //
  //     // 2. Add to Map
  //     await mapController.addImage("svg-composite-icon", markerBytes);
  //
  //     // 3. Display Symbol
  //     await mapController.addSymbol(
  //       SymbolOptions(
  //         geometry: LatLng(userLat, userLng),
  //         iconImage: "svg-composite-icon",
  //         iconSize: 1.0,
  //
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error adding marker: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = View.of(context).physicalSize.width < 400;

    return SafeArea(
      child: Scaffold(
          body: SafeArea(
            child: Obx(()=> _buildMainBody(isSmallScreen))

            // child: Obx(() => setupScrollVisibilityNotification(
            //     controller: controller.scrollController,
            //     onVisibilityChanged: (visible, offset) {
            //       // final currentOffset = controller.headerOffset.value;
            //       // const step = 0.25;
            //       //
            //       // double newOffset = currentOffset;
            //       // if (visible) {
            //       //   // show header
            //       //   newOffset = (currentOffset - step).clamp(0.0, 1.0);
            //       // } else {
            //       //   // hide header
            //       //   newOffset = (currentOffset + step).clamp(0.0, 1.0);
            //       // }
            //       //
            //       // controller.headerOffset.value = newOffset;
            //       controller.isHeaderVisible.value = visible;
            //       widget.onHeaderVisibilityChanged?.call(visible);
            //     },
            //     child:
            //     Stack(
            //       children: [
            //         /// Discover Main Body
            //         _buildMainBody(isSmallScreen),
            //
            //         /// Header stays same
            //         _buildFloatingHeader(),
            //       ],
            //     )
            //   )
            // ),

          )),
    );
  }

  Widget _buildMapWidget() {
    return CustomFormCard(
     padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _title('BlueEra Partner Near you')),
              SizedBox(width: SizeConfig.size8),
              Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: AppColors.primaryColor
                    )
                  ),
                  child: CustomText(
                      LocationService.userCurrentAddress.value.postalCode,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600
                  )
              )
            ],
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: SizeConfig.size160,
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(userLat, userLng),
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    onTap: (LatLng latLng) {
                      logs("logMsg");
                      Get.to(() => FranchiseHome());
                    },
                    zoomGesturesEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),

                  if (isMapLoading)
                    Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainBody(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
      ),
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            controller.isHeaderVisible.value = false;
            widget.onHeaderVisibilityChanged?.call(false);
          } else if (notification.direction == ScrollDirection.forward) {
            controller.isHeaderVisible.value = true;
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
                  forceElevated: innerBoxIsScrolled, // Adds shadow when content slides under
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
                          imagePath: AppIconAssets.cartIcon,
                        ),
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
                      tabAlignment: isSmallScreen ? TabAlignment.start : TabAlignment.fill,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppColors.primaryColor,
                      indicatorWeight: 2,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'In Contact'),
                        Tab(text: 'Favourite'),
                        Tab(text: 'Best Deal'),
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
                FavouriteCategoryListScreen(),
                SizedBox(),
              ],
            ),

        ),
      ),
    );
  }

  Widget _discoverWidget(){
    return SingleChildScrollView(
      child: Column(
        children: [

          Padding(
              padding: EdgeInsets.only(top: SizeConfig.paddingM),
              child: _buildMapWidget(), // Extract your map code here
          ),
      
          _buildGap(gap: SizeConfig.paddingM),
      
          searchProductsViaAiWidget(),
      
          _buildGap(gap: SizeConfig.paddingM),
      
          /// Rider
          CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: InkWell(
                  onTap: () =>
                      Get.toNamed(RouteHelper.getRiderStoreScreenRoute()),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _title(AppStrings.bookYourGroceryNdFood),
                          ),
      
                          SizedBox(width: SizeConfig.paddingXSL),
      
                          // Obx(() {
                          //   return Stack(
                          //     clipBehavior: Clip.none,
                          //     children: List.generate(controller.riderList.length, (index) {
                          //       return Padding(
                          //         // Each image shifts by 15 pixels multiplied by its index
                          //         padding: EdgeInsets.only(left: index * 15.0),
                          //         child: _buildRiderImageWidget(controller.riderList[index]),
                          //       );
                          //     }),
                          //   );
                          // })
      
                          //
                          // Stack(
                          //   clipBehavior: Clip.none,
                          //   children: List.generate(3, (index) {
                          //     return Padding(
                          //       padding: EdgeInsets.only(left: index * 15.0),
                          //       child: _buildRiderImageWidget(),
                          //     );
                          //   }),
                          // )
      
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      Stack(
                        children: [
                          _bannerWidget(
                              bannerImage: AppImageAssets.riderStoreBanner,
                              bannerHeight: SizeConfig.size180
                          ),
                          Positioned(
                              left: 16.0,
                              top: 10.0,
                              child: CustomText(
                                'Rider, Grocery\nVegetables &\nMedicine',
                                fontSize: SizeConfig.title,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              )
                          )
                        ],
                      ),
                    ],
                  ),
                )),
      
      
          _buildGap(),
      
          /// Product
          CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _title('Shopping'),
                        ),
                        SizedBox(
                          width: SizeConfig.size8,
                        ),
                        _viewAll(
                              () => Get.to(() => ProductLocalMarketScreen(
                            businessProductsCategories: businessProductsCategories,
                            businessProductStoreCategories: businessProductStoreCategories,
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
      
                    _buildProductMasonryGrid(),
      
                  ],
                )),
      
      
          _buildGap(),
      
          /// Medical
          CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Book Your Health care Service'),
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
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
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
                          'Doctors',
                          'Labs',
                          'Pharmacy',
                          'Surgical'
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      
      
          _buildGap(),
      
          /// Self work
          CustomFormCard(
              color: AppColors.yellowE7,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title('Book Home Services'),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(
                              ()=> Get.to(()=> AllSelfProfessionScreen(
                            selfEmployedCategories: individualOnboardingSkillWorkList.take(12).toList(),
                          ))
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGrid(
                      items: individualOnboardingSkillWorkList.take(6).toList(),
                      icon: (item)=> item.icon,
                      name: (item)=> item.name,
                      onTap: (c){
                        Get.to(()=> AllSelfProfessionScreen(
                            selfEmployedCategories: individualOnboardingSkillWorkList.take(12).toList(),
                            selectedSelfProfessionData: c
                        ));
                      }
                  )
                ],
              ),
            ),
      
      
          // SliverToBoxAdapter(
          //   child: Row(
          //     children: [
          //       _buildVerticalLayout(
          //           imageUrl: AppImageAssets.bookNowBanner,
          //           items: rentalServiceCategories,
          //           onTap: (c) {
          //             final typeMap = {
          //               Flat_ROOM: RentalServiceType.flatRoom,
          //               HOME_STAY: RentalServiceType.homeStay,
          //               VEHICLE:   RentalServiceType.vehicle,
          //             };
          //
          //             final type = typeMap[c.slugId];
          //
          //             if (type != null) {
          //               Get.to(() => AllRentalServiceScreen(type: type));
          //             } else {
          //               // Handle unknown slug (optional)
          //             }
          //           }
          //       ),
          //       SizedBox(width: SizeConfig.paddingXSL),
          //       _buildVerticalLayout(
          //           imageUrl: AppImageAssets.homeMadeBanner,
          //           items: homeServiceCategories,
          //         onTap:(c){
          //           if(c.slugId == SERVICE) {
          //             Get.to(()=> HomeServiceScreen());
          //           }else if(c.slugId == FOOD){
          //             Get.to(()=> HomeMadeFoodScreen());
          //           }else if(c.slugId == PRODUCT){
          //             Get.to(() => AllProductScreen(
          //                 isShowInGrid: true,
          //                 providerType: ProviderType.user,
          //             ));
          //           }else{
          //             log('No category');
          //           }
          //         }
          //       ),
          //     ],
          //   ),
          // ),
      
          _buildGap(),
      
          /// Stay Service
          CustomFormCard(
              color: AppColors.blueF4,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title('Book Your Stay'),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: stayItemsCategories
                          .where((item) => discoverShownStayCategories.contains(item.slugId))
                          .toList(),
                      crossAxisCount: 2,
                      getName: (item)=> item.name,
                      getIcon: (item)=> item.icon,
                      onTap: (c){
                        Get.to(() => AllStayServiceScreen(
                            stayCategories: stayItemsCategories,
                            selectedStayCategory: c
                        ));
      
                        // final typeMap = {
                        //   Flat_ROOM: RentalServiceType.flatRoom,
                        //   HOME_STAY: RentalServiceType.homeStay,
                        //   VEHICLE:   RentalServiceType.vehicle,
                        // };
                        //
                        // final type = typeMap[c.slugId];
                        //
                        // if (type != null) {
                        //   Get.to(() => AllRentalServiceScreen(type: type));
                        // } else {
                        //   // Handle unknown slug (optional)
                        // }
      
                      }
                  ),
                ],
              ),
            ),
      
      
          _buildGap(),
      
          /// Home made food, product, service
          CustomFormCard(
              color: AppColors.pinkDE,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Home Made Product, Food & Services'),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGrid(
                      items: homeMadeItemsCategories,
                      icon: (item)=> item.icon,
                      name: (item)=> item.name,
                      onTap: (item) {
                        if(item.slugId == SERVICE) {
                          Get.to(()=> HomeServiceScreen());
                        }else if(item.slugId == FOOD){
                          Get.to(()=> HomeMadeFoodScreen());
                        }else if(item.slugId == PRODUCT){
                          Get.to(()=> HomeMadeProductScreen());
                        }
                      }
                  )
                ],
              ),
            ),
      
      
          _buildGap(),
      
          /// Consultation Service
         CustomFormCard(
              color: AppColors.greenDB,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title('Professionals Consultant'),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      _viewAll(
                            () => Get.to(()=> AllProfessionConsultantScreen(
                          professionalConsultantCategories: individualOnboardingConsultationList,
                        )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGrid(
                      items: individualOnboardingConsultationList.take(6).toList(),
                      icon: (item)=> item.icon,
                      name: (item)=> item.name,
                      onTap: (c){
                        Get.to(()=> AllProfessionConsultantScreen(
                            professionalConsultantCategories: individualOnboardingConsultationList,
                            selectedProfessionConsultantData: c
                        )
                        );
                      }
                  )
                ],
              ),
            ),
      
          _buildGap(),
      
          /// Transport
          InkWell(
              onTap: (){
                Get.to(BookTransportMain());

              },
              child: CustomFormCard(
                color: AppColors.rating.withValues(alpha: 0.1),
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
      
                    _title('Book Your Transport'),
      
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _title('Book Your Transport'),
                    //     ),
                    //     SizedBox(
                    //       width: SizeConfig.size8,
                    //     ),
                    //     _viewAll(),
                    //   ],
                    // ),
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
                                const Icon(
                                    Icons.home_outlined,
                                    color: AppColors.secondaryTextColor,
                                    size: 16),

                                // The Dotted Line
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: CustomPaint(
                                      size: const Size(1, double.infinity),
                                      painter: DottedLinePainter(),
                                    ),
                                  ),
                                ),

                                const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.redLite,
                                    size: 16),
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
                                      "${LocationService.userCurrentAddress.value.city}",
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.greyBf,
                                      fontWeight: FontWeight.w400),

                                  SizedBox(height: SizeConfig.paddingS),

                                  // Divider
                                  CommonHorizontalDivider(
                                      height: 1,
                                      color: AppColors.greyBf
                                  ),

                                  SizedBox(height: SizeConfig.paddingS),

                                  // To
                                  CustomText(
                                      "To",
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
                                boxShadow: [
                                  AppShadows.textFieldShadow
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                    Icons.swap_vert,
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
                        getName: (item)=> item.name,
                        getIcon: (item)=> item.icon,
                        onTap: (_){
                          Get.to(BookTransportMain());
                        }
                    ),
                  ],
                ),
              ),
            ),
      
      
          _buildGap(),
      
          /// Service
          CustomFormCard(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title('Find Services'),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      InkWell(
                        onTap: () => Get.to(() => ServicesNearMeScreen(
                          businessServicesCategories: businessServicesCategories,
                        )),
                        child: _viewAll(),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGrid(
                      items: businessOnboardingServicesCategories.take(6).toList(),
                      icon: (item)=> item.icon,
                      name: (item)=> item.name,
                      onTap: (_){
                        Get.to(() => ServicesNearMeScreen(
                          businessServicesCategories: businessServicesCategories,
                        ));
                      }
                  )
                ],
              ),
            ),
      
      
          _buildGap(),
      
          /// Automotive Service
          CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Automotive Services'),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGridWithIcons(
                      items: automotiveServiceItemsCategories,
                      crossAxisCount: 3,
                      getName: (item)=> item.name,
                      getIcon: (item)=> item.icon,
                      onTap: (_){}
                  ),
                ],
              ),
            ),
      
          _buildGap(),
      
          /// Food
          CustomFormCard(
              color: AppColors.yellowE7,
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _title('Restaurant Near By'),
                      ),
                      SizedBox(
                        width: SizeConfig.size8,
                      ),
                      InkWell(
                        onTap: () {},
                        // onTap: ()=> Get.to(()=> ServicesNearMeScreen(
                        //   businessServicesCategories: businessServicesCategories,
                        // )),
                        child: _viewAll(),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  _buildMasonryGrid(
                      items: businessOnboardingFoodsCategories.take(6).toList(),
                      icon: (item)=> item.icon,
                      name: (item)=> item.name,
                      onTap: (_){}
                  )
                ],
              ),
            ),
      
      
          _buildGap(),
      
          /// Near By Jobs
          InkWell(
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
                    _title('Find Your Dream Job - Near By'),
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
                            child: _buildHorizontalTabs([
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
      
          _buildGap(),
      
          searchProductsViaAiWidget(),
      
          SizedBox(
                height:
                kBottomNavigationBarHeight + SizeConfig.paddingXXXL),
      
        ],
      ),
    );
  }

  Widget _title(String title) {
    return CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600);
  }

  Widget _viewAll([VoidCallback? onTap]){
    return InkWell(
      onTap: onTap,
      child: CustomText(
          'View All',
          fontSize: SizeConfig.medium,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600
      ),
    );
  }

  Widget _buildGap({double? gap}) {
    return  SizedBox(height: gap ?? SizeConfig.paddingXSL);
  }

  // Widget _buildStoreAiAssistant() {
  //   return Obx(() => AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 300), // Animation speed
  //         reverseDuration: const Duration(milliseconds: 200),
  //         transitionBuilder: (Widget child, Animation<double> animation) {
  //           return ScaleTransition(scale: animation, child: child);
  //         },
  //         child: controller.isHeaderVisible.value
  //             ? Padding(
  //                 key: const ValueKey('ai_assistant_button'),
  //                 padding: EdgeInsets.only(
  //                     bottom: kBottomNavigationBarHeight + SizeConfig.size10),
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(SizeConfig.size35),
  //                   child: BackdropFilter(
  //                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10.0),
  //                     child: GradientFloatingButton(
  //                       height: SizeConfig.size70,
  //                       width: SizeConfig.size70,
  //                       borderRadius: SizeConfig.size35,
  //                       borderWidth: 1.0,
  //                       padding: const EdgeInsets.all(8.0),
  //                       boxShadow: [
  //                         BoxShadow(
  //                             color: AppColors.black.withValues(alpha: 0.30),
  //                             blurRadius: 4.0,
  //                             offset: const Offset(0, 2))
  //                       ],
  //                       backgroundGradientColors: const [
  //                         Color(0xFFFFFFFF),
  //                         Color(0xFFCCE0FF),
  //                       ],
  //                       borderGradientColors: const [
  //                         Color(0xFF004FCE),
  //                         Color(0xFF5C9BFF),
  //                       ],
  //                       onPressed: () {
  //                         final chat = ChatViewController
  //                             .inventoryAiChatListSearchModule;
  //
  //                         Get.to(() => AskInventoryChatScreen(
  //                               profileImage: chat?.sender?.profileImage,
  //                               name: chat?.sender?.name,
  //                               contactNo: chat?.sender?.contactNo,
  //                               conversationId: '',
  //                               userId: '',
  //                               businessId: '',
  //                               type: chat?.sender?.accountType,
  //                               isInitialMessage: false,
  //                             ));
  //                       },
  //                       child:
  //                           LocalAssets(imagePath: AppIconAssets.aiChatbotIcon),
  //                     ),
  //                   ),
  //                 ),
  //               )
  //             : const SizedBox.shrink(),
  //       ));
  // }

  // ---------------- REUSABLE BANNER WIDGET ---------------- //

  Widget _bannerWidget({required String bannerImage, required double bannerHeight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox( // Using SizedBox is more lightweight than Container
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

  // Widget _buildRiderImageWidget() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       border: Border.all(color: AppColors.greyE5, width: 1.5),
  //     ),
  //     child: CircleAvatar(
  //       radius: 15,
  //       backgroundImage: NetworkImage("https://picsum.photos/200"),
  //     ),
  //   );
  // }
  //
  // Widget _buildVerticalLayout({
  //   required String imageUrl,
  //   required List<IndividualProfileCategory> items,
  //   required Function(IndividualProfileCategory item) onTap,
  // }) {
  //   return Expanded(
  //     child: CustomFormCard(
  //       padding: EdgeInsets.all(SizeConfig.size10),
  //       child: Column(
  //         children: [
  //           ClipRRect(
  //             borderRadius: BorderRadius.circular(10.0),
  //             child: LocalAssets(
  //                 imagePath: imageUrl,
  //                 width: double.maxFinite,
  //                 height: SizeConfig.size190,
  //                 boxFix: BoxFit.fill),
  //           ),
  //           SizedBox(
  //             height: SizeConfig.size10,
  //           ),
  //           genericSquareRow<IndividualProfileCategory>(
  //             items: items,
  //             itemsPerRow: 3,
  //             labelBuilder: (c) => c.name,
  //             iconBuilder: (c) => c.icon,
  //             onTap: (c) => onTap(c),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

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

  Widget _buildMasonryGrid<T>({
    required List<T> items,
    required String Function(T) icon,
    required String Function(T) name,
    required Function(T) onTap,
  }) {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        return InkWell(
          onTap: () => onTap(item),
          child: _commonCard(
              icon: icon(item),
              text: name(item)
          ),
        );
      },
    );
  }

  Widget _commonCard({required String icon, required String text}) {
    return Container(
      height: SizeConfig.size140,
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5)),
      child: Stack(
        children: [
          // 1. Background Image
          Positioned.fill( // Use Positioned.fill to ensure it covers the card
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LocalAssets(
                imagePath: icon,
                boxFix: BoxFit.cover, // Ensures image fills without stretching
              ),
            ),
          ),

          // 2. Bottom Gradient Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: SizeConfig.size40, // Reduced height for better balance
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                  gradient: LinearGradient(
                      colors: [
                        AppColors.black.withValues(alpha: 0.0),
                        AppColors.black.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter
                  )),
            ),
          ),

          // 3. Text Label
          Positioned(
            left: 5.0,
            right: 5.0,
            bottom: 5.0,
            child: CustomText(
              text,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductMasonryGrid(){
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
        var categoryItem =
        businessProductsCategories[index];
        return CommonServiceCard(
          service: categoryItem,
          getName: (item) => item.name,
          getIcon: (item) => item.icon,
          iconHeight: SizeConfig.size80,
          onTap: (item) {
            Get.to(() => ProductLocalMarketScreen(
              businessProductsCategories: businessProductsCategories,
              businessProductStoreCategories: businessProductStoreCategories,
            ));
          },
        );
      },

    );
  }

  Widget _buildMasonryGridWithIcons<T>({
    required List<T> items,
    required Function(T) getName,
    required Function(T) getIcon,
    required Function(T) onTap,
    required int crossAxisCount
   }){
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
                      enabled: false,
                      autofocus: false,
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