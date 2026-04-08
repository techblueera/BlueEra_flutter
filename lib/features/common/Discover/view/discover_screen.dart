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
  final GlobalKey _qrWidgetKey = GlobalKey();
  late final EmergencyProfileController emergencyController;

  /// 0=Overview, 1=Bookings, 2=Professionals, 3=Shopping, 4=Services
  int _activeTabIndex = 0;

  /// Section list with the set of tab indices each section belongs to.
  /// Tab 0 (Overview) shows everything, so it's not listed explicitly.
  ///
  /// Widgets that have separate horizontal-list and grid layouts read
  /// [_isInGridMode] so they switch automatically when the user moves
  /// between Overview and a filter tab.
  bool get _isInGridMode => _activeTabIndex != 0;

  List<({Widget widget, Set<int> tabs})> get _sections {
    final inGrid = _isInGridMode;
    return [
      (widget: GroceryCardWidget(), tabs: {3}),
      (widget: TransportServiceWidget(), tabs: {1}),
      (widget: BookHomeServiceWidget(), tabs: {2}),
      (widget: HealthServiceCardWidget(), tabs: {4}),
      (widget: ProfessionalsCardWidget(), tabs: {2}),
      (widget: ShoppingCardWidget(), tabs: {3}),
      (widget: HomeMadeProductWidget(), tabs: {3}),
      (widget: FindServiceCardWidget(), tabs: {4}),
      (widget: ResponsiveRentalCard(), tabs: {4}),
      (widget: HotelStayServiceCard(isShowInGrid: inGrid), tabs: {1}),
      (widget: AutomotiveServiceCardWidget(), tabs: {4}),
      (widget: FinancialSectors(isShowInGrid: inGrid), tabs: {4}),
      (widget: EducationServiceCardWidget(), tabs: {4}),
      (widget: JobServiceCardWidget(), tabs: {2}),
    ];
  }

  List<Widget> _buildSectionSlivers() {
    final visible = _sections
        .where((s) => _activeTabIndex == 0 || s.tabs.contains(_activeTabIndex))
        .toList();
    final result = <Widget>[];
    for (final s in visible) {
      result.add(_sliverCard(child: s.widget));
      result.add(_sliverGap());
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    userLat = LocationService.lat;
    userLng = LocationService.lng;

    // Register controllers here not in build
    emergencyController = getOrPut(() => EmergencyProfileController());

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Banner is dark and the sticky header bg is dark too, so keep
      // status bar icons light (white) throughout this screen.
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.appBackgroundColor,
          body: SafeArea(
            top: false,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if(notification.metrics.axis == Axis.vertical){
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

                  /// Search Bar + Tabs - sticky on scroll.
                  /// Search bar collapses away on scroll, tabs stay pinned.
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySearchBarDelegate(
                      topPadding: MediaQuery.of(context).padding.top,
                      activeIndex: _activeTabIndex,
                      onTabSelected: (i) {
                        if (i == _activeTabIndex) return;
                        setState(() => _activeTabIndex = i);
                      },
                    ),
                  ),

                  /// Sections filtered by the currently selected tab.
                  ..._buildSectionSlivers(),

                  /// Emergency QR + sticker options - only on Overview tab.
                  if (_activeTabIndex == 0) ...[
                    SliverToBoxAdapter(
                      child: Builder(
                        key: _qrWidgetKey,
                        builder: (_) {
                          return EmergencyQrWidget(key: ValueKey('emergency_qr'));
                        },
                      ),
                    ),
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
                  ] else
                    SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
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

  Widget _sliverCard({required Widget child}) {
    return SliverToBoxAdapter(
      child: Container(
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
        border: Border.all(
            color: AppColors.secondaryTextColor,
            width: 0.1),
        borderRadius: BorderRadius.circular(8)),
    child: CustomText(
        title,
        fontSize: SizeConfig.large18,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600),
  );
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  _StickySearchBarDelegate({
    required this.topPadding,
    required this.activeIndex,
    required this.onTabSelected,
  });

  // Fixed inner heights so min/maxExtent stay consistent with the layout.
  static const double _searchBarHeight = 52;
  static const double _searchTabsGap = 16;
  static const double _tabsHeight = 72;
  static const double _vTop = 10;
  static const double _vBottom = 10;

  // The chunk that collapses on scroll: search bar + the 16px gap below it.
  static const double _collapsibleHeight = _searchBarHeight + _searchTabsGap;

  // Non-sticky: no statusbar padding above search (sits flush below banner).
  // Sticky: statusbar padding above tabs so they clear the system status bar.
  @override
  double get maxExtent => _vTop + _collapsibleHeight + _tabsHeight + _vBottom;

  @override
  double get minExtent => topPadding + _vTop + _tabsHeight + _vBottom;

  List<Map<String, String>> get _sectionData => [
    {'title': AppStrings.overview.tr, 'icon': AppImageAssets.overviewDiscover},
    {'title': AppStrings.bookings.tr, 'icon': AppImageAssets.bookingDiscover},
    {'title': AppStrings.professionals.tr, 'icon': AppImageAssets.professionalDiscover},
    {'title': AppStrings.shopping.tr, 'icon': AppImageAssets.shoppingDiscover},
    {'title': AppStrings.services.tr, 'icon': AppImageAssets.servicesDiscover},
  ];

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseRange = maxExtent - minExtent; // _collapsibleHeight - topPadding
    final t = collapseRange <= 0
        ? 1.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final currentCollapsibleHeight = (1 - t) * _collapsibleHeight;
    final currentTopPad = _vTop + t * topPadding;
    final searchOpacity = (1 - t * 1.4).clamp(0.0, 1.0);
    final isSticky = t >= 0.999;

    return Container(
      color: isSticky ? const Color(0xFF1E2124) : Colors.transparent,
      padding: EdgeInsets.only(
        top: currentTopPad,
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        bottom: _vBottom,
      ),
      child: Column(
        children: [
          // Collapsing search bar + 16px gap below it.
          SizedBox(
            height: currentCollapsibleHeight,
            child: ClipRect(
              child: OverflowBox(
                minHeight: _collapsibleHeight,
                maxHeight: _collapsibleHeight,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: searchOpacity,
                  child: IgnorePointer(
                    ignoring: searchOpacity < 0.05,
                    child: Column(
                      children: [
                        SizedBox(
                          height: _searchBarHeight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(
                                  width: 1, color: AppColors.greyE5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: AppColors.secondaryTextColor,
                                    size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomText(
                                    AppStrings.searchAnything,
                                    fontSize: 16,
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
                                LocalAssets(
                                    imagePath: AppIconAssets.camera_black),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: _searchTabsGap),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tabs - always visible, distributed evenly across width.
          SizedBox(
            height: _tabsHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_sectionData.length, (index) {
                final isActive = activeIndex == index;
                final item = _sectionData[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
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
                              colors: [
                                AppColors.white,
                                Color(0xFFA4D4FF)
                              ],
                            )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primaryColor
                                  : AppColors.greyE5,
                            ),
                          ),
                          child: LocalAssets(
                            imagePath: item['icon']!,
                            width: 30,
                            height: 30,
                            boxFix: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: CustomText(
                            item['title']!,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            color: isSticky
                                ? AppColors.white
                                : AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding ||
          activeIndex != oldDelegate.activeIndex ||
          onTabSelected != oldDelegate.onTabSelected;
}
