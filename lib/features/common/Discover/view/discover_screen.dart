import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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
import 'package:BlueEra/features/common/Discover/view/widget/grocery_food_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/job_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/professionals_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/restaurant_near_me_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/shopping_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/transport_service_widget.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_widget.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _qrWidgetKey = GlobalKey();

  @override
  void initState() {
    userLat = LocationService.lat;
    userLng = LocationService.lng;
    super.initState();
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              widget.onHeaderVisibilityChanged?.call(false);
            } else if (notification.direction == ScrollDirection.forward) {
              widget.onHeaderVisibilityChanged?.call(true);
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

              /// Search Bar - sticky on scroll
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  topPadding: MediaQuery.of(context).padding.top,
                ),
              ),

              _sliverGap(SizeConfig.size8),

              /// Grocery & Food
              _sliverCard(child: GroceryFoodCardWidget()),
              _sliverGap(),

              /// Medical / Healthcare Services
              _sliverCard(child: HealthServiceCardWidget()),
              _sliverGap(),

              /// Shopping
              _sliverCard(child: ShoppingCardWidget()),
              _sliverGap(),

              /// Home Services
              _sliverCard(child: BookHomeServiceWidget()),
              _sliverGap(),

              /// Home made food, product, service
              _sliverCard(child: HomeMadeProductWidget()),
              _sliverGap(),

              /// Stay Service
              _sliverCard(child: HotelStayServiceCard()),
              _sliverGap(),

              /// Consultation Service
              _sliverCard(child: ProfessionalsCardWidget()),
              _sliverGap(),

              /// Transport
              _sliverCard(child: TransportServiceWidget()),
              _sliverGap(),

              /// Rental Service
              _sliverCard(child: ResponsiveRentalCard()),
              _sliverGap(),

              /// Services
              _sliverCard(child: FindServiceCardWidget()),
              _sliverGap(),

              /// Financial Sectors
              _sliverCard(child: FinancialSectors()),
              _sliverGap(),

              /// Automotive Service
              _sliverCard(child: AutomotiveServiceCardWidget()),
              _sliverGap(),

              /// Restaurant
              _sliverCard(child: RestaurantNearMeCardWidget()),
              _sliverGap(),

              /// Education Service
              _sliverCard(child: EducationServiceCardWidget()),
              _sliverGap(),

              /// Job Service
              _sliverCard(child: JobServiceCardWidget()),
              _sliverGap(),

              /// Emergency QR
              SliverToBoxAdapter(
                child: Builder(
                  key: _qrWidgetKey,
                  builder: (_) {
                    getOrPut(() => EmergencyProfileController());
                    return EmergencyQrWidget(key: ValueKey('emergency_qr'));
                  },
                ),
              ),

              /// QR Sticker Design Options (visible when QR is generated)
              SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
                sliver: SliverToBoxAdapter(
                  child: Builder(
                    builder: (_) {
                      final emergencyController =
                          getOrPut(() => EmergencyProfileController());
                      return Obx(() {
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
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        border: Border.all(color: AppColors.secondaryTextColor, width: 0.1),borderRadius: BorderRadius.circular(8)),
    child: CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600),
  );
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;

  _StickySearchBarDelegate({required this.topPadding});

  @override
  double get minExtent => 56 + topPadding;

  @override
  double get maxExtent => 56 + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        top: topPadding + SizeConfig.size8,
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        bottom: SizeConfig.size8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          border: Border.all(width: 1, color: AppColors.secondaryTextColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.secondaryTextColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                AppStrings.searchAnything,
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
            LocalAssets(
              imagePath: AppIconAssets.camera_black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding;
}
