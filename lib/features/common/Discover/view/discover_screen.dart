import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/recently_visited_stores_section.dart';
import 'package:BlueEra/features/common/Discover/view/widget/automotive_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_home_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/education_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/financial_sectors.dart';
import 'package:BlueEra/features/common/Discover/view/widget/find_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/grocery_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/job_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/professionals_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/shopping_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/transport_service_widget.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_widget.dart';
import 'package:BlueEra/features/me/food/view/customer/restaurant_near_me_screen.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final controller = getOrPut(() => DiscoverController());

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _riderWidgetKey = GlobalKey();
  late final EmergencyProfileController emergencyController;

  /// Active quick-access tab — see [discoverQuickAccessTabs]:
  /// 0=Quick Access, 1=Grocery & Food, 2=Travel & Booking,
  /// 3=Shopping & Sell, 4=Services & Professional, 5=Jobs & Other.
  ///
  /// Tab 0 (Quick Access) is the overview and shows every section; the rest
  /// filter down to the sections tagged with their index in [_sections].
  int _activeTabIndex = 0;

  /// Discover sections fetch against the user's lat/lng, so we hold the
  /// content behind the shimmer until the location attempt resolves —
  /// otherwise on first launch they'd fire with 0,0. Flips true once coords
  /// are available OR the fetch attempt finishes (even on denial), so we
  /// never block forever.
  bool _locationResolved = false;

  /// Widgets that ship separate horizontal-list and grid layouts read this so
  /// they switch automatically when the user moves off the overview tab.
  bool get _isInGridMode => _activeTabIndex != 0;

  /// Every Discover section with the set of tab indices it belongs to.
  /// Tab 0 (Quick Access / overview) shows everything, so it's not listed.
  ///
  /// The first three entries are the redesigned circular Grocery / Food
  /// blocks and the Recently Visited Stores carousel; the remainder are the
  /// original service sections, preserved so no functionality is lost.
  List<({Widget widget, Set<int> tabs})> get _sections {
    final inGrid = _isInGridMode;
    return [
      // --- Redesigned landing sections ---
      (
        widget: DiscoverCategorySection(
          title: AppStrings.grocery.tr,
          items: discoverGroceryCategories,
          columns: 5,
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
          onItemTap: (_) =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {1}
      ),
      (
        widget: DiscoverCategorySection(
          title: AppStrings.food.tr,
          items: discoverFoodCategories,
          columns: 5,
          onItemTap: (_) => Get.to(() => const RestaurantNearMeScreen()),
        ),
        tabs: {1}
      ),
      (
        widget: RecentlyVisitedStoresSection(
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {1}
      ),
      // --- Original service sections ---
      (widget: GroceryCardWidget(), tabs: {1, 3}),
      (widget: TransportServiceWidget(targetRiderKey: _riderWidgetKey), tabs: {2}),
      (widget: HotelStayServiceCard(isShowInGrid: inGrid), tabs: {2}),
      (widget: ShoppingCardWidget(), tabs: {3}),
      (widget: HomeMadeProductAndServiceWidget(), tabs: {3}),
      (widget: BookHomeServiceWidget(), tabs: {4}),
      (widget: ProfessionalsCardWidget(), tabs: {4}),
      (widget: HealthServiceCardWidget(), tabs: {4}),
      (widget: FindServiceCardWidget(), tabs: {4}),
      (widget: RentalCardWidget(), tabs: {4}),
      (widget: AutomotiveServiceCardWidget(), tabs: {4}),
      (widget: FinancialSectors(isShowInGrid: inGrid), tabs: {4}),
      (widget: EducationServiceCardWidget(), tabs: {4}),
      (widget: JobServiceCardWidget(), tabs: {5}),
    ];
  }

  @override
  void initState() {
    super.initState();
    emergencyController = getOrPut(() => EmergencyProfileController());

    _locationResolved = LocationService.hasUsableLocation;
    if (!_locationResolved) _ensureLocationThenBuild();
  }

  Future<void> _ensureLocationThenBuild() async {
    await LocationService.ensureUsableLocation();
    if (mounted) setState(() => _locationResolved = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// Light-blue header: location + wishlist, quick-access tabs,
            /// search bar. Covers the status bar area.
            SliverToBoxAdapter(child: _buildHeader(context)),

            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size12)),

            /// Category content — gated behind the shimmer while location and
            /// the initial fetch are still in flight.
            _buildSectionsSliver(),

            /// Emergency QR + sticker options — only on the overview tab, as
            /// in the previous design.
            if (_activeTabIndex == 0) ...[
              SliverToBoxAdapter(
                child: Builder(
                  builder: (_) =>
                      EmergencyQrWidget(key: const ValueKey('emergency_qr')),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  /// Single sliver that swaps between shimmer and the real section column.
  ///
  /// Gated on the location attempt AND the AuthController's category-loading
  /// flag — the section widgets read the onboarding buckets in their own build
  /// methods, so we subscribe to them here to repaint on the silent refresh.
  Widget _buildSectionsSliver() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final auth = Get.find<AuthController>();
        auth.onboardingBucketsWatch;
        if (auth.isInitialCategoriesLoading.value || !_locationResolved) {
          return const _DiscoverSectionsShimmer();
        }
        return _buildSectionsColumn();
      }),
    );
  }

  Widget _buildSectionsColumn() {
    final visible = _sections
        .where((s) => _activeTabIndex == 0 || s.tabs.contains(_activeTabIndex))
        .toList();
    return Column(
      children: [
        for (final s in visible) ...[
          Container(
            decoration: const BoxDecoration(color: AppColors.white),
            child: s.widget,
          ),
          SizedBox(height: SizeConfig.size12),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFE6FF), Color(0xFFDFEEFF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        top: statusBarHeight + SizeConfig.size12,
        left: SizeConfig.size12,
        right: SizeConfig.size12,
        bottom: SizeConfig.size16,
      ),
      child: Column(
        children: [
          _locationRow(context),
          SizedBox(height: SizeConfig.size16),
          _quickAccessTabs(),
          SizedBox(height: SizeConfig.size16),
          _searchRow(context),
        ],
      ),
    );
  }

  Widget _locationRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primaryColor, size: 20),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: Obx(
                    () => CustomText(
                      [
                        LocationService
                            .userCurrentAddress.value.subLocality,
                        LocationService.userCurrentAddress.value.city,
                      ].where((e) => e.isNotEmpty).join(', '),
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        _circleIconButton(
          child: const Icon(Icons.favorite_border,
              color: AppColors.primaryColor, size: 22),
          onTap: () {
            Navigator.pushNamed(context, RouteHelper.getYourCartScreenRoute());
          },
        ),
      ],
    );
  }

  Widget _circleIconButton({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }

  Widget _quickAccessTabs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(discoverQuickAccessTabs.length, (index) {
        final item = discoverQuickAccessTabs[index];
        final isActive = _activeTabIndex == index;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_activeTabIndex == index) return;
              setState(() => _activeTabIndex = index);
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryColor
                          : const Color(0xFFE1E8F2),
                      width: isActive ? 1.6 : 1,
                    ),
                    boxShadow: isActive
                        ? const [
                            BoxShadow(
                              color: Color(0x1A0086FF),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: LocalAssets(
                    imagePath: item['icon']!,
                    width: 30,
                    height: 30,
                    boxFix: BoxFit.contain,
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  item['title']!,
                  fontSize: SizeConfig.small,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _searchRow(BuildContext context) {
    return Row(
      children: [
        _circleIconButton(
          child: LocalAssets(
            imagePath: AppIconAssets.riderIconColorful,
            width: 24,
            height: 24,
          ),
          onTap: () => Navigator.pushNamed(
              context, RouteHelper.getGroceryStoresScreenRoute()),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(
              context,
              RouteHelper.getGlobalSearchScreenRoute(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppColors.secondaryTextColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      AppStrings.searchAnything.tr,
                      fontSize: SizeConfig.medium,
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
      ],
    );
  }
}

/// Shimmer skeleton shown in place of the Discover content while location and
/// the initial fetch are still resolving. Mirrors the card layout — a stack of
/// white cards each with a short title bar and a grid of round placeholders —
/// so the swap to real content reads as a content load, not a layout shift.
class _DiscoverSectionsShimmer extends StatelessWidget {
  const _DiscoverSectionsShimmer();

  static const int _cardCount = 3;
  static const int _columns = 5;
  static const int _tilesPerCard = 5;
  static const double _tileSpacing = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _cardCount; i++) ...[
          _shimmerCard(),
          SizedBox(height: SizeConfig.size12),
        ],
      ],
    );
  }

  Widget _shimmerCard() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLoadingShimmer(
            child: shimmerContainer(height: 22, width: 140),
          ),
          SizedBox(height: SizeConfig.size16),
          LayoutBuilder(builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - _tileSpacing * (_columns - 1)) /
                    _columns;
            return Wrap(
              spacing: _tileSpacing,
              runSpacing: _tileSpacing,
              children: List.generate(_tilesPerCard, (_) {
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      buildLoadingShimmer(
                        child: shimmerContainer(
                          height: itemWidth * 0.9,
                          width: itemWidth * 0.9,
                          radius: itemWidth,
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildLoadingShimmer(
                        child: shimmerContainer(height: 10, radius: 4),
                      ),
                    ],
                  ),
                );
              }),
            );
          }),
        ],
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

Widget titleWidget(String title) {
  return CustomText(title,
      fontSize: SizeConfig.large18,
      color: AppColors.mainTextColor,
      fontWeight: FontWeight.w600);
}
