import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/app_home_background.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/admin/discount_food_products_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_category_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodMainScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const FoodMainScreen({super.key, this.fromBottomNavBar});

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 1;
  bool _isGoLive = false;
  late final TabController _tabController;

  late final RestaurantController _foodController;
  late final ViewBusinessDetailsController _businessController;

  // Drives the orders list shown under the Order tab. Same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  List<String> get _tabs => [
        AppStrings.orderTab.tr,
        AppStrings.overviewTab.tr,
        AppStrings.productsTab.tr,
        AppStrings.postTabLabel.tr,
        AppStrings.statisticsTab.tr,
      ];

  static const int _discountPreviewLimit = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_handleTabChange);
    _foodController = getOrPut(() => RestaurantController());
    _businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    // Hydrate the order chat list so the Order tab's incoming-orders
    // list has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Order tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Fire the API(s) backing the tab the screen lands on (Overview by
    // default). Switching tabs later will fire other tabs' APIs lazily
    // via [_onTabTapped] â€” mirrors product_screen's per-tab discipline.
    _fetchForTab(_selectedTab);
    // Mirrors grocery: prompt the live-photos upload sheet on first
    // paint when the business has no live photos yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip when the user isn't on the Me tab â€” the screen can mount
      // transiently during initial bottom-nav routing (currentIndex
      // starts at 0 â†’ meScreens, then post-frame flips to the intended
      // tab like Discover), and we don't want the sheet popping there.
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  /// Per-tab API dispatcher. Each tab owns a different data set, so we
  /// only fire the calls backing the visible tab when the user lands on
  /// it. Other tabs stay quiet until they're opened.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        // Order â€” order chat list is hydrated in initState; the
        // ContributionController binds lazily when its slot renders.
        break;
      case 1:
        // Overview â€” the joined-profile / contact / QR / share-banner
        // sections all read from [ViewBusinessDetailsController], which
        // is registered as a permanent singleton elsewhere on launch.
        // No food-specific API is needed for this tab.
        break;
      case 2:
        // Products â€” popular dishes + food menu grid.
        final id = businessId;
        if (id.isEmpty) return;
        _foodController.fetchHomeData(businessId: id);
        _foodController.fetchDiscountFoodProducts(businessId: id);
        break;
      case 3:
        // Post â€” FeedScreen owns its own controller fetch on mount.
        break;
      case 4:
        // Statistics â€” ProfileStatisticsScreen owns its own data.
        break;
    }
  }

  /// Keep [_selectedTab] (the content source-of-truth for FAB/go-live state)
  /// in sync with the TabController and fire the new tab's lazy fetch when the
  /// user taps a tab or swipes between them.
  void _handleTabChange() {
    if (_selectedTab != _tabController.index) {
      setState(() => _selectedTab = _tabController.index);
      _fetchForTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll(_buildOrderTab()),
                _tabScroll(_buildOverviewSlivers()),
                _tabScroll(_buildProductsTab()),
                _tabScroll(_buildPostTab()),
                ProfileStatisticsScreen(
                  userId: businessId.isNotEmpty ? businessId : userId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        _chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
        if (Get.isRegistered<ContributionController>()) {
          await Get.find<ContributionController>().fetchCurrent();
        }
        break;
      case 1:
        await _businessController.viewBusinessProfile();
        break;
      case 2:
        final id = businessId;
        if (id.isEmpty) return;
        _foodController.fetchHomeData(businessId: id);
        await _foodController.fetchDiscountFoodProducts(businessId: id);
        break;
      case 3:
        if (Get.isRegistered<FeedController>()) {
          await Get.find<FeedController>().getFeed(refresh: true);
        }
        break;
      case 4:
        // ProfileStatisticsScreen manages its own state and doesn't
        // expose an external refresh hook â€” no-op for now.
        break;
    }
  }

  /// Wraps a tab's content list in a refreshable, scrollable body for the
  /// [TabBarView]. The per-tab builders (`_buildOrderTab`, `_buildOverviewSlivers`,
  /// …) already return bounded box widgets, so a SingleChildScrollView + Column
  /// reproduces the previous SliverToBoxAdapter + Column layout exactly.
  Widget _tabScroll(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _onRefreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          top: SizeConfig.size4,
          bottom: kBottomNavigationBarHeight + 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // ORDER TAB â€” top slot is reactive to the contribution status:
  //   â€¢ Active recharge present â†’ premium "membership peek" card with
  //     plan name, perks-remaining strip, and a forward chevron that
  //     pushes ContributionScreen.
  //   â€¢ Otherwise â†’ the lavender "Contribute now" CTA.
  // The orders list itself is still a coming-soon placeholder.
  List<Widget> _buildOrderTab() {
    // Lazy-register the contribution controller â€” its `onInit` fires
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
      SizedBox(height: SizeConfig.size12),

      // its Orders tab. Wrapped in a SizedBox because OrdersTabView
      // uses an Expanded ListView internally and needs a bounded
      // height. Translated -20 on x (and given matching width) to
      // neutralise the parent SliverToBoxAdapter's left:20 padding so
      // the filter pills and chat tiles align edge-to-edge like on
      // ConnectMainPage. `excludeSenderId: userId` hides chats whose
      // last message was authored by the merchant, leaving only
      // `isInParentScroll: true` makes OrdersTabView drop its inner
      // `Expanded` and switch the orders ListView to
      // NeverScrollableScrollPhysics so the surrounding
      // CustomScrollView owns the scroll â€” no fixed height needed.
      // The parent SliverToBoxAdapter's left: 20 padding insets the
      // orders list naturally â€” no Transform needed.
      BusinessChatsList(
        excludeSenderId: userId,
        isInParentScroll: true,
        showDateFilter: true,
      ),
    ];
  }

  // PEEK SKELETON â€” placeholder shown while /recharge/current is
  // in-flight. Matches the active-plan peek silhouette so the slot
  // doesn't jump height when the answer lands.
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ACTIVE PLAN PEEK â€” compact aurora card mirroring the hero on
  // ContributionScreen so recognition is instant. Gold tier badge on
  // the left, plan name + ACTIVE pill on top, perks-remaining strip
  // on the bottom, and a glass forward chevron on the right. Tapping
  // anywhere pushes ContributionScreen for the full membership view.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _activePlanPeekCard(Map<String, dynamic> data) {
    final plan = (data['rechargePlanId'] is Map<String, dynamic>)
        ? data['rechargePlanId'] as Map<String, dynamic>
        : <String, dynamic>{};

    final name = (plan['name'] ?? AppStrings.activeContribution.tr).toString();
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
                                ? AppStrings.memberCapsPrefixFmt
                                    .trParams({'tier': tier.toUpperCase()})
                                : AppStrings.memberLabel.tr,
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
                            ? AppStrings.perksRemaining.tr
                            : AppStrings.perksRemainingWithTypeFmt.trParams({
                                'type': '${perkType[0].toUpperCase()}${perkType.substring(1)}',
                              }),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE9D9FF),
                      ),
                      CustomText(
                        AppStrings.perksOfTotalFmt.trParams({
                          'remaining': '$perksRemaining',
                          'total': '$totalPerks',
                        }),
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
          Text(
            AppStrings.activeStatusLabel.tr,
            style: const TextStyle(
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CONTRIBUTE-NOW BANNER â€” frosted lavender CTA, identical to the
  // grocery v2 implementation. Shadow lives on the outer DecoratedBox
  // so it casts cleanly outside the ClipRRect that hosts the blur.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
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
                        AppStrings.contributeNow.tr,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF221831),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        AppStrings.toGetOrderVisibility.tr,
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
      BusinessJoinedProfileCard(businessController: _businessController),
      SizedBox(height: SizeConfig.size12),
      _buildLivePhotosSection(),
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
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details =
              _businessController.businessProfileDetails.value?.data;
          return WebsiteOverviewCard(
            websiteUrl: details?.websiteUrl,
            onSave: (url) => _businessController.updateBusinessProfileDetails(
              {ApiKeys.websiteUrl: url},
            ),
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

  // PRODUCTS TAB â€” food menu categories grid
  List<Widget> _buildProductsTab() {
    return [
      _buildPopularDishesSection(),
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size16
        ),
        child: _menuSectionHeader(),
      ),
      _buildFoodMenuGrid(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // Header strip: vertical brand-bar + 2-line title block on the left,
  // a refined "Add Product" chip on the right. Title hierarchy:
  // 18 / w800 + 11 / w500 secondary helper.
  Widget _menuSectionHeader() {
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
                AppStrings.foodOurMenuLabel.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.tapCategoryToManageProducts.tr,
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
        _addProductCta(),
      ],
    );
  }

  // Refined CTA chip â€” feels like a navigation chip rather than a
  // stamped Material button. Circular filled `+` badge anchors the
  // left, brand-color label on the right, all inside a thin
  // primary-tinted outline with the section's standard shadow.
  Widget _addProductCta() {
    return GestureDetector(
      onTap: () => Get.to(() => FoodCategoryMenuScreen()),
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
              AppStrings.addProduct.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodMenuGrid() {
    return Obx(() {
      final List<GroceryNestedCategoryModel> menus =
          List<GroceryNestedCategoryModel>.from(
              _foodController.foodMenuNestedCategory);

      if (menus.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size20,
          ),
          child: EmptyStateWidget(
            message: AppStrings.foodNoProductCreate.tr,
            actionText: AppStrings.addProduct.tr,
            actionCallback: () => Get.to(() => FoodCategoryMenuScreen()),
          ),
        );
      }

      return LayoutBuilder(
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
            itemCount: menus.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: SizeConfig.size12,
              mainAxisSpacing: SizeConfig.size12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, i) => _foodMenuCategoryCard(menus[i]),
          );
        },
      );
    });
  }

  // Two-tone storefront card. Top zone is a soft brand-tinted "shelf"
  // that holds the icon as the hero; bottom zone is a crisp white
  // footer with the name + a tiny circular chevron. The whole card is
  // a single tap target â€” no separate "View Products" CTA â€” so the
  // information density is high and the silhouette stays clean.
  Widget _foodMenuCategoryCard(GroceryNestedCategoryModel item) {
    final hasImage = (item.image ?? '').isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategory(item),
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
              // Hero shelf â€” full-bleed photo covering the entire upper
              // zone. Pale brand tint sits behind as a fallback so the
              // hero never looks empty when the image is missing or
              // still loading.
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
                          : isNetwork
                              ? CachedNetworkImage(
                                  imageUrl: item.image!,
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
                                  imagePath: item.image!,
                                  boxFix: BoxFit.contain,
                                ),
                    ),
                  ),
                ),
              ),
              // Footer â€” name on the left, brand-color chevron on the
              // right inside a tiny pill. Hairline top divider keeps
              // the two zones visually distinct.
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


  Future<void> _openCategory(GroceryNestedCategoryModel item) async {
    if ((item.name ?? '').isEmpty) {
      commonSnackBar(message: AppStrings.invalidCategory.tr);
      return;
    }
    await Get.to(() => MyFoodProductScreen(foodMenu: item));
    if (_foodController.foodDataNeedsRefresh) {
      _foodController.foodDataNeedsRefresh = false;
      _foodController.fetchHomeData(businessId: businessId);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // POST TAB â€” embeds FeedScreen filtered to current user's posts.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        key: const ValueKey('food_v2_my_posts'),
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
        label: CustomText(AppStrings.createPost.tr,
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
              CustomText(AppStrings.createPost.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BACKGROUND
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPatternBackground() {
    return const AppHomeBackground();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 4),
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
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can ellipsize
                // instead of pushing the row past its width.
                Flexible(child: _nearbyRidersPill()),
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                  icon: Icons.notifications_none,
                  onTap: _openNotifications,
                ),
                SizedBox(width: SizeConfig.size6),
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

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
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
    );
  }

  /// Quick-action pill in the top bar â€” jumps to the nearby-riders
  /// screen so the merchant can dispatch self-pickup or delivery.
  /// Visually identical to the grocery v2 pill: glass white surface,
  /// rider icon, neutral grey label, thin #C9CDD5 border.
  Widget _nearbyRidersPill() {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
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
                Flexible(
                  child: CustomText(
                    AppStrings.nearbyRiders.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _goLivePill() {
    return GestureDetector(
      onTap: () => setState(() => _isGoLive = !_isGoLive),
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
                CustomText(AppStrings.goLive.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor),
                SizedBox(width: SizeConfig.size6),
                Container(
                  width: 30,
                  height: 18,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _isGoLive ? AppColors.primaryColor : Colors.white,
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
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PROFILE ROW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TABS â€” solid white card with high-contrast labels and an animated
  // underline that glides under the selected tab. Mirrors the grocery
  // home v2 design.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // JOINED + IDENTITY + COVER STACK â€” three stacked cards mirroring
  // the grocery v2 overview header:
  //   Card 1. Joined-date pill (calendar + DD/MM/YYYY)
  //   Card 2. Identity card (avatar w/ edit pin, name, sub-cat, rating)
  //   Card 3. Cover-photo banner with footer Edit pill
  // Card containers share the #00112042 / blur-10 shadow language used
  // across other section cards.

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // QR CODE â€” share/download the business profile
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // POPULAR DISHES (discount foods, horizontal)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPopularDishesSection() {
    return Obx(() {
      final isInitialLoading =
          _foodController.isDiscountProductsLoading.value &&
              _foodController.discountFoodItems.isEmpty;
      final hasItems = _foodController.discountFoodItems.isNotEmpty;
      if (!isInitialLoading && !hasItems) {
        return const SizedBox.shrink();
      }

      return _SectionCard(
        title: AppStrings.foodOfferDishDiscount.tr,
        trailingLabel: AppStrings.viewAll.tr,
        onTrailingTap: () => Get.to(
            () => DiscountFoodProductsScreen(businessId: businessId)),
        child: isInitialLoading
            ? const SizedBox(
                height: 240,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : _buildPopularDishesList(),
      );
    });
  }

  Widget _buildPopularDishesList() {
    final items = _foodController.discountFoodItems.length >
            _discountPreviewLimit
        ? _foodController.discountFoodItems
            .take(_discountPreviewLimit)
            .toList()
        : _foodController.discountFoodItems.toList();

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
        itemBuilder: (_, i) => _popularDishCard(items[i]),
      ),
    );
  }

  Widget _popularDishCard(CategoryFoodProductData item) {
    final hasVariants = item.variants != null && item.variants!.isNotEmpty;
    final variantCount = item.variants?.length ?? 0;
    final isMultiVariant = variantCount > 1;
    final sellingPrice = hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;
    final discountPercent =
        (mrp != null && sellingPrice != null && mrp > sellingPrice)
            ? (((mrp - sellingPrice) / mrp) * 100).round()
            : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showFoodProductVariantSheet(context, product: item),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.images?.firstOrNull ?? '',
                    height: 130,
                    width: 170,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      width: 170,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFFD7845), Color(0xFFFA5568)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          AppStrings.discountOffFmt
                              .trParams({'percent': '$discountPercent'}),
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
                  child: FoodTypeIndicator(
                    isVegetarian:
                        item.dietaryType?.toLowerCase() == AppConstants.veg,
                    size: 8,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.name ?? '',
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBadge(rating: '4.5'),
                      const SizedBox(width: 4),
                      Flexible(
                        child: CustomText(
                          AppStrings.reviewsKMock.tr,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          color: AppColors.secondaryTextColor,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${sellingPrice ?? 0}',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      if (mrp != null &&
                          sellingPrice != null &&
                          mrp >= sellingPrice) ...[
                        const SizedBox(width: 6),
                        CustomText(
                          '${AppConstants.rupeeSymbol}$mrp',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                  if (variantCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          isMultiVariant
                              ? AppStrings.variantsMoreFmt
                                  .trParams({'count': '${variantCount - 1}'})
                              : AppStrings.variantSingularFmt
                                  .trParams({'count': '$variantCount'}),
                          fontSize: 10,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUSINESS LIVE PHOTOS â€” same shared widget the grocery v2 home uses,
  // so styling and behavior stay in sync.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLivePhotosSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonBusinessLivePhoto(
        controller: _businessController,
      ),
    );
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SHARED SECTION CARD WRAPPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CustomText(title,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (trailingLabel != null)
                  GestureDetector(
                    onTap: onTrailingTap,
                    child: CustomText(trailingLabel!,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor),
                  ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            child,
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LIVE PHOTO SLOT
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LivePhotoSlot extends StatefulWidget {
  final int index;
  final String? photoUrl;
  final String label;
  final String placeholderImage;
  final List<String> allPhotos;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.photoUrl,
    required this.label,
    required this.placeholderImage,
    required this.allPhotos,
    required this.controller,
  });

  @override
  State<_LivePhotoSlot> createState() => _LivePhotoSlotState();
}

class _LivePhotoSlotState extends State<_LivePhotoSlot> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null;

    return GestureDetector(
      onTap: _isLoading ? null : _onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => _placeholderError(),
                    )
                  : _blurredPlaceholder(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: CustomText(
                widget.label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (!hasPhoto && !_isLoading)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 18,
                    width: 18,
                    imgColor: Colors.white,
                  ),
                ),
              ),
            ),
          if (hasPhoto && !_isLoading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: _onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onTap() async {
    final hasPhoto = widget.photoUrl != null;
    if (hasPhoto) {
      navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: AppStrings.imageViewer.tr,
          subTitle: '',
          imageUrls: widget.allPhotos,
          initialIndex: widget.index,
        ),
      );
      return;
    }
    final imgStr = await PhotoPickerService.pickFromCamera(
      context,
      cropAspectRatio: CropAspectRatio(width: 1, height: 1),
    );
    if (imgStr == null || imgStr.isEmpty) return;
    if (!await File(imgStr).exists()) {
      commonSnackBar(message: AppStrings.imageProcessingFailed.tr);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.controller.saveBusinessImages(imgStr, widget.controller);
      widget.controller.update(['livePhotos']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    if (widget.photoUrl == null) return;
    setState(() => _isLoading = true);
    try {
      final data = {ApiKeys.image_url: widget.photoUrl};
      await widget.controller.deleteLiveStoreImage(data);
      widget.controller.businessProfileDetails.value?.data?.livePhotos
          ?.removeAt(widget.index);
      widget.controller.update(['livePhotos']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _blurredPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.placeholderImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}