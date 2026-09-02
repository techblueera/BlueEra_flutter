import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/features/me/content_creator/view/content_creator_overview_tab.dart';
import 'package:BlueEra/features/me/content_creator/widget/content_creator_channel_tab.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_store_section.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Content-creator dashboard — a self-contained "me" screen with six tabs:
///   • Order    — add-channel action + business-chat inquiry list
///   • Overview — creator overview (placeholder for now)
///   • Channel  — creator channel (placeholder for now)
///   • Store    — earn store cards
///   • Post     — embedded [FeedScreen] filtered to the user's posts
///   • Statics  — chat-click analytics + earn stats
///
/// Order / Store / Post / Statics mirror the professionals dashboard by reusing
/// the same SHARED widgets — this screen imports nothing from
/// `professionals_consultant`, so it can diverge freely.
class ContentCreatorMainScreen extends StatefulWidget {
  const ContentCreatorMainScreen({super.key});

  @override
  State<ContentCreatorMainScreen> createState() =>
      _ContentCreatorMainScreenState();
}

class _ContentCreatorMainScreenState extends State<ContentCreatorMainScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  // Drives the inquiry list on the Order tab — same controller the Connect
  // screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Backs the Overview tab — loads the creator's own earn-artist profile.
  final EarnArtistController _earnArtistController =
      getOrPut(() => EarnArtistController());

  late final TabController _tabController;

  /// Tabs whose data has already been loaded — each tab fetches lazily the first
  /// time it becomes active, so e.g. the earn-artist profile isn't fetched or
  /// created until the Overview tab is actually opened.
  final Set<int> _loadedTabs = {};

  List<String> get _tabs => [
        AppStrings.order.tr,
        AppStrings.overview.tr,
        AppStrings.channel.tr,
        AppStrings.store.tr,
        AppStrings.post.tr,
        AppStrings.statistics.tr,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: 0,
      vsync: this,
    );
    registerMeTabBackHandler(_tabController);
    // Register the personal-profile controller up front so the Overview tab's
    // identity card can drive cover/avatar edits from a shared instance.
    getOrPut(() => PersonalCreateProfileController());
    _viewCtrl.UserFollowersAndPostsCount(userId);
    // Load per-tab data lazily on first activation instead of all up front.
    _tabController.addListener(_onTabChanged);
    _loadTabData(_tabController.index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() ==
              AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Fires each tab's data load the first time it settles on that tab.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadTabData(_tabController.index);
  }

  /// Loads the data a tab needs, once. Order (0) hydrates the business-chat
  /// inquiry list; Overview (1) loads/creates the earn-artist profile. Other
  /// tabs manage their own data, so they have no entry here.
  void _loadTabData(int index) {
    if (!_loadedTabs.add(index)) return; // already loaded
    switch (index) {
      case 0:
        _chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
        break;
      case 1:
        _earnArtistController.ensureArtistProfile(
            type: userProfessionGlobal, category: userDesignationGlobal);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll(withQurekaPromoBelowAll(
                  _buildOrderTab(),
                  stripMargin: qurekaStripMarginFor(SizeConfig.size12),
                )),
                _tabScroll(const [ContentCreatorOverviewTab()]),
                _tabScroll(const [ContentCreatorChannelTab()]),
                _tabScroll(const [EarnStoreCards()]),
                _tabScroll(_buildPostTab()),
                _tabScroll(_buildStaticsTab()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────
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
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: Row(
              children: [
                _circleIconButton(
                  icon: Icons.menu,
                  onTap: () => _openDrawer(context),
                ),
                SizedBox(width: SizeConfig.size6),
                // Expanded + left Align fills the row so the notification lands
                // flush right, while the refer pill stays compact on the left.
                // No shadow here — the shadow flag is on only in the social
                // header.
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ReferEarnPill(),
                  ),
                ),
                SizedBox(width: SizeConfig.size6),
                if (!isGuestUser()) ...[
                  SizedBox(width: SizeConfig.size6),
                  _circleIconButton(
                    icon: Icons.notifications_none,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteHelper.getNotificationScreenRoute(),
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

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
                border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }

  /// Wraps a tab's content list in a scrollable body for the tab view.
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

  // ─── ORDER TAB ───────────────────────────────────────────────────────────
  List<Widget> _buildOrderTab() {
    return [
      SizedBox(height: SizeConfig.size10),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: OrderActionsCarousel(
          onAddCatalog: () => _tabController.animateTo(2), // Channel tab
          catalogIcon: Icons.video_library_rounded,
          catalogTitle: AppStrings.setUpChannel.tr,
          catalogSubtitle: AppStrings.buildCreatorChannel.tr,
        ),
      ),
      SizedBox(height: SizeConfig.size16),
      BusinessChatsList(
        isForwardUI: false,
        excludeSenderId: userId,
        isInParentScroll: true,
        listTitle: AppStrings.inquiry,
      ),
    ];
  }

  // ─── POST TAB ────────────────────────────────────────────────────────────
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
        key: const ValueKey('content_creator_my_posts'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        vertical: SizeConfig.size10, horizontal: SizeConfig.size4),
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

  // ─── STATICS TAB ─────────────────────────────────────────────────────────
  List<Widget> _buildStaticsTab() {
    return [
      ProfileStatisticsScreen(userId: userId),
      SizedBox(height: SizeConfig.size12),
      const EarnStatSections(),
      SizedBox(height: SizeConfig.size16),
    ];
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
