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
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/view/v2/tabs/other_overview_tab_v2.dart';
// import 'package:BlueEra/features/me/others/view/v2/tabs/other_posts_tab_v2.dart';
import 'package:BlueEra/features/me/others/view/v2/tabs/other_services_tab_v2.dart';
import 'package:BlueEra/features/me/others/view/v2/tabs/other_stats_tab_v2.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Other-business "me" profile home (v2) — redesigned to mirror the
/// layout used by `HospitalHomeScreenV2` while preserving every action
/// surfaced by the legacy `BusinessProfileFullScreen`. Standalone
/// screen — does NOT touch existing routes or `OthersMain`.
class OtherHomeScreenV2 extends StatefulWidget {
  const OtherHomeScreenV2({super.key});

  @override
  State<OtherHomeScreenV2> createState() => _OtherHomeScreenV2State();
}

class _OtherHomeScreenV2State extends State<OtherHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  late final BusinessProfileFullController _otherController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  late final TabController _tabController;

  // Built as a getter so `.tr` is re-evaluated on locale change rather
  // than frozen at class-load time. `statics` is reused for the Stats
  // tab to stay aligned with self-employee / rider dashboards.
  //
  // Overview leads here, Services second — deliberately the reverse of the
  // other "Me" home screens, and specific to THIS screen. Sibling screens
  // still open on their Order/Inquiry tab with Overview second; the deep-link
  // constant that encodes that (`BottomBarController.meOverviewTabIndex`) is
  // left alone and this screen declares its own index instead — see
  // [_overviewTabIndex] and the `registerMeTabBackHandler` call below.
  List<String> get _tabs => [
        AppStrings.overview.tr,
        AppStrings.services.tr,
        // Post tab removed for business accounts. Restore the label together
        // with the `OtherPostsTabV2` view below.
        // AppStrings.posts.tr,
        AppStrings.statics.tr,
      ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`,
  // `MedicalHomeScreenV2`, `LabHomeScreenV2` and the Order tab in
  // `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  /// Index of the Overview tab in [_tabs] — the tab that owns the live photos,
  /// and therefore the only place the live-photo sheet is asked for.
  ///
  /// 0, not the app-wide default of 1: this screen leads with Overview. It is
  /// handed to `registerMeTabBackHandler` so a deep link to "Me → Overview"
  /// resolves against THIS order instead of assuming the common one.
  static const int _overviewTabIndex = 0;

  /// One sheet per visit: `_tabController` fires twice per swipe (once on the
  /// index change, once when the animation settles) and the merchant can come
  /// back to Overview repeatedly.
  bool _livePhotoSheetAsked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    registerMeTabBackHandler(_tabController,
        overviewTabIndex: _overviewTabIndex);
    // Overview is the tab this screen OPENS on, and a TabController fires no
    // change notification for the tab it starts on — so the listener below
    // would only ever see Overview on a return visit. Ask once the first frame
    // is up instead, which is also late enough for `context` to be usable.
    if (_overviewTabIndex == 0) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeAskForLivePhotos());
    }
    _otherController = getOrPut(() => BusinessProfileFullController());
    // Overview is the tab this screen opens on, so its data has to be asked for
    // HERE — no tab switch is going to do it. Conditional because the bottom bar
    // rebuilds this screen on every visit to the Me tab (`_getScreen` is a plain
    // switch behind a per-index key, not an IndexedStack) while the controller
    // is a `Get.put` singleton that outlives it: without the guard, every tap on
    // Me would refetch. A load that failed leaves the value null, so this still
    // retries on the next visit.
    if (_otherController.businessProfile.value == null) {
      _otherController.getBusinessProfileFull();
    }
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what the other v2 screens
    // (Hospital, School, Medical, Lab) and `professionals_main.dart` do.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  /// Asks for the live-photo sheet when the merchant OPENS Overview.
  ///
  /// It used to fire on the screen's landing (from `OthersMain`), which put a
  /// photo-upload sheet over the Services tab — a tab that is about services,
  /// and whose own blocker is that no service exists. Overview is where the
  /// live photos live, so that is where being asked for them makes sense.
  ///
  /// The sheet keeps its own "already has photos / a sheet is already up"
  /// checks; this only decides WHEN to ask.
  void _onTabChanged() {
    if (_tabController.index != _overviewTabIndex) return;
    _maybeAskForLivePhotos();
  }

  /// Raises the sheet the first time Overview is on screen this visit.
  void _maybeAskForLivePhotos() {
    if (_livePhotoSheetAsked || !mounted) return;
    _livePhotoSheetAsked = true;
    showBusinessLivePhotoBottomSheetIfNeeded(
      context: context,
      controller: _businessController,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: MediaQuery.of(context).padding.top + 56,
              // Order must track [_tabs] exactly — Overview, Services, Stats.
              tabViews: [
                _tabScroll(OtherOverviewTabV2(controller: _otherController)),
                _tabScroll(withBannerAdBelow(
                  const OtherServicesTabV2(),
                  // This tab scroll has no horizontal padding of its own, so
                  // the strip has to state the tab's gutter itself or it runs
                  // to the screen edge. size8 is that gutter, and it is now the
                  // ONLY one in the tab — the empty-state banner used to add 4
                  // on top of it (see `_ServiceRequiredBanner`), which left no
                  // single value the strip could line up with.
                  margin: bannerAdMarginFor(SizeConfig.size8),
                )),
                // _tabScroll(const OtherPostsTabV2()),
                _tabScroll(const OtherStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _otherController.getBusinessProfileFull,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
        child: child,
      ),
    );
  }

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
