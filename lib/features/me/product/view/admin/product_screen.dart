import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/common/statistics/view/business_statistics_screen.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/view/admin/admin_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_home_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductScreen extends StatefulWidget {

  const ProductScreen({
    super.key,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTab = 1; // matches grocery's default (Overview)
  bool _isLoading = true;
  bool _isGoLive = false;
  bool _showStickyTabs = false;

  late final List<String> _tabs;
  late final List<Widget> _tabViews;

  final inventoryController = getOrPut(() => InventoryController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Hydrate the order chat list so the Order tab's incoming-orders
    // list has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Order tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  void _initializeData() {
    // Tabs mirror the grocery v2 home screen exactly so the merchant
    // sees a consistent layout across me-section services.
    _tabs = [
      AppStrings.orderTab.tr,
      AppStrings.overviewTab.tr,
      AppStrings.productsTab.tr,
      AppStrings.postTabLabel.tr,
      AppStrings.staticsTab.tr,
    ];

    _tabViews = [
      _OrdersTabBody(),
      const ProductHomeScreen(),
      _ProductsTabBody(onAddProduct: _onAddProduct),
      _PostTabBody(),
      BusinessStatisticsScreen(businessId: userId),
    ];

    _tabController = TabController(
      length: _tabViews.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_onTabChanged);
    MeTabRegistry.register(_tabController!);
    setState(() => _isLoading = false);
  }

  void _onTabChanged() {
    final c = _tabController;
    if (c == null) return;
    // No `indexIsChanging` guard here: on tap, `animateTo` notifies
    // listeners synchronously with `indexIsChanging == true`, and we
    // need to react at the START of the animation (not the end) so
    // the lazy product fetch fires for tap-driven changes too.
    if (_selectedTab != c.index) {
      setState(() => _selectedTab = c.index);
      // Fetch product data lazily â€” only when the merchant actually
      // opens the Products tab, not on every Me-tab landing.
      print('index--> ${c.index}');
      if (c.index == 2) {
        inventoryController.fetchAllProductData();
      }
    }
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        // Orders: re-pull the order chat list + recharge status.
        _chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
        if (Get.isRegistered<ContributionController>()) {
          await Get.find<ContributionController>().fetchCurrent();
        }
        break;
      case 1:
        // Overview: re-pull the business profile (drives joined date,
        // identity card, cover banner, contact-map, QR, share banner).
        await viewBusinessDetailsController.viewBusinessProfile();
        break;
      case 2:
        // Products: re-pull catalog + categories.
        inventoryController.fetchAllProductData();
        break;
      case 3:
        // Post: re-pull the merchant's own posts feed.
        if (Get.isRegistered<FeedController>()) {
          await Get.find<FeedController>().getFeed(refresh: true);
        }
        break;
      case 4:
        // Statics: BusinessStatisticsScreen manages its own state and
        // doesn't expose an external refresh hook â€” no-op for now.
        break;
    }
  }

  @override
  void dispose() {
    if (_tabController != null) {
      MeTabRegistry.unregister(_tabController!);
      _tabController!.removeListener(_onTabChanged);
    }
    _tabController?.dispose();
    super.dispose();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
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
                onRefresh: _onRefreshCurrentTab,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Top bar â€” slides out of view on scroll-down,
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
            // Sticky overlay â€” only shown after the in-flow tabs have
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
                      padding: EdgeInsets.only(
                          top: topInset + 10, bottom: 10),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TAB CONTENT â€” rebuilt per tab. Each branch returns the body
  // widgets the inner scroll content should host. Mirrors grocery's
  // _buildTabContent pattern so the outer CustomScrollView controls
  // the scroll for every tab.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOrderTab();

      case 1:
        return const [ProductHomeScreen()];
      case 2:
        return [_ProductsTabBody(onAddProduct: _onAddProduct)];
      case 3:
        return [_PostTabBody()];
      case 4:
        return [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: BusinessStatisticsScreen(businessId: userId),
          ),
        ];
      default:
        return const [SizedBox.shrink()];
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ORDER TAB â€” top slot is reactive to the contribution status:
  //   â€¢ Active recharge present â†’ premium "membership peek" card with
  //     plan name, perks-remaining strip, and a forward chevron that
  //     pushes ContributionScreen.
  //   â€¢ Otherwise â†’ the lavender "Contribute now" CTA, identical to
  //     grocery v2.
  // Below the slot sits the orders list region. Outer CustomScrollView
  // owns the scroll â€” body is a fixed-height window so the merchant
  // sees the orders list within the same surface.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            // While /recharge/current is resolving, hold the slot
            // with a skeleton instead of flashing the contribute
            // banner first and then swapping to the active card.
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
      // Incoming orders â€” same widget the Connect screen renders under
      // its Orders tab. Wrapped in a SizedBox because OrdersTabView
      // uses an Expanded ListView internally and needs a bounded
      // height. Translated -20 on x (and given matching width) to
      // neutralise the parent SliverToBoxAdapter's left:20 padding so
      // the filter pills and chat tiles align edge-to-edge like on
      // ConnectMainPage. `excludeSenderId: userId` hides chats whose
      // last message was authored by the merchant, leaving only
      // incoming order pings â€” same approach as the Grocery screen.
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PEEK SKELETON â€” placeholder shown while /recharge/current is
  // in-flight. Matches the active-plan peek silhouette (badge â–¸ two
  // text bars â–¸ chevron â–¸ progress strip) so the slot doesn't jump
  // height when the answer lands. Uses a shimmering frosted-glass
  // gradient so it reads as "loading" without looking like a CTA.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              _shimmerBox(
                width: double.infinity,
                height: 5,
                radius: 4,
              ),
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
                  // Aurora â€” same indigo â†’ violet â†’ magenta tri-stop
                  // the ContributionScreen hero card uses.
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
                    // Gold tier badge â€” warm sun gradient with glow.
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
                    // Glass forward chevron â€” translucent disc with a
                    // 1px white rim so it pops on the aurora.
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
                  offset: Offset(0, 0),
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
  // grocery v2 implementation. Tapping pushes ContributionScreen.
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BACKGROUND
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP BAR â€” glass-morphic chrome mirroring the grocery v2 home:
  // backdrop blur (50), translucent white fill (#FFFFFF33), white
  // border, and a soft outer #00112042 / blur-16 shadow that paints
  // outside the ClipRect via BlurStyle.outer so the glass interior
  // stays clean.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    final isGuest = isGuestUser();

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
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can
                // ellipsize instead of pushing the row past its width.
                Flexible(child: _nearbyRidersPill()),
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                if (!isGuest) ...[
                  _circleIconButton(
                    icon: Icons.notifications_none,
                    onTap: _openNotifications,
                  ),
                  SizedBox(width: SizeConfig.size6),
                ],
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

  /// Same flow that was previously triggered by the top-bar "Add Product"
  /// pill â€” now reused by the "Add Product" tab pill.
  Future<void> _onAddProduct() async {
    if (businessId.isEmpty) return;
    await Get.toNamed(
      RouteHelper.getProductSuperCategoryScreenRoute(),
      arguments: {
        ApiKeys.id: businessId,
        ApiKeys.providerType: ProviderType.business,
      },
    );
    if (inventoryController.productDataNeedsRefresh) {
      inventoryController.productDataNeedsRefresh = false;
      // After a publish the merchant wants to see the new item in the
      // catalog, not whatever tab they launched the add flow from. Jump
      // to the Products tab before kicking off the refresh.
      _tabController?.animateTo(2);
      inventoryController.fetchAllProductData();
    }
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

  /// Quick-action pill â€” jumps to the nearby-riders screen so the
  /// merchant can dispatch self-pickup or delivery. Glass white
  /// surface + #C9CDD5 outline matching the grocery v2 pill.
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

  /// Go-live toggle pill. Off-state: white track + grey thumb.
  /// On-state: brand-blue track + white thumb. Same chip language
  /// the grocery v2 top bar uses.
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
                CustomText(
                  AppStrings.goLive.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
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
  // v2 home design so styling stays consistent across me-section.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTabTapped(i),
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

  void _onTabTapped(int i) {
    final c = _tabController;
    if (c == null) return;
    if (i < 0 || i >= c.length) return;
    if (i == c.index) return;
    // _selectedTab is updated by _onTabChanged when animateTo
    // notifies â€” no preemptive setState here, otherwise the listener
    // sees `_selectedTab == c.index` and skips the fetch on tap.
    c.animateTo(i);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST TAB â€” embeds FeedScreen filtered to the current user's posts.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PostTabBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return FeedScreen(
      key: const ValueKey('inventory_v2_my_posts'),
      postFilterType: PostType.myPosts,
      id: userId,
      isInParentScroll: true,
      horizontalPaddingChannel: SizeConfig.size12,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PRODUCTS TAB â€” surfaces the merchant's top-selling preview and the
// category-with-inventory grid. The Overview tab no longer carries
// these sections; this dedicated lane makes catalog management the
// primary action of the Products tab.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProductsTabBody extends StatefulWidget {
  final VoidCallback onAddProduct;

  const _ProductsTabBody({required this.onAddProduct});

  @override
  State<_ProductsTabBody> createState() => _ProductsTabBodyState();
}

class _ProductsTabBodyState extends State<_ProductsTabBody> {
  final controller = getOrPut(() => InventoryController());

  @override
  Widget build(BuildContext context) {
    // Content-only â€” outer CustomScrollView in InventoryScreen owns
    // the scroll + RefreshIndicator. This widget just lays out its
    // sections in a Column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Top Selling Products ---
        Obx(() {
          if (controller.ownDraftAndPublicProductResponse.value.status ==
              Status.INITIAL) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: buildHorizontalListSkeleton(),
            );
          }
          return controller.allProducts.isNotEmpty
              ? _topSellingProduct()
              : const SizedBox.shrink();
        }),

        // --- Section header â€” vertical brand-bar + 2-line title +
        // refined "Add Product" chip CTA.
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size4,
              vertical: SizeConfig.size12),
          child: _productsSectionHeader(),
        ),

        // --- Category â€” two-tone storefront cards.
        Obx(() {
          if (controller.fetchProductCategoryResponse.value.status ==
              Status.INITIAL) {
            return buildCategoryGridSkeleton();
          }
          return _categoryWithInventoryGrid();
        }),
      ],
    );
  }

  Widget _productsSectionHeader() {
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
                AppStrings.ourProducts.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.tapCategoryToManageInventory.tr,
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

  // Refined CTA chip â€” solid primary circular `+` badge anchors the
  // outlined chip. Same chip language used in food's products tab.
  Widget _addProductCta() {
    return GestureDetector(
      onTap: widget.onAddProduct,
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

  // Editorial "best-seller chart" shelf â€” vertical-bar header + chip
  // CTA up top, horizontal scroller of ranked tiles below. Card uses
  // a brand-tinted hero, orangeâ†’pink discount sticker, "#NN" rank
  // pill, three-row info hierarchy, and a brand-blue gradient ribbon
  // at the bottom edge so the entire shelf reads as one curated row.
  Widget _topSellingProduct() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
            child: _topSellingHeader(),
          ),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            // Was 290 (sized for the old card with the attribute-chip
            // row). After that row was removed, the card's natural max
            // is ~245 (hero 160 + info 60 + paddings/ribbon). 250 keeps
            // a 5px buffer for descender/line-height variance.
            height: 250,
            child: Builder(builder: (context) {
              final previewCount = controller.allProducts.length >
                      InventoryController.ownProductsPreviewLimit
                  ? InventoryController.ownProductsPreviewLimit
                  : controller.allProducts.length;
              return ListView.builder(
                itemCount: previewCount,
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                itemBuilder: (context, index) =>
                    _topSellingCard(index, controller.allProducts[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _topSellingHeader() {
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
                AppStrings.topSelling.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.customersFavoritesThisMonth.tr,
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
        _topSellingViewAllChip(),
      ],
    );
  }

  // "View All" chip â€” label on the left, solid primary circular
  // arrow badge on the right. Mirrors the other chip CTAs on the page.
  Widget _topSellingViewAllChip() {
    return GestureDetector(
      onTap: () => Get.to(() => const AdminAllTopSellingProductsScreen()),
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
              AppStrings.viewAll.tr,
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

  Widget _topSellingCard(int index, dynamic product) {
    final details = product.product.details;
    final variants = product.product.sellerClassification?.variants ?? [];
    final img = (details?.media.isNotEmpty ?? false)
        ? details!.media.first
        : '';
    final hasVariants = variants.isNotEmpty;
    final sellingPrice = hasVariants ? variants[0].sellingPrice : null;
    final mrp = hasVariants ? variants[0].mrp : null;
    final discountRaw = hasVariants
        ? calculateDiscount('${variants[0].sellingPrice}',
            '${variants[0].mrp}')
        : 0;
    final discountPercent = discountRaw.toInt();
    final rank = index + 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => const AdminAllTopSellingProductsScreen()),
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero zone â€” brand-tinted backdrop with the photo
            // centered (BoxFit.contain so product shots never crop).
            // Discount sticker top-left, rank pill top-right.
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
                    padding: const EdgeInsets.all(10),
                    child: SizedBox.expand(
                      child: img.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.contain,
                              placeholder: (_, __) =>
                                  const SizedBox.shrink(),
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
                            // Fresh-leaf â†’ deep-produce green pulled
                            // from AppColors so the sticker reads as
                            // part of the brand green palette.
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
            // Info zone â€” name + price hierarchy.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    details?.name ?? '',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (hasVariants)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CustomText(
                          '${AppConstants.rupeeSymbol}$sellingPrice',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: CustomText(
                            '${AppConstants.rupeeSymbol}$mrp',
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
            // Brand-blue gradient ribbon â€” section "signature" that
            // anchors every tile and ties the shelf together.
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
      ),
    );
  }

  Widget _categoryWithInventoryGrid() {
    final List<ProductCategoryWithInventoryModel> categoryList =
        controller.productNestedCategoryList;
    if (categoryList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size20,
        ),
        child: EmptyStateWidget(
          message: AppStrings.noProductYetCreateOne.tr,
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
            SizeConfig.size4,
            SizeConfig.size4,
            SizeConfig.size4,
            0,
          ),
          itemCount: categoryList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: SizeConfig.size12,
            mainAxisSpacing: SizeConfig.size12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) =>
              _inventoryCategoryCard(categoryList[i], categoryList),
        );
      },
    );
  }

  // Two-tone storefront card â€” tinted hero zone with the full image
  // (BoxFit.contain so nothing crops), crisp white footer with the
  // name + a small filled brand-blue chevron. Single tap target â€”
  // no separate "View Products" CTA â€” for a clean silhouette.
  Widget _inventoryCategoryCard(
    ProductCategoryWithInventoryModel item,
    List<ProductCategoryWithInventoryModel> categoryList,
  ) {
    final image = (item.image ?? '').toString();
    final hasImage = image.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(
          RouteHelper.getProductNestedCategoryWithInventoryScreenRoute(),
          arguments: {
            ApiKeys.userId: businessId,
            ApiKeys.argProductCategoryWithInventory: categoryList.toList(),
            ApiKeys.argProductCatKey: item.key ?? '',
            ApiKeys.argProductCatName: item.name ?? '',
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
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ORDERS TAB â€” placeholder until product orders ships.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _OrdersTabBody extends StatelessWidget {
  const _OrdersTabBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size40,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              AppStrings.orders.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.comingSoon.tr,
              fontSize: 12,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
