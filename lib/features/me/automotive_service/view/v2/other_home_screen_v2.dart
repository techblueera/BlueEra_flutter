import 'package:BlueEra/core/services/ads/admob_banner_ad_widget.dart';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_overview_tab_v2.dart';
// import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_posts_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_services_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_stats_tab_v2.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/business_live_photo_bottom_sheet.dart';

/// Automotive-service "me" profile home (v2) — structural twin of the generic
/// `OtherHomeScreenV2` (under `me/others/`). Uses the shared [HomeTabScaffold]
/// (the same Material tab bar grocery / hospital / lab use) and a frosted-glass
/// header so the app-wide themeable background shows through.
class OtherHomeScreenV2 extends StatefulWidget {
  const OtherHomeScreenV2({super.key});

  @override
  State<OtherHomeScreenV2> createState() => _OtherHomeScreenV2State();
}

class _OtherHomeScreenV2State extends State<OtherHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  late final AutomotiveBusinessProfileFullController _otherController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Nullable (not `late final`) so a stale instance left over by a hot reload
  // — whose initState never ran under the new field layout — can't throw a
  // LateInitializationError in dispose/build. Mirrors product_screen.dart.
  TabController? _tabController;

  List<String> get _tabs => [
        AppStrings.services.tr,
        AppStrings.overview.tr,
        // Post tab removed for business accounts. Restore the label together
        // with the `OtherPostsTabV2` view below.
        // AppStrings.posts.tr,
        AppStrings.statics.tr,
      ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    registerMeTabBackHandler(_tabController!);
    _otherController =
        getOrPut(() => AutomotiveBusinessProfileFullController());
    // `viewBusinessProfile()` is called PLAIN, with no "already have it" guard
    // — it is the profile-wide API every Me screen depends on, and the
    // controller coalesces concurrent non-silent callers onto one request.
    // `getBusinessProfileFull()` keeps its guard: that one is the
    // other-service payload and is served from the Hive snapshot.
    //
    // Deferred to post-frame for the same reason as the `me/others` fork this
    // module was copied from: both calls write an `.obs` synchronously before
    // their first await, and doing that from initState marks the bottom bar's
    // `Obx` dirty while the framework is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_otherController.businessProfile.value == null) {
        _otherController.getBusinessProfileFull();
      }
      _businessController.viewBusinessProfile();
    });
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );

    // Deferred to post-frame — the helper reads `ModalRoute.of(context)`,
    // which can't run before initState completes (inherited-widget lookup).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabCtrl = _tabController;
    if (tabCtrl == null) return const SizedBox.shrink();
    return Scaffold(
      // No hardcoded background — inherit the themed scaffold background so the
      // app-wide themeable background (color via the theme, banner via
      // GetMaterialApp.builder; both driven by AppBackgroundController) shows
      // through, same as grocery_home_screen_v2. The frosted-glass top bar lets
      // it through at the header too.
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: tabCtrl,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: MediaQuery.of(context).padding.top + 56,
              tabViews: [
                _tabScroll(withBannerAdBelow(
                  const OtherServicesTabV2(),
                  // This tab scroll has no horizontal padding — the tab insets
                  // itself by size8, so the strip takes the same on both edges
                  // instead of running to the screen edge on the left.
                  margin: bannerAdMarginFor(SizeConfig.size8),
                )),
                _tabScroll(OtherOverviewTabV2(controller: _otherController)),
                // _tabScroll(const OtherPostsTabV2()),
                _tabScroll(const OtherStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh dispatcher — mirrors `GroceryHomeScreenV2`
  /// (`_onRefreshCurrentTab`): each tab owns a different data set, so a pull
  /// fires only the API(s) backing the visible one.
  ///
  /// Overview is index 1 in this module (Services leads), unlike the
  /// `me/others` fork where it leads.
  Future<void> _onRefreshCurrentTab() async {
    // `forceRefresh`: a pull-to-refresh must reach the network. Served from the
    // Hive snapshot it would return instantly having changed nothing, which
    // reads as a broken gesture — and it is the merchant's only way to pick up
    // an edit made on another device.
    if (_tabController?.index != 1) {
      await _otherController.getBusinessProfileFull(forceRefresh: true);
      return;
    }
    // Overview draws from BOTH APIs: the other-service payload backs
    // Management / Gallery / Timings, while the joined-profile card, live
    // photos, contact map, website and QR come from `viewBusinessProfile`, the
    // profile-wide API shared by every Me screen.
    await Future.wait([
      _otherController.getBusinessProfileFull(forceRefresh: true),
      _businessController.viewBusinessProfile(),
    ]);
  }

  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _onRefreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
        child: child,
      ),
    );
  }

  // Frosted-glass header (matches grocery / others) so the app-wide themeable
  // background shows through behind it.
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
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can ellipsize
                // instead of pushing the row past its width.
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                    icon: Icons.notifications_none, onTap: _openNotifications),
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
          child: Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ProfileMenuDrawer()),
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

  /// Drive the Go-Live toggle — a plain on/off switch. With weekly hours saved
  /// it flips today's open/closed state straight from the pill; with no hours
  /// yet it shows the "Set visiting hours" prompt. Hours are set and edited
  /// from the clock button beside the pill.
  Future<void> handleGoLiveTap() async {
    await _businessController.toggleLiveNow();
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: handleGoLiveTap,
        onScheduleTap: _businessController.openScheduleControl,
      ),
    );
  }
}
