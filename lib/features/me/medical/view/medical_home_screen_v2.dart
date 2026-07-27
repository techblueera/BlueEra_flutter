import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_verfication.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical/view/tabs/medical_overview_tab.dart';
import 'package:BlueEra/features/me/medical/view/tabs/medical_post_tab.dart';
import 'package:BlueEra/features/me/medical/view/tabs/medical_products_tab.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Medical Home screen (v2) â€” redesigned to match IMG-3 reference.
class MedicalHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const MedicalHomeScreenV2({super.key, required this.businessId});

  @override
  State<MedicalHomeScreenV2> createState() => _MedicalHomeScreenV2State();
}

class _MedicalHomeScreenV2State extends State<MedicalHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  /// Medical profile powering the Overview tab. Null until that tab is opened
  /// — see [_ensureProfileLoaded].
  MedicalHomeResponseModel? _data;

  /// True while the Overview profile fetch is in flight. Scoped to that tab:
  /// it used to gate the WHOLE screen, so landing on Products showed a
  /// full-screen spinner waiting on data the Products tab never reads.
  bool _isProfileLoading = false;

  /// Whether the profile fetch has already been dispatched for this mount.
  bool _profileRequested = false;

  // Lands on the first tab (Products, index 0) on open.
  late final TabController _tabController;

  late final MedicalGalleryController _galleryController;
  late final MedicalController _medicalController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab â€” same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`
  // and the Order tab in `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` â†’ `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  List<String> _tabs = [
    // AppStrings.orders.tr,
    AppStrings.products.tr,
    AppStrings.overview.tr,
    AppStrings.posts.tr,
    AppStrings.stats.tr,
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabs.length, initialIndex: 0, vsync: this)
          ..addListener(_handleTabChange);
    registerMeTabBackHandler(_tabController);
    _galleryController = Get.put(MedicalGalleryController());
    _medicalController = getOrPut(() => MedicalController());
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what `HospitalHomeScreenV2`,
    // `SchoolHomeScreenV2` and `professionals_main.dart` do.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Fire the API backing the tab the screen LANDS on — Products. The
    // listener only dispatches when the index CHANGES, so without this the
    // landing tab never fetched and its skeletons spun forever; meanwhile the
    // Overview profile call fired here regardless of which tab was showing.
    _fetchForTab(_dispatchedTab);
    // The once-a-day "add your medicines" nudge. Owner-only: this screen is
    // also reachable via RouteConstant.medicalHomeScreen with an arbitrary
    // businessId, and prompting someone to stock a pharmacy that isn't theirs
    // would be nonsense. No livePhotoGate â€” medical never pops the live-photo
    // sheet, so there's nothing to collide with.
    if (widget.businessId == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAddProductPromptIfNeeded(
          context: context,
          spec: const AddProductPromptSpec(
            titleKey: AppStrings.addPromptTitleMedical,
            ctaKey: AppStrings.addProduct,
            icon: Icons.medication_outlined,
          ),
          onAddProduct: () => _tabController.animateTo(0),
        );
      });
    }
  }

  /// Per-tab API dispatcher. Each tab's data is pulled the first time that tab
  /// is opened — including the landing tab, dispatched from `initState` — and
  /// the `*IfNeeded()` guards no-op while data is still loaded and fresh, so
  /// hopping between tabs (or leaving and coming back) doesn't refetch.
  ///
  /// Tabs: 0 Products, 1 Overview, 2 Posts, 3 Stats.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        _ensureProductsLoaded();
        break;
      case 1:
        _ensureProfileLoaded();
        break;
      case 2:
        // Post — FeedScreen owns its own fetch on mount.
        break;
      case 3:
        // Stats — ProfileStatisticsScreen owns its own data.
        break;
    }
  }

  /// Products tab: Top Selling + category-with-inventory, both behind the
  /// controller's freshness guard.
  void _ensureProductsLoaded() {
    // The business-products endpoint keys on the business document's `_id`
    // (the store), NOT the owner's `user_id` — passing the user id returns an
    // empty list. `widget.businessId` here is the user id (MedicalScreen passes
    // it because the profile endpoint deliberately wants the user id), so use
    // the global `businessId` instead — the same store id MedicalController's
    // post-publish refresh already passes to this call.
    _medicalController.fetchMedicalProductsTabDataIfNeeded(
      businessId: businessId,
    );
  }

  /// Overview tab: the medical profile (cover banner, gallery, testimonials,
  /// contact card). Fired the first time Overview is opened rather than on
  /// landing — the screen lands on Products, which reads none of it.
  void _ensureProfileLoaded() {
    if (_profileRequested) return;
    _profileRequested = true;
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isProfileLoading = true);
    try {
      final res = await MedicalRepo()
          .fetchMedicalProfileFd(businessId: widget.businessId);
      if (res.isSuccess && res.response?.data != null) {
        final data = res.response?.data['data'] ?? res.response?.data;
        if (data != null && data is Map<String, dynamic>) {
          setState(() => _data = MedicalHomeResponseModel.fromJson(data));
          _populateGalleryFromResponse(data['gallery']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching medical profile: $e");
    } finally {
      // Let a failed fetch retry the next time Overview is opened rather than
      // leaving the tab permanently empty.
      if (_data == null) _profileRequested = false;
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  void _populateGalleryFromResponse(dynamic galleryJson) {
    if (galleryJson == null || galleryJson is! List || galleryJson.isEmpty) {
      return;
    }
    if (_galleryController.galleryList.isNotEmpty) return;

    try {
      for (final item in galleryJson) {
        if (item is Map<String, dynamic>) {
          final entry = OtherServiceGalleryData.fromJson(item);
          if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty) {
            _galleryController.galleryList.add(entry);
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing gallery from home response: $e");
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Index the dispatcher last fired for. A TabController notifies its
  /// listeners on every animation frame — including throughout a drag, where
  /// `indexIsChanging` stays false — so without this the swipe would dispatch
  /// the same tab's fetch dozens of times, and the `*IfNeeded` guards can't
  /// dedupe calls that all start before the first one has landed.
  int _dispatchedTab = 0;

  /// Fires the newly-opened tab's fetch. Guarded on `indexIsChanging` so a
  /// swipe only dispatches once it settles, not for every tab it passes over.
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_dispatchedTab == _tabController.index) return;
    _dispatchedTab = _tabController.index;
    _fetchForTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Wraps a tab in the scrollable body they all share. The tab classes are
  /// content-only (each returns a bounded Column), and this is the only place
  /// the shared bottom inset is set.
  Widget _tabScroll(Widget tab) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
      child: tab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        // No screen-wide loading gate: the tabs render immediately and each
        // shows its own loading state. Blocking here meant the Products tab
        // (the landing tab) sat behind a spinner for the Overview profile call.
        child: Stack(
                children: [
                  HomeTabScaffold(
                    controller: _tabController,
                    tabLabels: _tabs,
                    topBarHeight: topBarHeight,
                    topBar: Column(
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopBar(),
                        // _buildProfileRow(_data?.businessProfile),
                      ],
                    ),
                    // Top bar (status inset + ~56) + the profile row (~74).
                    // Sized with headroom so the profile row's two text lines
                    // don't overflow the fixed header height (was +120 → 6px
                    // overflow).
                    // topBarHeight: MediaQuery.of(context).padding.top + 132,
                    // One class per tab, each in `view/tabs/` — this screen
                    // owns the chrome (top bar, tab controller, per-tab fetch)
                    // and nothing else. Stats already is its own screen.
                    tabViews: [
                      _tabScroll(
                          MedicalProductsTab(businessId: widget.businessId)),
                      // Overview waits on its OWN fetch rather than the whole
                      // screen doing so; once the profile lands the setState
                      // in [_fetchData] swaps this for the real tab.
                      _tabScroll(
                        _data == null && _isProfileLoading
                            ? const SizedBox(
                                height: 320,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : MedicalOverviewTab(data: _data),
                      ),
                      _tabScroll(const MedicalPostTab()),
                      ProfileStatisticsScreen(userId: userId),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // CREATE OFFERS BUTTON (overview tab)
  // Parked: its call site in the Overview tab is commented out, kept here for
  // when offers ship. Same treatment as _buildVerifyTab below.
  // ignore: unused_element
  Widget _buildCreateOffersButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _onCreateOffer,
          icon: const Icon(Icons.local_offer_outlined,
              size: 18, color: Colors.white),
          label: CustomText(AppStrings.createYourOffers.tr,
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
      ),
    );
  }

  void _onCreateOffer() {
    commonSnackBar(message: AppStrings.comingSoon.tr);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VERIFY TAB â€” shows verification status; tap to start the flow if pending
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ignore: unused_element
  List<Widget> _buildVerifyTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details =
              _businessController.businessProfileDetails.value?.data;
          final isVerified = details?.businessIsVerified ?? false;

          return Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Get.to(ProfileStatisticsScreen(userId: userId));
                    },
                    child: CustomText(AppStrings.clickMe.tr)),
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.gpp_maybe_outlined,
                      color: isVerified ? AppColors.green00 : AppColors.redLite,
                      size: 28,
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CustomText(
                        isVerified
                            ? AppStrings.verifiedProfile.tr
                            : AppStrings.profileNotVerified.tr,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    BusinessVerifyNowButton(details: details),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                CustomText(
                  isVerified
                      ? AppStrings.profileVerifiedHint.tr
                      : AppStrings.profileNotVerifiedHint.tr,
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 4,
                ),
                if (!isVerified) ...[
                  SizedBox(height: SizeConfig.size12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => BusinessVerification()),
                      icon: const Icon(Icons.verified_outlined,
                          size: 18, color: Colors.white),
                      label: CustomText(AppStrings.startVerification.tr,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    // Glassmorphic header — mirrors GroceryHomeScreenV2: a frosted translucent
    // white bar (over the pattern background) with a hairline white border and
    // an outer shadow, instead of the old solid blue gradient.
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

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        onTap: handleGoLiveTap,
      ),
    );
  }

  /// Drive the Go-Live toggle. Turning ON opens the shop-availability
  /// (set-time) form directly — no permission gate. The form persists the
  /// hours and goes live via the backend, popping back `true` on success.
  /// Turning OFF just flips the local toggle.
  Future<void> handleGoLiveTap() async {
    // The pill reflects the schedule-driven auto open/close state; tapping
    // opens the shop-status control — first run routes to the weekly hours
    // editor, thereafter the status sheet (with the today-only override).
    await _businessController.openAvailabilityControl();
  }

  // PROFILE ROW
  // Parked: its call site inside the top bar is commented out.
  // ignore: unused_element
  Widget _buildProfileRow(BusinessProfile? profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Obx(() {
                final logo =
                    _businessController.imagePath?.value ?? profile?.logo ?? '';
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
              // Positioned(
              //   right: -10,
              //   top: 6,
              //   child: Container(
              //     height: SizeConfig.size30,
              //     width: SizeConfig.size30,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: Colors.red.shade600,
              //       border: Border.all(color: Colors.white, width: 2),
              //     ),
              //   ),
              // ),
            ],
          ),
          SizedBox(width: SizeConfig.size20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        profile?.businessName ?? '',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                          fontSize: 11, color: AppColors.secondaryTextColor),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                CustomText(
                  profile?.typeOfBusiness ?? '',
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Obx(() => BusinessVerifyNowButton(
                details: _businessController.businessProfileDetails.value?.data,
              )),
          SizedBox(width: SizeConfig.size10),
          IconButton(
            onPressed: _previewProfileAsVisitor,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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

  /// Opens the Discover-style profile preview so the owner can see the
  /// public profile the way other users discover it on the Discover screen.
  void _previewProfileAsVisitor() {
    final profile = _data?.businessProfile;
    final coverFromCtrl = _businessController.coverImage?.value ?? '';
    final logoFromCtrl = _businessController.imagePath?.value ?? '';

    // Collect gallery image URLs from the gallery controller (same source the
    // overview Gallery section uses).
    final galleryPhotos = <String>[];
    for (final entry in _galleryController.galleryList) {
      galleryPhotos.addAll(entry.imageUrls ?? []);
    }

    final service = ServiceData()
      ..id = profile?.id ?? widget.businessId
      ..name = profile?.businessName
      ..profileImage = (coverFromCtrl.isNotEmpty
          ? coverFromCtrl
          : (logoFromCtrl.isNotEmpty ? logoFromCtrl : (profile?.logo ?? '')))
      ..bio = profile?.businessDescription
      ..address = profile?.address
      ..rating = profile?.avgRating
      ..reviewCount = int.tryParse(profile?.totalRatings ?? '') ?? 0
      ..category = profile?.typeOfBusiness
      ..serviceMedia = ServiceMedia(photos: galleryPhotos);

    Get.to(() => SelfEmployeeViewDiscoverScreen(
          service: service,
          isSelfPreview: true,
        ));
  }
}
