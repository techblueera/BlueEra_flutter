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
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/orders_chat/orders_chat_list.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
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
  bool _showStickyTabs = false;

  late final GroceryController _groceryController;
  final _businessController =
  getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  // Chat controller drives the Orders list shown under the Order tab.
  // Mirrors `ConnectMainPage._emitChatListForTab(2)` — same controller,
  // same event, so the data is shared with the Connect screen and
  // receives socket-driven updates while the user is on this screen.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

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
    // Hydrate the order chat list so the Orders section under the Order
    // tab has data ready when the user switches to it. Same emit shape
    // used by `ConnectMainPage` for its Orders tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.order_Chat_Type},
    );
  }

  Future<void> _refresh() async {
    await _groceryController.fetchAllGroceryData(widget.businessId,
        otherStore: false);
  }

  // ─────────────────────────────────────────────
  // BUILD — fixed header (top bar + profile row + tabs row) with only
  // the tab content scrolling underneath it. Mirrors the reference
  // mock at assets/img1.png: the chrome stays put while content moves.
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Approximate top-bar height; the sticky tabs overlay engages
    // once the user has scrolled past the original (in-flow) tabs.
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis != Axis.vertical) return false;
                final shouldShow = n.metrics.pixels > topBarHeight;
                if (shouldShow != _showStickyTabs) {
                  setState(() => _showStickyTabs = shouldShow);
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Top bar — slides out of view on scroll-down,
                    // snaps back on scroll-up (floating + snap).
                    SliverAppBar(
                      primary: false,
                      pinned: false,
                      floating: true,
                      snap: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      surfaceTintColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      toolbarHeight: topBarHeight,
                      flexibleSpace: _buildTopBar(),
                    ),
                    // In-flow tabs (no padding around them; let it sit
                    // tight under the top bar). When the user scrolls
                    // past, a separate overlay sticks them to the top.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _buildTabsCard(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          top: SizeConfig.size10,
                          bottom: kBottomNavigationBarHeight + 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildTabContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sticky overlay — only shown after the in-flow tabs have
            // scrolled past. Padded for the status bar so it doesn't
            // sit under the notch.
            if (_showStickyTabs)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: EdgeInsets.only(top: topInset + 10, bottom: 10),
                      decoration: const BoxDecoration(
                        color: Color(0x66FFFFFF),
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.white, width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x42001120),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                      child: _buildTabsCard(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABS — glass-pill container with a smoothly-sliding gradient
  // indicator that morphs between tabs. Selected tab text fades from
  // secondary grey → white and from medium → bold weight in a single
  // continuous transition. The indicator carries the brand-colored
  // glow + a 1-px inner top highlight for a "lifted glass" feel.
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // TABS — solid white card with high-contrast labels and an animated
  // underline that glides under the selected tab. The underline carries
  // a small brand-colored glow so the selection reads at a glance even
  // on busy backgrounds.
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A001120),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _tabs.length;
            const indicatorWidth = 28.0;
            final indicatorLeft =
                tabWidth * _selectedTab + (tabWidth - indicatorWidth) / 2;
            return Stack(
              children: [
                // Tap rows + animated labels. Selected tab swaps to
                // primaryColor + bold; unselected stays mainTextColor +
                // medium so the strip reads clearly when nothing is hot.
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedTab = i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                              color: selected
                                  ? AppColors.primaryColor
                                  : AppColors.mainTextColor,
                            ),
                            child: Text(_tabs[i]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Animated underline — slides between tabs. Soft
                // brand-color glow gives the indicator a touch of
                // emphasis without dominating the card.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  bottom: 6,
                  child: Container(
                    width: indicatorWidth,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
  // ORDER TAB — top slot is reactive to the contribution status:
  //   • Active recharge present → premium "membership peek" card with
  //     plan name, perks-remaining strip, and a forward chevron that
  //     pushes ContributionScreen.
  //   • Otherwise → the lavender "Contribute now" CTA.
  // Below the slot sits the legacy [MyGroceryOrders] list region.
  // ─────────────────────────────────────────────
  List<Widget> _buildOrderTab() {
    // Lazy-register the contribution controller — its `onInit` fires
    // /recharge/plans + /recharge/current. Bound here (only when the
    // Order tab actually builds) so the APIs don't run on every Me-tab
    // landing or on bottom-nav startup. Subsequent rebuilds reuse the
    // existing instance, so the calls fire at most once per session.
    final contributionController = getOrPut(() => ContributionController());

    return [
      Padding(
        padding: EdgeInsets.only(right: SizeConfig.size12),
        child: Center(
          child: Obx(() {
            final status = contributionController.currentStatus.value;
            if (status == Status.INITIAL || status == Status.LOADING) {
              return _planPeekSkeleton();
            }
            final hasPlan = contributionController.hasActiveRecharge.value;
            final data = contributionController.currentRecharge.value;
            if (hasPlan && data != null && data.isNotEmpty) {
              return _activePlanPeekCard(data);
            }
            return _contributeNowBanner();
          }),
        ),
      ),
      SizedBox(height: SizeConfig.size16),
      Builder(builder: (_) {
        debugPrint('[GroceryHomeV2] excludeSenderId(userId) = "$userId" '
            '| businessId="${widget.businessId}"');
        return OrdersTabView(
          excludeSenderId: userId,
          isInParentScroll: true,
        );
      }),
    ];
  }

  // ─────────────────────────────────────────────
  // PEEK SKELETON — placeholder shown while /recharge/current is
  // in-flight. Matches the active-plan peek silhouette so the slot
  // doesn't jump height when the answer lands.
  // ─────────────────────────────────────────────
  Widget _planPeekSkeleton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEFEAF7),
                Color(0xFFE3D9F4),
                Color(0xFFEFEAF7),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF844CD5).withValues(alpha: 0.18),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _shimmerBox(width: 44, height: 44, radius: 22),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _shimmerBox(width: 140, height: 14, radius: 4),
                        const SizedBox(height: 6),
                        _shimmerBox(width: 80, height: 10, radius: 4),
                      ],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Color(0xFF844CD5)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              _shimmerBox(width: double.infinity, height: 5, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFCDBCE9).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACTIVE PLAN PEEK — compact aurora card mirroring the hero on
  // ContributionScreen so recognition is instant. Gold tier badge on
  // the left, plan name + ACTIVE pill on top, perks-remaining strip
  // on the bottom, and a glass forward chevron on the right. Tapping
  // anywhere pushes ContributionScreen for the full membership view.
  // ─────────────────────────────────────────────
  Widget _activePlanPeekCard(Map<String, dynamic> data) {
    final plan = (data['rechargePlanId'] is Map<String, dynamic>)
        ? data['rechargePlanId'] as Map<String, dynamic>
        : <String, dynamic>{};

    final name = (plan['name'] ?? 'Active Contribution').toString();
    final tier = (plan['tier'] ?? '').toString();
    final perkType = (plan['perk_type'] ?? '').toString();
    final totalPerks = _asInt(data['total_perks']);
    final perksRemaining = _asInt(data['perks_remaining']);
    final progress = totalPerks > 0 ? perksRemaining / totalPerks : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => const ContributionScreen()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size12,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F1B5C),
                  Color(0xFF5E2BA8),
                  Color(0xFFB2308C),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFCD34D),
                            Color(0xFFF59E0B),
                            Color(0xFFB7781F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FCD34D),
                            blurRadius: 14,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 24,
                        color: Color(0xFF6B3A00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: CustomText(
                                  name,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: SizeConfig.size6),
                              _activePill(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            tier.isNotEmpty
                                ? '${tier.toUpperCase()} MEMBER'
                                : 'MEMBER',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE9D9FF),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (totalPerks > 0) ...[
                  SizedBox(height: SizeConfig.size12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        perkType.isEmpty
                            ? 'Perks remaining'
                            : '${perkType[0].toUpperCase()}${perkType.substring(1)} remaining',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE9D9FF),
                      ),
                      CustomText(
                        '$perksRemaining of $totalPerks',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFCD34D),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF047857),
            Color(0xFF065F46),
            Color(0xFF064E3B),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF34D399),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'ACTIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  // ─────────────────────────────────────────────
  // CONTRIBUTE-NOW BANNER — frosted lavender CTA per assets/img1.png.
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
              color: Color(0x42001120),
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
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
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
            color: Color(0x42001120),
            blurRadius: 10,
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
      _buildTopSellingSection(),
      SizedBox(height: SizeConfig.size16),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
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
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            border: Border.all(
              color: Colors.white,
              width: 1.0,
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
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
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
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.riderIcon,
                    imgColor: AppColors.secondaryTextColor,
                    height: 18,
                    width: 18,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText('Nearby Riders',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText('Go live',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor),
                  SizedBox(width: SizeConfig.size6),
                  Container(
                    width: 30,
                    height: 18,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isGoLive
                          ? AppColors.primaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondaryTextColor
                            .withValues(alpha: 0.4),
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
                        decoration: BoxDecoration(
                            color: _isGoLive
                                ? Colors.white
                                : AppColors.secondaryTextColor,
                            shape: BoxShape.circle),
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
  // PROFILE ROW — owner-identity strip per assets/img1.png:
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
  // TOP-SELLING PRODUCTS — editorial-style horizontal scroller. Each
  // tile is a ranked chart entry with a brand-tinted image hero, a
  // small "#01" rank pill, the green-gradient discount sticker, a
  // bold name, and a prominent price. A 3-px brand-blue gradient
  // ribbon caps the bottom edge so the section reads as one curated
  // shelf. Header uses the page's vertical-bar pattern + chip CTA.
  // ─────────────────────────────────────────────
  Widget _buildTopSellingSection() {
    return Obx(() {
      final isLoading =
          _groceryController.fetchGroceryBusinessProductsResponse.value.status ==
              Status.INITIAL;
      final products = _groceryController.groceryBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      final previewItems = products.length >
              GroceryController.businessProductsPreviewLimit
          ? products
              .take(GroceryController.businessProductsPreviewLimit)
              .toList()
          : products.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: _topSellingSectionHeader(),
          ),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 290,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : ListView.builder(
                    itemCount: previewItems.length,
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                    itemBuilder: (context, index) =>
                        _productCard(previewItems[index], index + 1),
                  ),
          ),
        ],
      );
    });
  }

  Widget _topSellingSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                AppStrings.groceryViewTopSellingProduct.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                'Hand-picked best sellers',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _viewAllCta(),
      ],
    );
  }

  // "View All" chip — label on the left, solid primary circular
  // arrow badge on the right. Mirrors the chip language used by the
  // category section's CTA on the opposite end.
  Widget _viewAllCta() {
    return GestureDetector(
      onTap: () => Get.to(() => AllTopSellingGroceryProductsScreen(
            userId: widget.businessId,
            otherStore: false,
          )),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.groceryViewViewAll.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Editorial "ranked tile" for the top-selling shelf. Image hero is
  // padded inside a brand-tinted gradient backdrop so product shots
  // never crop awkwardly. A small "#NN" pill in the top-right marks
  // the chart position; the green discount sticker sits opposite. The
  // info zone uses a clear three-row hierarchy (chips → name → price)
  // and the card is finished with a brand-blue gradient ribbon at
  // the bottom edge to anchor the silhouette.
  Widget _productCard(BusinessProductData item, int rank) {
    final imageUrl = item.product?.images?.firstOrNull?.url ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final discountPercent = (item.avgDiscount ?? 0).toInt();
    final variantName = item.productVariant?.variantName ?? '';
    final isVeg = item.productVariant?.isVegetarian;

    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
        boxShadow: const [
          // Grocery-flavoured shadow — soft green halo (matches the
          // discount sticker palette) instead of the page's neutral
          // navy shadow, so the shelf reads as "fresh / produce".
          BoxShadow(
            color: Color(0x3315B85A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image hero — brand-tinted backdrop with the photo
            // centered (BoxFit.contain so packaged products never
            // crop). Discount sticker top-left, rank pill top-right.
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor.withValues(alpha: 0.10),
                          AppColors.primaryColor.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox.expand(
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const SizedBox.shrink(),
                              errorWidget: (_, __, ___) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.contain,
                              ),
                            )
                          : LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.contain,
                            ),
                    ),
                  ),
                  if (discountPercent > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: const BoxDecoration(
                            // Grocery palette — fresh-leaf →
                            // deep-produce green pulled from AppColors
                            // so the sticker visibly belongs to the
                            // grocery section's brand language.
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.greenLight,
                                AppColors.green1A,
                              ],
                            ),
                          ),
                          child: CustomText(
                            '$discountPercent% OFF',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.30),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14001120),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: CustomText(
                        '#${rank.toString().padLeft(2, '0')}',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info zone — chips row, name, price hierarchy.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVeg != null || variantName.isNotEmpty)
                    Row(
                      children: [
                        if (isVeg != null) ...[
                          FoodTypeIndicator(isVegetarian: isVeg, size: 6),
                          const SizedBox(width: 6),
                        ],
                        if (variantName.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: CustomText(
                                variantName,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (isVeg != null || variantName.isNotEmpty)
                    const SizedBox(height: 8),
                  CustomText(
                    item.product?.name ?? '',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${item.minSellingPrice ?? '-'}',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: CustomText(
                          '${AppConstants.rupeeSymbol}${item.minMrp ?? '-'}',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Brand-blue gradient ribbon — the subtle "section
            // signature" that ties the shelf together.
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.55),
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  // ─────────────────────────────────────────────
  // CATEGORIES WITH INVENTORY — header strip + two-tone storefront
  // card grid. Same design language used in food's products tab:
  // a vertical brand-accent bar with title + helper, a refined chip
  // CTA on the right, and full-bleed photo cards below with a tinted
  // hero zone and a crisp footer carrying the name + a brand chevron.
  // ─────────────────────────────────────────────
  Widget _buildCategoryWithInventorySection() {
    return Obx(() {
      final groceryCategoryList = List<GroceryCategoryWithInventoryModel>.from(
          _groceryController.groceryCategoryList);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: _categorySectionHeader(),
          ),
          SizedBox(height: SizeConfig.size16),
          if (groceryCategoryList.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size20,
              ),
              child: EmptyStateWidget(
                message: AppStrings.groceryViewNoProductsYetCreate.tr,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12,
                    SizeConfig.size4,
                    SizeConfig.size12,
                    0,
                  ),
                  itemCount: groceryCategoryList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: SizeConfig.size12,
                    mainAxisSpacing: SizeConfig.size12,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (_, i) => _groceryCategoryCard(
                    groceryCategoryList[i],
                    groceryCategoryList,
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _categorySectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                AppStrings.groceryViewCategory.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                'Tap a category to manage inventory',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _addGroceryCta(),
      ],
    );
  }

  // Refined CTA chip — solid primary circular `+` badge anchors a
  // brand-outlined chip. Same shadow + border treatment as other
  // section chips so the rhythm reads as a single design language.
  Widget _addGroceryCta() {
    return GestureDetector(
      onTap: _onAddMoreProducts,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              AppStrings.addGrocery.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Two-tone storefront card. Tinted hero zone with the full image
  // (BoxFit.contain so nothing crops), crisp white footer with the
  // name + a small filled brand-blue chevron. Single tap target —
  // no separate "View Products" CTA — for a clean silhouette.
  Widget _groceryCategoryCard(
    GroceryCategoryWithInventoryModel item,
    List<GroceryCategoryWithInventoryModel> all,
  ) {
    final image = item.image ?? '';
    final hasImage = image.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(
          RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
          arguments: {
            ApiKeys.userId: widget.businessId,
            ApiKeys.argGroceryCategoryWithInventory: all,
            ApiKeys.argArrGroceryCatKey: item.key,
            ApiKeys.argArrGroceryCatName: item.name,
          },
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x42001120),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.10),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox.expand(
                      child: !hasImage
                          ? LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.contain,
                            )
                          : isNetworkImage(image)
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                )
                              : LocalAssets(
                                  imagePath: image,
                                  boxFix: BoxFit.contain,
                                ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEF1F4), width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10,
                  vertical: SizeConfig.size10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomText(
                        item.name ?? '',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate({
    required this.child,
    this.height = 56,
    this.topInset = 0,
  });

  final Widget child;
  final double height;
  final double topInset;

  @override
  double get minExtent => height + topInset;

  @override
  double get maxExtent => height + topInset;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final pinned = overlapsContent || shrinkOffset > 0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(top: pinned ? topInset : 0),
          decoration: BoxDecoration(
            color: pinned ? const Color(0x66FFFFFF) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: pinned ? Colors.white : Colors.transparent,
                width: 1,
              ),
            ),
            boxShadow: pinned
                ? const [
                    BoxShadow(
                      color: Color(0x42001120),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                      blurStyle: BlurStyle.outer,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.height != height ||
      oldDelegate.topInset != topInset;
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

