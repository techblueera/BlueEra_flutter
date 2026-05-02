import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/all_top_selling_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_orders/my_grocery_orders.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Grocery Home screen (v2) — mirrors the medical home v2 layout so the
/// business owner sees a consistent, modern profile across me-section
/// services. Reuses [ViewBusinessDetailsController] for the profile data
/// and [GroceryController] for top-selling products & categories.
class GroceryHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const GroceryHomeScreenV2({super.key, required this.businessId});

  @override
  State<GroceryHomeScreenV2> createState() => _GroceryHomeScreenV2State();
}

class _GroceryHomeScreenV2State extends State<GroceryHomeScreenV2> {
  bool _isGoLive = false;
  int _selectedTab = 1;

  late final GroceryController _groceryController;
  final _businessController =
  getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  static const _tabs = [
    'Order',
    'Overview',
    'Products',
    'Post',
    'Statics',
  ];

  @override
  void initState() {
    super.initState();
    _groceryController = getOrPut(() => GroceryController());
    _groceryController.fetchAllGroceryData(widget.businessId, otherStore: false);
  }

  Future<void> _refresh() async {
    await _groceryController.fetchAllGroceryData(widget.businessId,
        otherStore: false);
  }

  // ─────────────────────────────────────────────
  // BUILD — fixed header (top bar + profile row + tabs row) with only
  // the tab content scrolling underneath it. Mirrors the reference
  // mock at assets/img.png: the chrome stays put while content moves.
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Android: light icons (white) on the dark blue gradient.
        statusBarIconBrightness: Brightness.light,
        // iOS: dark *brightness* of the bar means iOS draws light icons.
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF2FB),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              _buildPatternBackground(),
              Column(
                children: [
                  _buildTopBar(),
                  // _buildProfileRow(),
                  SizedBox(height: SizeConfig.size10),
                  _buildTabsCard(),
                  SizedBox(height: SizeConfig.size10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20,
                          bottom: kBottomNavigationBarHeight + 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildTabContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABS — segmented-control look per assets/img_1.png: a soft grey
  // capsule wraps the [HorizontalTabSelector]; selected tab is solid
  // primaryColor + white label, unselected tabs are white + dark
  // label. Centered horizontally on the screen.
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: HorizontalTabSelector<String>(
          tabs: _tabs,
          selectedIndex: _selectedTab,
          labelBuilder: (s) => s,
          onTabSelected: (index, _) => setState(() => _selectedTab = index),
          unSelectedBackgroundColor: Colors.white,
          unSelectedBorderColor: AppColors.borderBox,
          horizontalPadding: 8,
          verticalPadding: 6,
          horizontalMargin: 0,
          verticalMargin: 0,
          tabBorderRadius: 30,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab
  //   0 Order, 1 Overview, 2 Products, 3 Post, 4 Statics
  // ─────────────────────────────────────────────
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOrderTab();
      case 1:
        return _buildOverviewSlivers();
      case 2:
        return _buildProductsTab();
      case 3:
        return _buildPostTab();
      case 4:
        return [MedicalStatisticsScreen(businessId: widget.businessId)];
      default:
        return [_buildComingSoon()];
    }
  }

  // ─────────────────────────────────────────────
  // ORDER TAB — "Contribute now" CTA banner stacked above the legacy
  // [MyGroceryOrders] list. The banner is horizontally centered on
  // the screen and content-sized (shrink-wrapped) per the spec.
  // ─────────────────────────────────────────────
  List<Widget> _buildOrderTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    return [
      Padding(
        padding: EdgeInsets.only(right: SizeConfig.size12),
        child: Center(child: _contributeNowBanner()),
      ),
      SizedBox(height: SizeConfig.paddingM),
      SizedBox(
        height: screenHeight * 0.85,
        child: const MyGroceryOrders(),
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // CONTRIBUTE-NOW BANNER — frosted lavender CTA per assets/img.png.
  //   • Border: #844CD5 / 0.5 px
  //   • Gradient: #FAF3FF → #E7C8FF
  //   • Backdrop blur: 100
  //   • Shadow: #020122 @ 5% / blur 10 / offset (0, 2)
  // The shadow lives on the outer DecoratedBox so it casts cleanly
  // outside the ClipRRect that hosts the BackdropFilter.
  // ─────────────────────────────────────────────
  Widget _contributeNowBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const ContributionScreen()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D020122),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size14,
                  vertical: SizeConfig.size12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFAF3FF),
                    Color(0xFFE7C8FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF844CD5),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crown badge — frosted dark-purple gradient circle
                  // with a thin lavender ring and a white crown icon.
                  // Backdrop blur (1000) is clipped to the circle so
                  // the chrome behind the badge is heavily diffused.
                  ClipOval(
                    child: BackdropFilter(
                      filter:
                      ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF543680),
                              Color(0xFF311E52),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFD4BAFF),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'Contribute now',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF221831),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        'to get order & Visibility',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E5F8E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOverviewSlivers() {
    return [
      _buildJoinedProfileCard(),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: CommonBusinessLivePhoto(
          controller: _businessController,
        ),
      ),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: const BusinessDescriptionCard(),
      ),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details =
              _businessController.businessProfileDetails.value?.data;
          return BusinessContactMapCard(
            businessProfileDetails: details,
          );
        }),
      ),
      SizedBox(height: SizeConfig.size12),
      _buildQrCodeSection(),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: const BusinessShareBanner(),
      ),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // ─────────────────────────────────────────────
  // PROFILE CARDS — three INDEPENDENT containers with 12-px gaps:
  //   Card 1. Joined-date pill   → small left-aligned pill with calendar
  //                                 icon + "Joined - DD/MM/YYYY"
  //   Card 2. Identity + rating  → bigger logo, name, sub-cat pill, rating
  //   Card 3. Cover photo banner → editable 16:9 cover with "Edit" chip
  // Card 1 uses a different visual treatment (self-sized pill) than
  // cards 2 and 3 (full-width white cards) per assets/img_1.png.
  // ─────────────────────────────────────────────
  Widget _buildJoinedProfileCard() {
    return Obx(() {
      final details =
          _businessController.businessProfileDetails.value?.data;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Card 1 — content-sized pill, horizontally centered.
            _section1JoinedDate(details),
            SizedBox(height: SizeConfig.size12),
            // Card 2 — content-sized identity card, horizontally centered.
            // IntrinsicWidth gives the inner Column a bounded width so
            // the hairline divider + Expanded children inside the row
            // still get a finite parent extent.
            IntrinsicWidth(
              child: _profileCardWrap(
                child: _section2IdentityRating(details),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            // Card 3 — full-width cover-photo card. The inner photo is
            // already inset + rounded by the section itself, so the
            // outer wrap doesn't need `clip: true`.
            _profileCardWrap(child: _section3CoverBanner()),
          ],
        ),
      );
    });
  }

  // Card 1 — small left-aligned pill: calendar + "Joined - DD/MM/YYYY".
  // Per assets/img_1.png, this is its own self-sized container, not a
  // full-width card.
  Widget _section1JoinedDate(dynamic details) {
    final joined = _formatJoinedDate(details?.createdAt?.toString());
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 16,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              'Joined - $joined',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // Format `createdAt` (ISO-8601) as "D/MM/YYYY" — no zero pad on day,
  // 2-digit month, 4-digit year. Returns "--" when the input is empty
  // or unparseable so the pill always renders cleanly.
  String _formatJoinedDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '--';
    final mm = dt.month.toString().padLeft(2, '0');
    return '${dt.day}/$mm/${dt.year}';
  }

  Widget _profileCardWrap({required Widget child, bool clip = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.hardEdge : Clip.none,
      child: child,
    );
  }

  // Section 2 — identity card per assets/img_2.png:
  //   Row 1: [logo with edit pin] McDonald's
  //                                Automotive
  //   Hairline divider
  //   Row 2: ★ 4.8 (48 reviews)
  Widget _section2IdentityRating(dynamic details) {
    final logo =
        _businessController.imagePath?.value ?? details?.logo ?? '';
    final rating =
        double.tryParse(details?.avg_rating?.toString() ?? '0.0') ?? 0.0;
    final reviews = (details?.total_ratings ?? 0).toInt();
    final subCat = (details?.subCategoryDetails?.name ??
        details?.typeOfBusiness ??
        '')
        .toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: avatar (with edit pin) + name + sub-category ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatarWithEditPin(logo),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      details?.businessName ?? '',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      subCat,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          // ── Hairline divider ──
          Container(height: 1, color: Colors.grey.shade200),
          SizedBox(height: SizeConfig.size10),
          // ── Row 2: star + rating value + (reviews) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded,
                  size: 18, color: Color(0xFFFFB400)),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(width: SizeConfig.size6),
              CustomText(
                '($reviews ${reviews == 1 ? 'review' : 'reviews'})',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Logo with a small edit-pin badge anchored to its bottom-right.
  // Tapping either the avatar or the pin opens the cover-edit flow.
  Widget _avatarWithEditPin(String url) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _onEditCover,
              child: _avatar(
                url: url,
                size: 56,
                ringColor: AppColors.primaryColor.withValues(alpha: 0.35),
                ringWidth: 1.5,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: _onEditCover,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit,
                    size: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 3 — cover-photo card per assets/img_3.png:
  //   • Inset photo (rounded on all four corners)
  //   • Pagination dots centered near the bottom of the photo
  //   • Footer row: "Cover Photo" label on left, "Edit" pill on right
  Widget _section3CoverBanner() {
    return Obx(() {
      final cover = _businessController.coverImage?.value ?? '';
      final hasBanner = cover.isNotEmpty;
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Inset rounded photo (single banner — no carousel) ──
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: hasBanner
                    ? CachedNetworkImage(
                  imageUrl: cover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) =>
                      _emptyCoverPlaceholder(),
                )
                    : _emptyCoverPlaceholder(),
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            // ── Footer: label + edit pill ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomText(
                      'Cover Photo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onEditCover,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size12,
                          vertical: SizeConfig.size6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.primaryColor),
                          SizedBox(width: SizeConfig.size4),
                          CustomText('Edit',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Empty-state placeholder shown when no cover image is set or when
  // the network image fails to load.
  Widget _emptyCoverPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText('Add Your Banner Here',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  // Shared circular avatar — used by sections 1 and 2 with different
  // sizes/ring treatments.
  Widget _avatar({
    required String url,
    required double size,
    required Color ringColor,
    required double ringWidth,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
      ),
      clipBehavior: Clip.hardEdge,
      child: url.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _logoFallback(),
      )
          : _logoFallback(),
    );
  }

  // ─────────────────────────────────────────────
  // QR CODE — share/download the business profile
  // ─────────────────────────────────────────────
  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }

  // ─────────────────────────────────────────────
  // PRODUCTS TAB — top-level "Add Grocery" CTA, then the same
  // top-selling and category-with-inventory cards as Overview.
  // The category section keeps its inline "Update Inventory" link;
  // this top button is the dedicated bulk-upload entry point.
  // ─────────────────────────────────────────────
  List<Widget> _buildProductsTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _onAddMoreProducts,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: CustomText(
              AppStrings.addGrocery.tr,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
      ),
      SizedBox(height: SizeConfig.size12),
      _buildTopSellingSection(),
      SizedBox(height: SizeConfig.size12),
      _buildCategoryWithInventorySection(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  Future<void> _onAddMoreProducts() async {
    await Get.toNamed(
      RouteHelper.getGrocerySuperCategoryScreenRoute(),
      arguments: {ApiKeys.argBulkUpload: true},
    );
    if (_groceryController.groceryDataNeedsRefresh) {
      _groceryController.groceryDataNeedsRefresh = false;
      _groceryController.fetchAllGroceryData(widget.businessId,
          otherStore: false);
    }
  }

  // ─────────────────────────────────────────────
  // POST TAB — embeds FeedScreen filtered to current user's posts.
  // ─────────────────────────────────────────────
  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: _createPostCta(),
      ),
      SizedBox(height: SizeConfig.size12),
      FeedScreen(
        key: const ValueKey('grocery_v2_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  Widget _createPostCta() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: CustomText('Create Post',
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  /// Dialog with the same post-creation entries as the global app bar:
  /// Lekha, Symbol, Poll, and Job (business only).
  Future<void> _showCreatePostDialog() async {
    final isBusiness = isBusinessUser();
    final entries = <_PostMenuEntry>[
      _PostMenuEntry(
        type: PostCreationMenu.message,
        label: AppStrings.lekha.tr,
        iconAsset: AppIconAssets.message_post,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.symbol,
        label: AppStrings.symbol.tr,
        iconAsset: 'assets/icons/add_symbol_color.png',
      ),
      _PostMenuEntry(
        type: PostCreationMenu.poll,
        label: AppStrings.poll.tr,
        iconAsset: AppIconAssets.qa_ask_questionOutlinedIcon,
      ),
      if (isBusiness)
        _PostMenuEntry(
          type: PostCreationMenu.jobPost,
          label: AppStrings.jobPost.tr,
          iconAsset: AppIconAssets.uilSuitcaseOutlinedIcon,
        ),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Create Post',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size12),
              for (var i = 0; i < entries.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handlePostMenu(entries[i].type);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                        horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(
                            imagePath: entries[i].iconAsset,
                            height: 24,
                            width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostMenu(PostCreationMenu type) {
    switch (type) {
      case PostCreationMenu.message:
      case PostCreationMenu.poll:
        postVia(context, type);
        break;
      case PostCreationMenu.jobPost:
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(), arguments: {
          'isEditMode': false,
          'jobId': '',
          'createJobVia': 'business',
        });
        break;
      case PostCreationMenu.symbol:
        Get.to(() => AddChatSymbolScreen());
        break;
    }
  }

  Widget _buildComingSoon() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 48, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size10),
            CustomText(AppStrings.comingSoon,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BACKGROUND
  // ─────────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            topInset + SizeConfig.size8,
            SizeConfig.size12,
            SizeConfig.size10,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0387FF),
                Color(0xFF034785),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Color(0x26FFFFFF),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
              SizedBox(width: SizeConfig.size8),
              _nearbyRidersPill(),
              const Spacer(),
              _circleIconButton(
                  icon: Icons.notifications_none, onTap: _openNotifications),
              SizedBox(width: SizeConfig.size8),
              _goLivePill(),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: Get.width * 0.85,
          height: double.infinity,
          child: Drawer(child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x29FFFFFF),
                border: Border.all(
                  color: const Color(0x3DFFFFFF),
                  width: 0.6,
                ),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  /// Grocery-specific quick action — replaces medical's "Earn" pill so
  /// the merchant can hop straight to nearby riders for self-pickup
  /// or delivery dispatch.
  Widget _nearbyRidersPill() {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0x3DFFFFFF),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.riderIcon,
                    imgColor: Colors.white,
                    height: 18,
                    width: 18,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText('Nearby Riders',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: () => setState(() => _isGoLive = !_isGoLive),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0x3DFFFFFF),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText('Go live',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  SizedBox(width: SizeConfig.size6),
                  Container(
                    width: 30,
                    height: 18,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isGoLive
                          ? AppColors.primaryColor
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: _isGoLive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE ROW — owner-identity strip per assets/img.png:
  // [logo] businessName [+1]   [edit] [eye]
  //        typeOfBusiness
  // Fixed at top — does NOT scroll with the content.
  // ─────────────────────────────────────────────
  Widget _buildProfileRow() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          Obx(() {
            final details =
                _businessController.businessProfileDetails.value?.data;
            final logo = _businessController.imagePath?.value ??
                details?.logo ??
                '';
            return Container(
              height: SizeConfig.size40,
              width: SizeConfig.size40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              clipBehavior: Clip.hardEdge,
              child: logo.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _logoFallback(),
              )
                  : _logoFallback(),
            );
          }),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Obx(() {
              final details =
                  _businessController.businessProfileDetails.value?.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          details?.businessName ?? '',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText('+1',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    details?.typeOfBusiness ?? '',
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),
          IconButton(
            onPressed: _onEditCover,
            icon: Icon(Icons.edit_outlined,
                size: 20, color: AppColors.mainTextColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: SizeConfig.size8),
          IconButton(
            onPressed: _previewProfileAsVisitor,
            icon: Icon(Icons.remove_red_eye_outlined,
                size: 20, color: AppColors.mainTextColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() => Container(
    color: Colors.grey.shade200,
    child: Icon(Icons.storefront,
        size: 20, color: AppColors.secondaryTextColor),
  );

  Future<void> _onEditCover() async {
    try {
      final newPath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      _businessController.coverImage?.value = newPath;
      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage =
      await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final details = _businessController.businessProfileDetails.value?.data;
      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: details?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ─────────────────────────────────────────────
  // TOP-SELLING PRODUCTS (overview) — mirrors the card style used in
  // [MyGroceryStoreScreen] so the v2 home and the legacy store look
  // identical. Image-on-top, name, veg indicator + variant chip, PriceRow.
  // ─────────────────────────────────────────────
  Widget _buildTopSellingSection() {
    return Obx(() {
      final isLoading =
          _groceryController.fetchGroceryBusinessProductsResponse.value.status ==
              Status.INITIAL;
      final products = _groceryController.groceryBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 16,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.groceryViewTopSellingProduct.tr,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  InkWell(
                    onTap: () =>
                        Get.to(() => AllTopSellingGroceryProductsScreen(
                          userId: widget.businessId,
                          otherStore: false,
                        )),
                    child: CustomText(
                      AppStrings.groceryViewViewAll.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              SizedBox(
                height: SizeConfig.size230,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Builder(builder: (context) {
                  final previewItems = products.length >
                      GroceryController.businessProductsPreviewLimit
                      ? products
                      .take(GroceryController
                      .businessProductsPreviewLimit)
                      .toList()
                      : products.toList();
                  return ListView.builder(
                    itemCount: previewItems.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) =>
                        _productCard(previewItems[index]),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _productCard(BusinessProductData item) {
    final imageUrl = item.product?.images?.firstOrNull?.url ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      width: SizeConfig.size160,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyE5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(
                width: double.infinity,
                child: hasImage
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child:
                      CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                )
                    : LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  '${item.product?.name ?? ''}',
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                FittedBox(
                  child: Row(
                    children: [
                      if (item.productVariant?.isVegetarian != null) ...[
                        FoodTypeIndicator(
                            isVegetarian:
                            item.productVariant?.isVegetarian ?? false),
                        SizedBox(width: SizeConfig.size6),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              width: 0.5, color: AppColors.greyE5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 0.5),
                        child: CustomText(
                          '${item.productVariant?.variantName ?? ''}',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice:
                  '${AppConstants.rupeeSymbol}${item.minSellingPrice ?? '-'}',
                  mrp: '${AppConstants.rupeeSymbol}${item.minMrp ?? '-'}',
                  discount: '${item.avgDiscount ?? 0}% OFF',
                ),
                SizedBox(height: SizeConfig.size4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORIES WITH INVENTORY (overview) — mirrors the "Category" card
  // used in [MyGroceryStoreScreen]. Tapping "Update Inventory" opens
  // the super-category picker; tapping a card jumps to the nested
  // category-with-inventory screen for that key.
  // ─────────────────────────────────────────────
  Widget _buildCategoryWithInventorySection() {
    return Obx(() {
      final groceryCategoryList = List<GroceryCategoryWithInventoryModel>.from(
          _groceryController.groceryCategoryList);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 16,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.groceryViewCategory.tr,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  InkWell(
                    onTap: () async {
                      await Get.toNamed(
                        RouteHelper.getGrocerySuperCategoryScreenRoute(),
                        arguments: {ApiKeys.argBulkUpload: false},
                      );
                      if (_groceryController.groceryDataNeedsRefresh) {
                        _groceryController.groceryDataNeedsRefresh = false;
                        _groceryController.fetchAllGroceryData(
                            widget.businessId,
                            otherStore: false);
                      }
                    },
                    child: CustomText(
                      AppStrings.groceryViewUpdateInventory.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              groceryCategoryList.isNotEmpty
                  ? MasonryGridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groceryCategoryList.length,
                itemBuilder: (context, index) {
                  final categoryItem = groceryCategoryList[index];
                  return CommonServiceCard(
                    service: categoryItem,
                    getName: (c) => c.name ?? '',
                    getIcon: (c) => c.image ?? '',
                    iconHeight: SizeConfig.size60,
                    boxShadow: const [],
                    onTap: (c) {
                      return Get.toNamed(
                        RouteHelper
                            .getGroceryNestedCategoryWithInventoryScreenRoute(),
                        arguments: {
                          ApiKeys.userId: widget.businessId,
                          ApiKeys.argGroceryCategoryWithInventory:
                          groceryCategoryList,
                          ApiKeys.argArrGroceryCatKey: c.key,
                          ApiKeys.argArrGroceryCatName: c.name,
                        },
                      );
                    },
                  );
                },
              )
                  : EmptyStateWidget(
                message: AppStrings.groceryViewNoProductsYetCreate.tr,
              ),
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      );
    });
  }

  /// Opens the Discover-style profile preview so the owner can see the
  /// public profile the way other users discover it on the Discover screen.
  void _previewProfileAsVisitor() {
    final details = _businessController.businessProfileDetails.value?.data;
    final coverFromCtrl = _businessController.coverImage?.value ?? '';
    final logoFromCtrl = _businessController.imagePath?.value ?? '';

    final livePhotos = details?.livePhotos ?? const <String>[];

    final service = ServiceData()
      ..id = details?.id ?? widget.businessId
      ..name = details?.businessName
      ..profileImage = (coverFromCtrl.isNotEmpty
          ? coverFromCtrl
          : (logoFromCtrl.isNotEmpty ? logoFromCtrl : (details?.logo ?? '')))
      ..bio = details?.businessDescription
      ..address = details?.address
      ..category = details?.typeOfBusiness
      ..serviceMedia = ServiceMedia(photos: List<String>.from(livePhotos));

    Get.to(() => SelfProfessionScreenPreview(
      service: service,
      timingMap: const {},
      priceDisplay: '',
      priceBadgeText: '',
      priceBadgeColor: AppColors.primaryColor,
      isSelfPreview: true,
    ));
  }
}

class _PostMenuEntry {
  final PostCreationMenu type;
  final String label;
  final String iconAsset;

  const _PostMenuEntry({
    required this.type,
    required this.label,
    required this.iconAsset,
  });
}

