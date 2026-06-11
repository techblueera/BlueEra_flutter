import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_store_section.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/personal_qrcode_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SelfEmployeeScreen extends StatefulWidget {
  const SelfEmployeeScreen({
    super.key,
  });

  @override
  State<SelfEmployeeScreen> createState() => _SelfEmployeeScreenState();
}

class _SelfEmployeeScreenState extends State<SelfEmployeeScreen>
    with SingleTickerProviderStateMixin {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());

  late final TabController _tabController;

  // Drives the inquiry list shown under the Order tab. Same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  // Backs the "Store" tab cards — holds the user's earn profile (logo,
  // cover, address, diet, delivery flags, gallery) for the summary card.
  final EarnProfileController _earnProfileCtrl =
      getOrPut(() => EarnProfileController());

  // True when the user has created one of the home-made earn profiles.
  // Used to decide whether to hydrate the earn profile on load.
  bool get _hasEarnProfile => _viewCtrl.earnProfileType.isNotEmpty;

  // The Store tab is always present, placed just before Statics (index 4).
  List<String> get _tabs => [
        AppStrings.order.tr,
        AppStrings.overview.tr,
        AppStrings.service.tr,
        AppStrings.post.tr,
        AppStrings.store.tr,
        AppStrings.statics.tr,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: 1,
      vsync: this,
    );
    _viewCtrl.UserFollowersAndPostsCount(userId);
    // Hydrate the business chat list so the Order tab's inquiry list
    // has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Inquiry tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Hydrate the earn profile so the "Store" tab card can show real
    // store details (name / cover / address / chips).
    if (_hasEarnProfile) {
      _earnProfileCtrl.fetchEarnProfile();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  // with a sticky tab overlay that engages once the in-flow tabs
  // have scrolled past the top bar (mirrors grocery v2).
  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: ProfileTopBar(
                onGoLiveTap: _handleGoLiveTap,
                showGoLivePill: Platform.isAndroid,
              ),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll(_buildOrderTab()),
                _tabScroll(_buildOverviewTab()),
                _tabScroll(_buildServiceTab()),
                _tabScroll(_buildPostTab()),
                _tabScroll(_buildEarnTab()),
                _tabScroll(_buildStaticsTab()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TOP BAR â€” glassmorphic strip:
  //   [drawer] [Earn/profile selector]   â€¦   [bell] [Go Live]



  // Going live needs background location, battery-optimization, and
  // display-over-other-apps. If any are missing we route through
  // [GoLivePermissionScreen] and only flip the shop status once the
  // user finishes granting them. Turning the shop back off doesn't
  // need any of these checks.
  Future<void> _handleGoLiveTap() async {
    if (_viewCtrl.shopStatusOpenClose.value) {
      _viewCtrl.toggleShopStatus();
      return;
    }
    final statuses = await GoLivePermissionService.checkAll();
    if (statuses.values.every((v) => v)) {
      _viewCtrl.toggleShopStatus();
      return;
    }
    final granted = await Get.to(() => const GoLivePermissionScreen());
    if (granted == true) {
      _viewCtrl.toggleShopStatus();
    }
  }


  // TABS â€” solid white card with an animated underline that slides
  // beneath the selected tab.
  /// Wraps a tab's content list in a scrollable body for the [TabBarView].
  /// The per-tab builders return bounded box widgets, so SingleChildScrollView
  /// + Column reproduces the previous SliverToBoxAdapter + Column layout.
  Widget _tabScroll(List<Widget> children) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // STORE TAB — always visible. Lists all three earn flavours (food /
  // product / service). The flavour the user has created shows a rich
  // storefront card that opens the earn dashboard; the rest show an "Add"
  // card that routes to that flavour's create flow.
  List<Widget> _buildEarnTab() {
    // Reuses the shared [EarnStoreCards] so the made/add storefront cards are
    // identical across all individual profile screens.
    return [const EarnStoreCards()];
  }

  // Order tab â€” top slot is reactive to the contribution status:
  //   â€¢ Active recharge present â†’ premium "membership peek" card with
  //     plan name, perks-remaining strip, and a forward chevron that
  //     pushes ContributionScreen.
  //   â€¢ Otherwise â†’ the lavender "Contribute now" CTA.
  // Below the slot sits the legacy [SelfEmployeeOrders] body. Lazy-
  // registers ContributionController so /recharge/* fires only when
  // the Order tab actually builds.
  List<Widget> _buildOrderTab() {
    final contributionController = getOrPut(() => ContributionController());
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
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
      BusinessChatsList(
        isForwardUI: false,
        excludeSenderId: userId,
        isInParentScroll: true,
      ),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PEEK SKELETON â€” placeholder shown while /recharge/current is
  // in-flight. Matches the active-plan peek silhouette so the slot
  // doesn't jump height when the answer lands.
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
                      valueColor: AlwaysStoppedAnimation(Color(0xFF844CD5)),
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
  // ContributionScreen so recognition is instant.
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
                                ? '${tier.toUpperCase()} ${AppStrings.memberLabel.tr}'
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
                            : '${perkType[0].toUpperCase()}${perkType.substring(1)} ${AppStrings.remainingLabel.tr}',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE9D9FF),
                      ),
                      CustomText(
                        '$perksRemaining ${AppStrings.outOf.tr} $totalPerks',
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
            AppStrings.active.tr.toUpperCase(),
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
  // CONTRIBUTE-NOW BANNER â€” frosted lavender CTA. Border #844CD5/0.5,
  // gradient #FAF3FF â†’ #E7C8FF, backdrop blur 100, soft navy shadow.
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
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
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

  // the parent CustomScrollView so its sections share the page's
  // scroll. That lets the sticky-tab overlay engage when the user
  // scrolls past the top bar (matches the Post tab's behavior).
  List<Widget> _buildServiceTab() {
    return const [SelfProfessionServiceScreen()];
  }

  // POST TAB â€” embeds FeedScreen filtered to the current user's
  // posts. Mirrors grocery v2's post tab so creators see the same
  // CTA + feed treatment across me-section dashboards.
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
        key: const ValueKey('self_employee_my_posts'),
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
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  /// Dialog with the same post-creation entries as the global app
  /// bar: Lekha, Symbol, Poll, and Job (business only).
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
      _PostMenuEntry(
        type: PostCreationMenu.reel,
        label: 'Reel',
        iconAsset: AppIconAssets.video_outline,
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
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.createPost.tr,
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
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10, horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(imagePath: entries[i].iconAsset, height: 24, width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1) Divider(height: 1, color: Colors.grey.shade200),
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
      case PostCreationMenu.reel:
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

  // Statics tab â€” chat-click analytics, same as grocery/medical
  // dashboards' last tab. Uses the current user's id as the analytics
  // key since self-employed accounts don't have a separate businessId.
  List<Widget> _buildStaticsTab() {
    return [
      ProfileStatisticsScreen(userId: userId),
      SizedBox(height: SizeConfig.size12),
      _earnStatPlaceholder('Home Made Food Statistics'),
      _earnStatPlaceholder('Home Made Products Statistics'),
      _earnStatPlaceholder('Home Service Statistics'),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // Per-earn-type statistics shown below the main chat-click analytics.
  // Labeled placeholders for now — real data will be wired in later.
  Widget _earnStatPlaceholder(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              'Statistics coming soon',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // OVERVIEW TAB â€” refined editorial identity dossier:
  //   1. Single hero card unifying the cover banner, the avatar
  //      (straddling the photo/sheet boundary), and the identity
  //      block (designation eyebrow â†’ name â†’ username Â· member-since
  //      â†’ location/email rows). Hairline divides photo from sheet.
  //   2. Stats card with hero-typed numerals and primary-color
  //      accent bars stamped beneath each metric.
  //   3. Action row with explicit Share + Business-Card pills.
  List<Widget> _buildOverviewTab() {
    return [
      _buildIdentityCard(context),
      _buildStatsCard(),
      Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
        child: const ProfileBioCard(margin: EdgeInsets.zero),
      ),
      _buildActionRow(),
      const RentalPropertyCard(
        margin: EdgeInsets.only(top: 10, left: 20, right: 10),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
        child: const ProfileLocationCard(margin: EdgeInsets.zero),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
        child: Obx(() => WebsiteOverviewCard(
              websiteUrl: _viewCtrl.website.value,
              onSave: (url) => _personalCtrl.updateUserProfileDetails(
                params: {ApiKeys.website: url},
                isFromProfileOnly: true,
              ),
            )),
      ),
      _buildQrCard(),
      _buildShareBanner(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // V2 opener + inline `_buildRentalCardV2` + `_rentalPropertyTile`
  // moved to the shared widget `RentalPropertyCardV2`
  // (lib/features/common/rental/widget/rental_property_card_v2.dart)
  // so cab / rider / professionals / self-employee dashboards all
  // render the same V2 card with one source of truth.

  // â”€â”€â”€ IDENTITY CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // The cover banner, profile avatar, and identity block live in
  // ONE rounded sheet so the eye reads them as a single dossier
  // rather than three disconnected stripes. The avatar straddles the
  // photo/sheet boundary, anchored by a 4-px white ring + soft
  // shadow so it reads as a frame, not a sticker.
  Widget _buildIdentityCard(BuildContext context) {
    const bannerHeight = 200.0;
    const avatarSize = 88.0;
    const avatarOverlap = avatarSize / 2; // half on photo, half on sheet
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              SizedBox(
                height: bannerHeight + avatarOverlap,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: bannerHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _bannerImage()),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _glassActionPill(
                              icon: Icons.camera_alt_rounded,
                              label: AppStrings.editCover.tr,
                              onTap: () => _onCoverImageEdit(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _avatarFrame(avatarSize),
                          SizedBox(width: SizeConfig.size12),
                          Padding(
                            padding: EdgeInsets.only(bottom: avatarOverlap - 4),
                            child: _memberSincePill(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildIdentityBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerImage() {
    return Obx(() {
      final banner = _personalCtrl.coverImagePath?.value ?? '';
      if (banner.isNotEmpty) {
        return Image.network(banner, fit: BoxFit.cover);
      }
      final fallback = _personalCtrl.imagePath?.value ?? '';
      if (fallback.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: fallback,
          fit: BoxFit.cover,
          placeholder: (_, __) => _coverFallback(),
          errorWidget: (_, __, ___) => _coverFallback(),
        );
      }
      return _coverFallback();
    });
  }

  Widget _coverFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.18),
              AppColors.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  // Identity block â€” sits directly under the banner Stack. The
  // avatar already lives inside the banner Stack's bounds (so it's
  // hit-testable), so this block only needs a small top breathing
  // gap before its first row.
  Widget _buildIdentityBlock() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        SizeConfig.size8,
        20,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final user = _viewCtrl.personalProfileDetails.value.user;
            final name = _capitalizeFirst(user?.name ?? '');
            final username = user?.username ?? '';
            final designation = user?.designation ?? '';
            // Address is rendered in [ProfileLocationCard] now â€” don't
            // duplicate it inside the identity card.
            final email = user?.email ?? '';

            final hasDesignation = designation.trim().isNotEmpty;
            final hasName = name.isNotEmpty;
            final hasUsername = username.isNotEmpty;
            final hasEmail = email.isNotEmpty;
            final hasContact = hasEmail;
            final hasAnyIdentity = hasDesignation || hasName || hasUsername || hasContact;

            // Build children dynamically so empty fields claim
            // zero vertical space â€” no placeholder rows, no
            // dangling spacers.
            final children = <Widget>[];

            if (hasDesignation) {
              children.add(_designationEyebrow(designation));
            }

            if (hasName) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size6));
              }
              children.add(_nameRow(name));
            } else if (hasAnyIdentity) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size8));
              }
              children.add(
                Align(
                  alignment: Alignment.centerRight,
                  child: _editChip(
                    onTap: () => EditProfileBottomSheet.show(Get.context!),
                    label: AppStrings.edit.tr,
                    icon: Icons.edit_outlined,
                  ),
                ),
              );
            }

            if (hasUsername) {
              children.add(const SizedBox(height: 4));
              children.add(_usernameText(username));
            }

            if (hasContact) {
              children.add(SizedBox(height: SizeConfig.size12));
              children.add(Container(
                height: 1,
                color: const Color(0xFFEDEFF4),
              ));
              children.add(SizedBox(height: SizeConfig.size12));
              if (hasEmail) {
                children.add(_infoRow(Icons.alternate_email_rounded, email));
              }
            }

            if (children.isEmpty) {
              return _completeProfileCta();
            }

            return Padding(
              padding: EdgeInsets.only(top: SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _avatarFrame(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                return CommonProfileImage(
                  imagePath: _personalCtrl.imagePath?.value ?? '',
                  onImageUpdate: (image) async {
                    _personalCtrl.imagePath?.value = image;
                    dynamic dataImage = await multiPartImage(imagePath: image);
                    var reqProfile = {ApiKeys.profile_image: dataImage};
                    await _personalCtrl.updateUserProfileDetails(params: reqProfile, isFromProfileOnly: true);
                  },
                  dialogTitle: AppStrings.uploadProfilePicture,
                  showProfileBorder: false,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Joined-date pill rendered on the photo side of the seam â€” small
  // brass-colored badge with a calendar tick. Adds a "membership
  // card" cue without being noisy.
  Widget _memberSincePill() {
    return Obx(() {
      final createdAt = _viewCtrl.personalProfileDetails.value.user?.createdAt ?? '';
      if (createdAt.isEmpty) return const SizedBox.shrink();
      final since = _formatJoinedDate(createdAt);
      if (since.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE4D2A6),
            width: 0.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 12,
              color: const Color(0xFFB7781F),
            ),
            const SizedBox(width: 4),
            Text(
              '${AppStrings.memberShortLabel.tr} · $since',
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B3A00),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    });
  }

  // Designation eyebrow â€” tracked uppercase, primary colored,
  // tappable to open the designation sheet. Skipped entirely when
  // no designation is set.
  Widget _designationEyebrow(String designation) {
    return InkWell(
      onTap: () => showProfileDesignationSheet(Get.context!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 1.5,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: Text(
              designation.toUpperCase(),
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Hero name row with inline Edit chip on the right. Only rendered
  // when the user has a name; otherwise the Edit chip is moved to
  // its own right-aligned row so the affordance is always reachable
  // without reserving an empty name slot.
  Widget _nameRow(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              height: 1.1,
              letterSpacing: -0.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _editChip(
          onTap: () => EditProfileBottomSheet.show(Get.context!),
          label: AppStrings.edit.tr,
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  Widget _usernameText(String username) {
    return Text(
      '@$username',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
        letterSpacing: 0.1,
      ),
    );
  }

  // Empty-profile fallback â€” a single full-width CTA shown when the
  // user has no name, designation, username, location, or email.
  // Replaces the whole identity stack so we don't render a column of
  // empty placeholder rows.
  Widget _completeProfileCta() {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size12),
      child: InkWell(
        onTap: () => EditProfileBottomSheet.show(Get.context!),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Text(
                  AppStrings.completeProfile.tr,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editChip({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Frosted-glass pill used by the cover-edit affordance. Stays
  // legible over any cover photo thanks to a 14-blur backdrop and a
  // soft white border.
  Widget _glassActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ STATS CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Three columns with hero-typed numerals + small captions and a
  // 16-px primary-color accent bar stamped under each value. Whole
  // tile is tappable for Followers / Following so the count and the
  // CTA are the same target.
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20, right: 10),
      child: CustomFormCard(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: Obx(() {
          final followers = _viewCtrl.followersCount.value;
          final following = _viewCtrl.followingCount.value;
          final posts = _viewCtrl.postsCount.value;
          return Row(
            children: [
              Expanded(child: _statTile(label: AppStrings.posts.tr, value: '$posts')),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.followers.tr,
                  value: _formatCount(followers),
                  onTap: () => Get.to(() => FollowersFollowingPage(tabIndex: 1, userID: userId)),
                ),
              ),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.following.tr,
                  value: _formatCount(following),
                  onTap: () => Get.to(() => FollowersFollowingPage(tabIndex: 0, userID: userId)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontFamily: AppConstants.OpenSans,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          letterSpacing: -0.4,
          height: 1.0,
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: tile,
      ),
    );
  }

  Widget _statSeam() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFEDEFF4),
    );
  }

  // â”€â”€â”€ ACTION ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Two equal-width pills: Share (outlined) and Personal Cards
  // (filled primary). Replaces the trio of tiny floating buttons
  // that used to clutter the cover photo.
  Widget _buildActionRow() {
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20, right: 10),
      child: Row(
        children: [
          Expanded(
            child: _actionPill(
              icon: Icons.share_outlined,
              label: AppStrings.shareProfile.tr,
              filled: false,
              onTap: _onShareProfile,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: _actionPill(
              icon: Icons.contact_page_outlined,
              label: AppStrings.personalCards.tr,
              filled: true,
              onTap: () => Get.to(() => AllPersonalVisitingCards(
                    personalDetails: _viewCtrl.personalProfileDetails.value,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : AppColors.primaryColor;
    final bg = filled ? AppColors.primaryColor : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: filled ? 1 : 0.30),
            width: filled ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: filled ? AppColors.primaryColor.withValues(alpha: 0.30) : const Color(0x14001120),
              blurRadius: filled ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onShareProfile() async {
    final userName = _viewCtrl.personalProfileDetails.value.user?.name ?? '';
    await ShareService.instance.shareProfile(userId: userId, subject: userName);
  }

  // Note: the legacy `_buildContactMapCard` + `_contactItem` helpers
  // were retired â€” the address/map flow lives in [ProfileLocationCard]
  // and the bio in [ProfileBioCard]. Website/phone are surfaced via
  // the identity card's edit flow instead of being re-rendered here.

  // â”€â”€â”€ QR CODE CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Reuses [PersonalQrCodeWidget] so the personal QR card looks and
  // behaves the same as the business one (capturable RepaintBoundary,
  // Download to gallery, Share PNG). The wrapper just feeds it the
  // reactive name + designation from the personal profile.
  Widget _buildQrCard() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final name = _capitalizeFirst(user?.name ?? AppStrings.profile.tr);
      final designation = user?.designation ?? '';
      return PersonalQrCodeWidget(
        userId: userId,
        name: name,
        designation: designation,
        margin: const EdgeInsets.only(top: 10, left: 20, right: 10),
      );
    });
  }

  // â”€â”€â”€ SHARE BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Reuses the same [BusinessShareBanner] grocery v2 ships, but
  // passes individual-profile overrides so the banner renders with
  // the user's name, profile photo and designation. Account type is
  // forced to [AppConstants.individual] so the share deep link
  // points at the personal profile route.
  Widget _buildShareBanner() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10),
      child: Obx(() {
        final user = _viewCtrl.personalProfileDetails.value.user;
        final name = _capitalizeFirst(user?.name ?? '');
        final photo = (_personalCtrl.imagePath?.value.trim().isNotEmpty ?? false)
            ? _personalCtrl.imagePath?.value
            : user?.profileImage;
        final designation = user?.designation ?? '';
        return BusinessShareBanner(
          overrideName: name,
          overridePhoto: photo,
          overrideSubCategory: designation,
          accountType: AppConstants.individual,
        );
      }),
    );
  }

  // ============================================================
  // COVER IMAGE EDIT
  // ============================================================

  Future<void> _onCoverImageEdit(BuildContext context) async {
    final String? newPath = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.editCoverPicture,
      cropAspectRatio: CropAspectRatio(width: 3, height: 2),
    );
    if (newPath == null || newPath.isEmpty) return;
    dynamic dataImage = await multiPartImage(imagePath: newPath);
    var reqProfile = {ApiKeys.coverpicture: dataImage};
    await _personalCtrl.updateUserProfileDetails(params: reqProfile, isFromProfileOnly: true);
  }

  // ============================================================
  // TEXT HELPERS
  // ============================================================

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
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
