import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/discover_banner_slider.dart';
import 'package:BlueEra/features/common/Discover/view/widget/automotive_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_home_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/education_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/financial_sectors.dart';
import 'package:BlueEra/features/common/Discover/view/widget/find_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/grocery_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/job_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/professionals_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/shopping_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/transport_service_widget.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_widget.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import '../../bottomNavigationBar/controller/bottom_bar_controller.dart';

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

class _DiscoverScreenState extends State<DiscoverScreen> {
  final controller = getOrPut(() => DiscoverController());

  late final double userLat;
  late final double userLng;
  final bottomBarController = getOrPut(() => BottomBarController());

  final ScrollController _scrollController = ScrollController();
  final ScrollController _tabScrollController = ScrollController();
  final ScrollController _horizontalTabScrollController = ScrollController();
  final GlobalKey _qrWidgetKey = GlobalKey();
  late final EmergencyProfileController emergencyController;

  // Section keys for scroll-to and active tab tracking
  final List<GlobalKey> _sectionKeys = List.generate(14, (_) => GlobalKey());
  final GlobalKey _horizontalTabKey = GlobalKey();
  final ValueNotifier<int> _activeTabIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> _showStickyTabs = ValueNotifier<bool>(false);
  bool _isTabTapScrolling = false;

  List<Map<String, String>> get _sectionData => [
        {'title': AppStrings.groceryAndFood.tr, 'icon': AppImageAssets.groceryItemsDiscover},
        {'title': AppStrings.transport.tr, 'icon': AppImageAssets.transportVehicle},
        {'title': AppStrings.healthcare.tr, 'icon': AppImageAssets.pharmacyMedicalStore},
        {'title': AppStrings.shopping.tr, 'icon': AppImageAssets.fashionLifestyle},
        {'title': AppStrings.homeServices.tr, 'icon': AppImageAssets.homeService},
        {'title': AppStrings.homeMade.tr, 'icon': AppImageAssets.homeMadeFood},
        {'title': AppStrings.stay.tr, 'icon': AppImageAssets.hotelAndHomeStay},
        {'title': AppStrings.consultation.tr, 'icon': AppImageAssets.bookProfessional},
        {'title': AppStrings.rental.tr, 'icon': AppImageAssets.rentalService},
        {'title': AppStrings.services.tr, 'icon': AppImageAssets.findServiceNearMe},
        {'title': AppStrings.financial.tr, 'icon': AppImageAssets.financial},
        {'title': AppStrings.automotive.tr, 'icon': AppImageAssets.automotiveStore},
        {'title': AppStrings.education.tr, 'icon': AppImageAssets.education},
        {'title': AppStrings.jobs.tr, 'icon': AppImageAssets.jobBanner},
      ];

