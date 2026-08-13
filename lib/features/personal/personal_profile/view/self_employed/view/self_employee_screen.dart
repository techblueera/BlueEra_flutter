import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/service/self_work_auto_golive_scheduler.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_work_statistics_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/personal_qrcode_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());

  late final TabController _tabController;

  // Service leads, Overview second. Overview MUST stay at index 1 —
  // [BottomBarController.meOverviewTabIndex] is a hard-coded 1 that deep links
  // (e.g. profile_completion_reminder) use to jump straight to this tab.
  //
  // The Inquiry and Store tabs used to sit here; both were removed along with
  // the requests that backed them (the business chat-list socket emit and the
  // lazy earn-profile fetch). Post is gone too — it embedded the same
  // `PostType.myPosts` feed the Social section's My Post tab now owns.
  //
  // Removing Post kept Overview at index 1, which the deep link above depends
  // on; anything added here must go after Overview, not before it.
  List<String> get _tabs => [
        AppStrings.service.tr,
        AppStrings.overview.tr,
        AppStrings.statics.tr,
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
    // Resume the best-effort daily auto go-live scheduler if the provider opted
    // in on a previous session (08:00–22:00 auto open/close while the app is
    // open — best-effort, foreground only).
    SelfWorkAutoGoLiveScheduler().ensureStartedIfEnabled();
    _viewCtrl.UserFollowersAndPostsCount(userId);
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
              // Frosted rather than the default solid white, so the pinned tab
              // row continues the header's glass instead of cutting a white bar
              // across it — same treatment as the Connect tab strip.
              tabBarColor: Colors.white.withValues(alpha: 0.45),
              topBarHeight: topBarHeight,
              // Order must match [_tabs].
              tabViews: [
                _tabScroll(_buildServiceTab()),
                _tabScroll(_buildOverviewTab()),
                _tabScroll(_buildStaticsTab()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Going live needs background location, battery-optimization, and
  // display-over-other-apps. If any are missing we route through
  // [GoLivePermissionScreen] and only flip the shop status once the
  // user finishes granting them. Turning the shop back off doesn't
  // need any of these checks.
  Future<void> _handleGoLiveTap() async {
    // Already online → allow toggling offline without re-checking.
    if (_viewCtrl.shopStatusOpenClose.value) {
      _viewCtrl.toggleShopStatus();
      // If they manually go offline inside the auto window, don't let the
      // scheduler re-open them for the rest of today.
      SelfWorkAutoGoLiveScheduler().noteManualOffDuringWindow();
      return;
    }

    // The security deposit must be paid before a selfWork provider can go live
    // and receive service enquiries. Source of truth is the individual
    // profile's `securityDeposit` (GET individual profile), exposed via
    // [ViewPersonalDetailsController.canGoLive] — same pattern as the business
    // gate. Fail-open: block ONLY when the backend explicitly reports
    // `required && !paid` (canGoLive == false); a missing / paid / not-required
    // deposit always allows go-live. The backend also enforces this server-side
    // (402 on the go-live PUT). See docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
    //
    // No waivers: the first-service-free exemption is gone, so an active plan
    // or a satisfied deposit is the whole rule — as it already is for riders
    // and businesses.
    final depositBlocked = !AccountPlanEntitlement.to.hasActivePlan.value &&
        !_viewCtrl.canGoLive;
    if (depositBlocked) {
      // Tell the provider why go-live is blocked, then route them to the
      // security-deposit flow to complete payment — go-live stays blocked
      // until it's paid. On return, refresh the profile so a freshly-paid
      // deposit (reconciled server-side by the Razorpay webhook, with no in-app
      // trigger) and the updated `freeServiceUsed` are picked up.
      commonSnackBar(
        message:
            'Your payment is incomplete. Please choose a plan to go live and receive service enquiries.',
      );
      await Get.to(() => const ContributionScreen());
      await _viewCtrl.viewPersonalProfile(forceRefresh: true);
      await AccountPlanEntitlement.to.refresh();
      return;
    }

    // Battery optimization is excluded from the gate — see
    // GoLivePermissionService.areRequiredGranted. Gating on it looped the
    // permission screen forever on Android 13+/16.
    if (await GoLivePermissionService.areRequiredGranted()) {
      _viewCtrl.toggleShopStatus();
      // First successful manual go-live opts the provider into the daily
      // 8 AM–10 PM auto window from tomorrow on.
      SelfWorkAutoGoLiveScheduler().enableAfterManualGoLive();
      return;
    }
    final granted = await Get.to(() => const GoLivePermissionScreen());
    if (granted == true) {
      _viewCtrl.toggleShopStatus();
      SelfWorkAutoGoLiveScheduler().enableAfterManualGoLive();
    }
  }


  // TABS â€” solid white card with an animated underline that slides
  // beneath the selected tab.
  /// Wraps a tab's content list in a scrollable body for the [TabBarView].
  /// The per-tab builders return bounded box widgets, so SingleChildScrollView
  /// + Column reproduces the previous SliverToBoxAdapter + Column layout.
  Widget _tabScroll(Widget child) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + 30,
      ),
      child: child,
    );
  }

  // the parent CustomScrollView so its sections share the page's
  // scroll. That lets the sticky-tab overlay engage when the user
  // scrolls past the top bar (matches the Post tab's behavior).
  Widget _buildServiceTab() {
    return const SelfProfessionServiceScreen();
  }

  // STATICS TAB — a purpose-built skilled-worker dashboard.
  //
  // This used to be the generic [ProfileStatisticsScreen] (chat clicks +
  // profile visits) that every profile type shared, stacked with
  // [EarnStatSections] (per-earn-flavour "coming soon" placeholders for home
  // made food / products / services). Both are gone: those two numbers
  // describe a *page*, and a self-employed account is a *trade* — an
  // electrician, plumber, tutor or gardener wants earnings, the enquiry
  // funnel, which of their services pay, their ratings, and how they stack up
  // against others in the same trade nearby.
  //
  // [SelfWorkStatisticsView] owns all of that. It currently renders sample
  // data behind SelfWorkStatisticsController.useSampleData because
  // `earn-service/self-work/statistics` is not built yet — the contract we
  // designed against is in docs/backend/SELF_WORK_STATISTICS_API_GUIDE.md.
  Widget _buildStaticsTab() {
    return const SelfWorkStatisticsView();
  }

  // OVERVIEW TAB â€” refined editorial identity dossier:
  //   1. Single hero card unifying the cover banner, the avatar
  //      (straddling the photo/sheet boundary), and the identity
  //      block (designation eyebrow â†’ name â†’ username Â· member-since
  //      â†’ location/email rows). Hairline divides photo from sheet.
  //   2. Stats card with hero-typed numerals and primary-color
  //      accent bars stamped beneath each metric.
  //   3. Action row with explicit Share + Business-Card pills.
  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: Obx(() => WebsiteOverviewCard(
            websiteUrl: _viewCtrl.website.value,
            onSave: (url) => _personalCtrl.updateUserProfileDetails(
              params: {ApiKeys.website: url},
              isFromProfileOnly: true,
            ),
          )),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
          child: const ProfileLocationCard(margin: EdgeInsets.zero),
        ),
        _buildQrCard(),
        _buildShareBanner(),
        SizedBox(height: SizeConfig.size16),
      ],
    );
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
  // Reuses the same [ProfileShareBanner] grocery v2 ships, but
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
        return ProfileShareBanner(
          overrideName: name,
          overridePhoto: photo,
          overrideSubCategory: designation,
          accountType: AppConstants.individual,
          referralCode: user?.referral_code,
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

