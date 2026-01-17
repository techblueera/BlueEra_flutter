import 'dart:developer';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/ask_inventory_chat_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/all_rental_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/product_local_market_screen.dart';
import 'package:BlueEra/features/common/Discover/view/all_self_profession_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/store/view/new_store/all_product_store_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/gradient_floating_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:BlueEra/widgets/update_live_photo_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible)? onHeaderVisibilityChanged;

  const DiscoverScreen({
    super.key,
    required this.isHeaderVisible,
    this.onHeaderVisibilityChanged});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final DiscoverController controller = Get.put(DiscoverController());

  @override
  void initState() {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: _buildStoreAiAssistant(),
        body: Obx(()=> setupScrollVisibilityNotification(
            controller: controller.scrollController,
            onVisibilityChanged: (visible, offset) {
              final currentOffset = controller.headerOffset.value;
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
                /// Discover Main Body
                _buildMainBody(),

                /// Header stays same
                _buildFloatingHeader(),
              ],
            )
          ))
      ),
    );
  }

  Widget _buildFloatingHeader(){
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      top: -controller.headerOffset.value *
          controller.headerHeight,
      left: 0,
      right: 0,
      child: KeyedSubtree(
        key: controller.headerKey,
        child: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size20,
                top: SizeConfig.size10,
                bottom: SizeConfig.size10),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    LocalAssets(
                      imagePath:
                      AppIconAssets.currentLocationIcon,
                      height: SizeConfig.size24,
                      width: SizeConfig.size24,
                    ),
                    SizedBox(width: SizeConfig.size10),
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
                  ]),
                ),
                SizedBox(width: SizeConfig.size8),
                InkWell(
                  onTap: () {
                    if (isBusinessUser()) {
                      final controller = getOrPut(() => ViewBusinessDetailsController());

                      if ((controller.businessProfileDetails?.data
                          ?.livePhotos ??
                          [])
                          .length <
                          3) {
                        showLivePhotoDialog(
                          context: context,
                        );
                      } else {
                        Get.toNamed(RouteHelper.getInventoryScreenRoute());
                      }
                    } else {
                      final controller = getOrPut(() => ViewPersonalDetailsController());

                      if (controller.personalProfileDetails.value
                          .isProfileCreated ==
                          false) {
                        Get.to(() => CreateProfileScreen());
                      } else {
                        if(userWorkTypeGlobal == DELIVERY_RIDER){
                          Get.toNamed(RouteHelper
                              .getRiderServiceScreenRoute());
                        }else{
                          Get.toNamed(RouteHelper
                              .getEarnServiceScreenRoute());
                        }
                      }
                    }
                  },
                  child: LocalAssets(
                    imagePath: AppIconAssets.cartIcon,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBody(){
    return AnimatedPadding(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(
          top: controller.headerHeight *
              (1 - controller.headerOffset.value)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
        ),
        child: CustomScrollView(
          controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            /// Job
            SliverToBoxAdapter(
              child: InkWell(
                onTap: () {
                  Widget dest = isGuestUser()
                      ? GuestDashBoardScreen()
                      : JobsScreen();

                  Get.to(() => dest);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 1.2),
                      boxShadow: [AppShadows.textFieldShadow]),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.searchJobIcon,
                        height: SizeConfig.size30,
                        width: SizeConfig.size30,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomText(AppStrings.findYourDreamJobNow,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400),
                    ],
                  ),
                ),
              ),
            ),

            _buildGap(),

            /// Rider
            SliverToBoxAdapter(
              child: CustomFormCard(
                  padding: EdgeInsets.all(
                      SizeConfig.size10
                  ),
                  child: InkWell(
                    onTap: ()=> Get.toNamed(RouteHelper.getRiderStoreScreenRoute()),
                    child: Column(
                      children: [
                        _bannerWidget(
                            bannerImage: AppImageAssets.riderStoreBanner,
                            bannerHeight: SizeConfig.size180
                        ),
              
                        SizedBox(height: SizeConfig.paddingXSL),
              
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: CustomText(
                                  AppStrings.bookYourGroceryNdFood,
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w600),
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
              
              
                            Stack(
                              clipBehavior: Clip.none,
                              children: List.generate(3, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(left: index * 15.0),
                                  child: _buildRiderImageWidget(),
                                );
                              }),
                            )
                          ],
                        )
                      ],
                    ),
                  )
              ),
            ),

            _buildGap(),

            /// Product
            SliverToBoxAdapter(
              child: CustomFormCard(
                  padding: EdgeInsets.all(
                      SizeConfig.size10
                  ),
                  child: Column(
                    children: [
                      _bannerWidget(
                          bannerImage: AppImageAssets.localMarketProducts,
                          bannerHeight: SizeConfig.size180
                      ),

                      SizedBox(height: SizeConfig.paddingXSL),

                      genericSquareRow<BusinessProfileCategory>(
                        items: businessProductsCategories,
                        itemsPerRow: 5,
                        labelBuilder: (c) => c.name,
                        iconBuilder: (c) => c.icon,
                        onTap: (c) {
                          Get.to(()=> ProductLocalMarketScreen(
                            businessProductsCategories: businessProductsCategories,
                          ));
                        },
                      )
                    ],
                  )
              ),
            ),

           _buildGap(),

            /// Self work
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    final double fixedBannerHeight = SizeConfig.size160;
                    final double gap = SizeConfig.paddingXSL;
                    final double sideBoxSize = (fixedBannerHeight - gap) / 2;
                    final double bannerWidth = totalWidth - sideBoxSize - gap;

                    final List<IndividualProfileCategory> sideBoxItems = selfWorkCategories.sublist(0, 2);
                    final List<IndividualProfileCategory> bottomRowItems = selfWorkCategories.sublist(2, 7);

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: bannerWidth,
                              height: fixedBannerHeight,
                              child: _bannerWidget(
                                bannerImage: AppImageAssets.bookProfessional,
                                bannerHeight: fixedBannerHeight,
                              ),
                            ),

                            SizedBox(width: gap),

                            SizedBox(
                              width: sideBoxSize,
                              height: fixedBannerHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildContainer(
                                      size: sideBoxSize,
                                      text: sideBoxItems[0].name,
                                      icon: sideBoxItems[0].icon,
                                      onTap: () {
                                        Get.to(()=> AllSelfProfessionScreen(
                                            selfEmployedCategories: selfWorkCategories, // Pass full list for context
                                            selectedSelfProfessionData: sideBoxItems[0]
                                        ));
                                      }
                                  ),
                                  _buildContainer(
                                      size: sideBoxSize,
                                      text: sideBoxItems[1].name,
                                      icon: sideBoxItems[1].icon,
                                      onTap: () {
                                        Get.to(()=> AllSelfProfessionScreen(
                                            selfEmployedCategories: selfWorkCategories,
                                            selectedSelfProfessionData: sideBoxItems[1]
                                        ));
                                      }
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: SizeConfig.paddingXSL),

                        // Bottom Section
                        genericSquareRow<IndividualProfileCategory>(
                          items: bottomRowItems,
                          itemsPerRow: 5,
                          labelBuilder: (s) => s.name,
                          iconBuilder: (s) => s.icon,
                          onTap: (s) {
                            Get.to(()=> AllSelfProfessionScreen(
                              selfEmployedCategories: selfWorkCategories,
                              selectedSelfProfessionData: s
                            ));
                          },
                        )
                      ],
                    );
                  },
                ),
              ),
            ),

           _buildGap(),

            SliverToBoxAdapter(
              child: Row(
                children: [
                  _buildVerticalLayout(
                      imageUrl: AppImageAssets.bookNowBanner,
                      items: rentalServiceCategories,
                      onTap: (c) {
                        final typeMap = {
                          Flat_ROOM: RentalServiceType.flatRoom,
                          HOME_STAY: RentalServiceType.homeStay,
                          VEHICLE:   RentalServiceType.vehicle,
                        };

                        final type = typeMap[c.slugId];

                        if (type != null) {
                          Get.to(() => AllRentalServiceScreen(type: type));
                        } else {
                          // Handle unknown slug (optional)
                        }
                      }
                  ),
                  SizedBox(width: SizeConfig.paddingXSL),
                  _buildVerticalLayout(
                      imageUrl: AppImageAssets.homeMadeBanner,
                      items: homeServiceCategories,
                    onTap:(c){
                      if(c.slugId == SERVICE) {
                        Get.to(()=> HomeServiceScreen());
                      }else if(c.slugId == FOOD){
                        Get.to(()=> HomeMadeFoodScreen());
                      }else if(c.slugId == PRODUCT){
                        Get.to(() => AllProductScreen(
                            isShowInGrid: true,
                            providerType: ProviderType.user,
                        ));
                      }else{
                        log('No category');
                      }
                    }
                  ),
                ],
              ),
            ),

            _buildGap(),

            /// Service
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  children: [
                    _bannerWidget(
                        bannerImage: AppImageAssets.findServiceNearMe,
                        bannerHeight: SizeConfig.size180
                    ),


                    SizedBox(height: SizeConfig.paddingXSL),

                    // Bottom Section
                    genericSquareRow<BusinessProfileCategory>(
                      items: businessServicesCategories,
                      itemsPerRow: 5,
                      labelBuilder: (c) => c.name,
                      iconBuilder: (c) => c.icon,
                      onTap: (c) {
                        Get.to(()=> ServicesNearMeScreen(
                          businessServicesCategories: businessServicesCategories,
                        ));
                      },
                    )
                  ],
                ),
              ),
            ),

            _buildGap(),

            /// Medical
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  children: [

                    _bannerWidget(
                        bannerImage: AppImageAssets.medicalHealthService,
                        bannerHeight: SizeConfig.size180
                    ),

                    SizedBox(height: SizeConfig.paddingXSL),

                    // Bottom Section
                    genericSquareRow<String>(
                      items: ["Hospital", "Pharmacy", "Lab Test", "Clinic", "Doctors"],
                      itemsPerRow: 5,
                      labelBuilder: (c) => c,
                      iconBuilder: (c) => AppIconAssets.electricianIcon,
                      onTap: (c) {

                      },
                    )
                  ],
                ),
              ),
            ),

            _buildGap(),

            /// Food
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  children: [

                    _bannerWidget(
                        bannerImage: AppImageAssets.foodDeliveryService,
                        bannerHeight: SizeConfig.size180
                    ),

                    SizedBox(height: SizeConfig.paddingXSL),

                    // Bottom Section
                    genericSquareRow<BusinessProfileCategory>(
                      items: businessFoodsCategories,
                      itemsPerRow: 5,
                      labelBuilder: (c) => c.name,
                      iconBuilder: (c) => c.icon,
                      onTap: (c) {


                      },
                    )
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                  height: kBottomNavigationBarHeight + SizeConfig.paddingXXXL
              ),
            ),

          ]
        ),
      ),
    );
  }

  Widget _buildGap(){
    return  SliverToBoxAdapter(
      child: SizedBox(height: SizeConfig.paddingXSL),
    );
  }

  Widget _buildStoreAiAssistant() {
    return Obx(() => AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // Animation speed
      reverseDuration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: controller.isHeaderVisible.value
          ? Padding(
        key: const ValueKey('ai_assistant_button'),
        padding: EdgeInsets.only(
            bottom: kBottomNavigationBarHeight + SizeConfig.size10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SizeConfig.size35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10.0),
            child: GradientFloatingButton(
              height: SizeConfig.size70,
              width: SizeConfig.size70,
              borderRadius: SizeConfig.size35,
              borderWidth: 1.0,
              padding: const EdgeInsets.all(8.0),
              boxShadow: [
                BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.30),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2))
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
                final chat =
                    ChatViewController.inventoryAiChatListSearchModule;

                Get.to(() => AskInventoryChatScreen(
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
              child: LocalAssets(imagePath: AppIconAssets.aiChatbotIcon),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    ));
  }

  // ---------------- REUSABLE BANNER WIDGET ---------------- //
  Widget _bannerWidget({required String bannerImage, required double bannerHeight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: bannerHeight,
        width: SizeConfig.screenWidth,
        child: LocalAssets(
          imagePath: bannerImage,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRiderImageWidget() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greyE5, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 15,
        backgroundImage: NetworkImage("https://picsum.photos/200"),
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
        final double itemSize = (constraints.maxWidth - totalSpacing) / itemsPerRow;

        return SizedBox(
          height: itemSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: items.asMap().entries.map((entry) {
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
            }).take(itemsPerRow).toList(),
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
  }){
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: size,  // Calculated Width
        height: size, // Same as Width = Square
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
              color: AppColors.greyE5,
              width: 0.5
          ),
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

  Widget _buildVerticalLayout({
    required String imageUrl,
    required List<IndividualProfileCategory> items,
    required Function(IndividualProfileCategory item) onTap,
  }) {
    return Expanded(
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LocalAssets(
                imagePath: imageUrl,
                width: double.maxFinite,
                height: SizeConfig.size190,
                boxFix: BoxFit.fill
              ),
            ),

            SizedBox(
              height: SizeConfig.size10,
            ),

            genericSquareRow<IndividualProfileCategory>(
              items: items,
              itemsPerRow: 3,
              labelBuilder: (c) => c.name,
              iconBuilder: (c) => c.icon,
              onTap: (c)=> onTap(c),
            )
          ],
        ),
      ),
    );
  }


}