  @override
  void initState() {
    super.initState();
    userLat = LocationService.lat;
    userLng = LocationService.lng;
    emergencyController = getOrPut(() => EmergencyProfileController());
    _scrollController.addListener(_onScroll);
    _showStickyTabs.addListener(_onStickyChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _showStickyTabs.removeListener(_onStickyChanged);
    _scrollController.dispose();
    _tabScrollController.dispose();
    _horizontalTabScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if horizontal tabs scrolled off screen
    final tabCtx = _horizontalTabKey.currentContext;
    if (tabCtx != null) {
      final box = tabCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        _showStickyTabs.value = (pos.dy + box.size.height) < 0;
      }
    }

    if (_isTabTapScrolling) return;

    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy <= 200) {
            if (_activeTabIndex.value != i) {
              _activeTabIndex.value = i;
              _scrollTabIntoView(i);
            }
            return;
          }
        }
      }
    }
  }

  void _onStickyChanged() {
    // When switching between sticky/non-sticky, jump the newly visible tab bar to the active tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTabIntoView(_activeTabIndex.value);
    });
  }

  void _scrollTabIntoView(int index) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_showStickyTabs.value) {
      // Scroll sticky vertical tabs to center
      if (_tabScrollController.hasClients) {
        const stickyTabWidth = 80.0;
        final stickyOffset = (index * stickyTabWidth) - (screenWidth / 2) + (stickyTabWidth / 2);
        _tabScrollController.animateTo(
          stickyOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      // Scroll horizontal chip tabs to center
      if (_horizontalTabScrollController.hasClients) {
        const chipTabWidth = 130.0;
        final chipOffset = (index * chipTabWidth) - (screenWidth / 2) + (chipTabWidth / 2);
        _horizontalTabScrollController.animateTo(
          chipOffset.clamp(0.0, _horizontalTabScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _scrollToSection(int index) async {
    final key = _sectionKeys[index];
    final ctx = key.currentContext;
    if (ctx == null) return;

    _isTabTapScrolling = true;
    _activeTabIndex.value = index;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );

    _isTabTapScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          bottomBarController.onChangeIndex(0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                if (notification.direction == ScrollDirection.reverse) {
                  widget.onHeaderVisibilityChanged?.call(false);
                } else if (notification.direction == ScrollDirection.forward) {
                  widget.onHeaderVisibilityChanged?.call(true);
                }
              }
              return true;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                /// Banner covering full top: status bar + notch + icons overlay
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      /// Banner image — full width, covers status bar & notch
                      DiscoverBannerSlider(
                        parentScrollController: _scrollController,
                        targetKey: _qrWidgetKey,
                      ),

                      /// Overlay: location + cart on top of banner
                      Positioned(
                        top: statusBarHeight,
                        left: SizeConfig.size12,
                        right: SizeConfig.size12,
                        child: Row(
                          children: [
                            /// Location with rounded bg
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: AppColors.white, size: 20),
                                    SizedBox(width: SizeConfig.size6),
                                    Flexible(
                                      child: CustomText(
                                        [
                                          LocationService.userCurrentAddress.value
                                              .subLocality,
                                          LocationService
                                              .userCurrentAddress.value.city,
                                        ].where((e) => e.isNotEmpty).join(', '),
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w700,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down,
                                        color: AppColors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: SizeConfig.size8),

                            /// Cart with rounded bg
                            _appBarAction(
                              icon: AppIconAssets.cartIcon,
                              onTap: () => Navigator.pushNamed(
                                  context, RouteHelper.getYourCartScreenRoute()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Search Bar - scrolls away
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.white,
                    padding: EdgeInsets.only(
                      left: SizeConfig.size16,
                      right: SizeConfig.size16,
                      top: SizeConfig.size16,
                      bottom: 0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(width: 1, color: AppColors.greyE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.secondaryTextColor, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomText(
                              AppStrings.searchAnything.tr,
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          LocalAssets(
                            imagePath: AppIconAssets.mic,
                            width: 20,
                            height: 20,
                            imgColor: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(width: 12),
                          LocalAssets(imagePath: AppIconAssets.camera_black),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Horizontal tabs - scrolls with content
                SliverToBoxAdapter(
                  child: Container(
                    key: _horizontalTabKey,
                    child: _buildHorizontalTabs(),
                  ),
                ),

                _sliverGap(SizeConfig.size8),

                /// Grocery & Food
                _sliverCard(sectionKey: _sectionKeys[0], child: GroceryCardWidget()),
                _sliverGap(),

                /// Transport
                _sliverCard(sectionKey: _sectionKeys[1], child: TransportServiceWidget()),
                _sliverGap(),

                /// Medical / Healthcare Services
                _sliverCard(sectionKey: _sectionKeys[2], child: HealthServiceCardWidget()),
                _sliverGap(),

                /// Shopping
                _sliverCard(sectionKey: _sectionKeys[3], child: ShoppingCardWidget()),
                _sliverGap(),

                /// Home Services
                _sliverCard(sectionKey: _sectionKeys[4], child: BookHomeServiceWidget()),
                _sliverGap(),

                /// Home made food, product, service
                _sliverCard(sectionKey: _sectionKeys[5], child: HomeMadeProductWidget()),
                _sliverGap(),

                /// Stay Service
                _sliverCard(sectionKey: _sectionKeys[6], child: HotelStayServiceCard()),
                _sliverGap(),

                /// Consultation Service
                _sliverCard(sectionKey: _sectionKeys[7], child: ProfessionalsCardWidget()),
                _sliverGap(),

                /// Rental Service
                _sliverCard(sectionKey: _sectionKeys[8], child: ResponsiveRentalCard()),
                _sliverGap(),

                /// Services
                _sliverCard(sectionKey: _sectionKeys[9], child: FindServiceCardWidget()),
                _sliverGap(),

                /// Financial Sectors
                _sliverCard(sectionKey: _sectionKeys[10], child: FinancialSectors()),
                _sliverGap(),

                /// Automotive Service
                _sliverCard(sectionKey: _sectionKeys[11], child: AutomotiveServiceCardWidget()),
                _sliverGap(),

                /// Education Service
                _sliverCard(sectionKey: _sectionKeys[12], child: EducationServiceCardWidget()),
                _sliverGap(),

                /// Job Service
                _sliverCard(sectionKey: _sectionKeys[13], child: JobServiceCardWidget()),
                _sliverGap(),

              /// Emergency QR
              SliverToBoxAdapter(
                child: Builder(
                  key: _qrWidgetKey,
                  builder: (_) {
                    return EmergencyQrWidget(key: ValueKey('emergency_qr'));
                  },
                ),
              ),

              /// QR Sticker Design Options (visible when QR is generated)
              SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
                sliver: SliverToBoxAdapter(
                  child: Obx(() {
                    if (!emergencyController.hasEmergencyData.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(height: SizeConfig.size8),
                        QrDesignOptionsWidget(
                          userName: emergencyController.fullName.value,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
                ),
        ),

            // Sticky vertical tabs overlay — slides down/up
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showStickyTabs,
                builder: (context, show, _) {
                  return IgnorePointer(
                    ignoring: !show,
                    child: AnimatedSlide(
                      offset: show ? Offset.zero : const Offset(0, -1),
                      duration: Duration(milliseconds: show ? 400 : 250),
                      curve: show ? Curves.easeOutBack : Curves.easeInCubic,
                      child: AnimatedOpacity(
                        opacity: show ? 1.0 : 0.0,
                        duration: Duration(milliseconds: show ? 300 : 150),
                        child: _buildStickyVerticalTabs(statusBarHeight),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
            ));
  }

  Widget _appBarAction({required String icon, required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: LocalAssets(imagePath: icon, imgColor: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildHorizontalTabs() {
    return Container(
      color: AppColors.white,
      height: 56,
      child: ValueListenableBuilder<int>(
        valueListenable: _activeTabIndex,
        builder: (context, activeIndex, _) => ListView.builder(
          controller: _horizontalTabScrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size10,
          ),
          itemCount: _sectionData.length,
          itemBuilder: (context, index) {
            final isActive = activeIndex == index;
            final item = _sectionData[index];
            return GestureDetector(
              onTap: () => _scrollToSection(index),
              child: Container(
                margin: EdgeInsets.only(right: SizeConfig.size8),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryColor : AppColors.whiteF1,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive ? AppColors.primaryColor : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalAssets(
                      imagePath: item['icon']!,
                      width: 30,
                      height: 30,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      item['title']!,
                      fontSize: SizeConfig.small,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppColors.white : AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStickyVerticalTabs(double statusBarHeight) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: const Color(0xFF1E2124),
        padding: EdgeInsets.only(top: statusBarHeight),
        height: statusBarHeight + 110,
        child: ValueListenableBuilder<int>(
          valueListenable: _activeTabIndex,
          builder: (context, activeIndex, _) => ListView.builder(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              left: SizeConfig.size12,
              right: SizeConfig.size12,
              top: SizeConfig.size15,
              bottom: SizeConfig.size10,
            ),
            itemCount: _sectionData.length,
            itemBuilder: (context, index) {
              final isActive = activeIndex == index;
              final item = _sectionData[index];
              return GestureDetector(
                onTap: () => _scrollToSection(index),
                child: Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isActive ? null : AppColors.white,
                          gradient: isActive
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.white, Color(0xFFA4D4FF)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? AppColors.primaryColor : AppColors.greyE5,
                          ),
                        ),
                        child: LocalAssets(
                          imagePath: item['icon']!,
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        item['title']!,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sliverCard({required Widget child, GlobalKey? sectionKey}) {
    return SliverToBoxAdapter(
      child: Container(
        key: sectionKey,
        decoration: BoxDecoration(
          color: AppColors.white,
        ),
        child: child,
      ),
    );
  }

  Widget _sliverGap([double? gap]) {
    return SliverToBoxAdapter(
      child: SizedBox(height: gap ?? SizeConfig.size8),
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

Widget titleWidget(String title) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryTextColor, width: 0.1),borderRadius: BorderRadius.circular(8)),
    child: CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600),
  );
}

