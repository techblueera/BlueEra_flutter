import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/cab_and_transport_partner/view/widgets/cab_transport_orders_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_store_section.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/personal_qrcode_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Cab & Transport Partner dashboard â€” mirrors the self-employee v2 layout
/// so cab/auto/taxi drivers see the same modern shell as riders. Floating
/// glassmorphic top bar, animated tab strip with sticky overlay, and
/// five tab bodies:
///   â€¢ Order / Document â€” single tab whose label flips between
///     "Document" (verification pending) and "My Order" (approved).
///     Body shows [CabsAndTransportPartnerOrders] when approved,
///     otherwise [RiderProfileStatusScreen] handles every other state.
///   â€¢ Chat     â€” incoming order inquiries via [BusinessChatsList] with
///     `excludeSenderId: userId` so the partner only sees conversations
///     awaiting a reply.
///   â€¢ Overview â€” personal profile (cover + identity + stats + actions)
///   â€¢ Post     â€” embedded [FeedScreen] filtered to the user's posts
///   â€¢ Statics  â€” chat-click analytics
class CabAndTransportPartner extends StatefulWidget {
  final bool fromBottomNavBar;

  const CabAndTransportPartner({super.key, this.fromBottomNavBar = false});

  @override
  State<CabAndTransportPartner> createState() => _CabAndTransportPartnerState();
}

class _CabAndTransportPartnerState extends State<CabAndTransportPartner>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());

  late final TabController _tabController;

  // Order/Document share a single tab â€” its label flips between
  // "Document" (KYC pending) and "My Order" (approved), matching
  // RiderServiceScreen's pattern. Chat is no longer a top-level
  // tab; it lives as a sub-tab inside My Order (only once the
  // partner is approved). _orderSubTab tracks which sub-tab is
  // active. Rentals are a CTA card inside the Overview tab (see
  // _buildRentalCard), matching the rider surface.
  static const _orderSubOrders = 0;
  static const _orderSubChat = 1;
  int _orderSubTab = _orderSubOrders;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    registerMeTabBackHandler(_tabController);
    _checkRiderStatus();
    _viewCtrl.UserFollowersAndPostsCount(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() ==
              AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    deleteIfRegistered<EarnServiceController>();
    deleteIfRegistered<DeliveryPartnerController>();
    super.dispose();
  }

  // Status is fetched once in initState. We deliberately do NOT re-fetch on
  // every back-press (the old RouteAware.didPopNext) — that hammered the API.
  // The only return that can change onboarding status is coming back from the
  // deposit-payment flow, which the shared handleGoLiveTap refreshes explicitly.
  // Other changes are covered: in-app step mutations self-refresh via
  // forceRefresh, and RiderMeScreen (sharing this controller + reactive
  // riderOnboardingStatusData) refreshes on its own return / app resume, which
  // this screen's Obx reflects.
  void _checkRiderStatus() {
    deliveryPartnerController.ridersOnboardingStatusRepoApi();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Tab labels are reactive (first label flips Document/My Order
            // with the partner's verification status), so the scaffold is
            // rebuilt inside an Obx.
            Obx(() {
              final approved = deliveryPartnerController
                      .riderOnboardingStatusData.value?.verificationStatus ==
                  "approved";
              final tabLabels = <String>[
                approved ? AppStrings.myOrder.tr : AppStrings.document.tr,
                AppStrings.overview.tr,
                AppStrings.store.tr,
                AppStrings.post.tr,
                AppStrings.statics.tr,
              ];
              return HomeTabScaffold(
                controller: _tabController,
                tabLabels: tabLabels,
                topBar: ProfileTopBar(
                  onGoLiveTap: handleGoLiveTap,
                  showGoLivePill: Platform.isAndroid,
                ),
                topBarHeight: topBarHeight,
                tabViews: [
                  _tabScroll(_buildOrderTab()),
                  _tabScroll(_buildOverviewTab()),
                  _tabScroll(const [EarnStoreCards()]),
                  _tabScroll(_buildPostTab()),
                  _tabScroll(_buildStaticsTab()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Wraps a tab's content list in a scrollable body for the [TabBarView].
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

  List<Widget> _buildOrderTab() {
    return [
      Obx(() {
        final approved = deliveryPartnerController
                .riderOnboardingStatusData.value?.verificationStatus ==
            "approved";
        if (!approved) return RiderProfileStatusScreen();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSubTabs(),
            SizedBox(height: SizeConfig.size12),
            if (_orderSubTab == _orderSubOrders)
              CabsAndTransportPartnerOrders(isInParentScroll: true)
            else ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                child: OrderActionsCarousel(
                  onAddCatalog: () => _tabController.animateTo(2),
                  catalogIcon: Icons.storefront_rounded,
                  catalogTitle: AppStrings.store.tr,
                  catalogSubtitle: 'Manage your store',
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              BusinessChatsList(
                isForwardUI: false,
                excludeSenderId: userId,
                isInParentScroll: true,
              ),
            ],
          ],
        );
      }),
    ];
  }

  // Level 2 â€” solid pill segmented control inside My Order.
  // The previous tonal-on-tonal version (primary @ 4% track, @ 14%
  // indicator) disappeared against the dashboard's patterned blue
  // background. This version uses a SOLID white track + a SOLID
  // primary indicator so the control anchors clearly on any
  // backdrop. Still pill-shaped (BorderRadius 100) so it stays
  // distinct from the L1 strip (white card, animated underline)
  // and from the L3 filter (white form field with chevron).
  Widget _buildOrderSubTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const trackPadding = 4.0;
          final pillWidth =
              (constraints.maxWidth - trackPadding * 2) / 2;
          return Container(
            height: 42,
            padding: const EdgeInsets.all(trackPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.greyE5,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14001120),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sliding primary indicator â€” solid fill, soft
                // primary-tinted drop shadow lifts it forward against
                // the white track. 260ms easeOutCubic glide is the
                // toggle's signature beat.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: pillWidth * _orderSubTab,
                  top: 0,
                  bottom: 0,
                  width: pillWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Positioned.fill makes the Row stretch to the full
                // bounds of the Stack â€” without this the Row sizes
                // to its children's intrinsic height (~20pt) and the
                // Stack's default topStart alignment leaves icon+label
                // hugging the top edge instead of sitting dead-center
                // in the 42pt track.
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: _subTabButton(
                          icon: Icons.receipt_long_rounded,
                          label: 'Orders',
                          index: _orderSubOrders,
                        ),
                      ),
                      Expanded(
                        child: _subTabButton(
                          icon: Icons.question_answer_outlined,
                          label:  AppStrings.inquiry.tr,
                          index: _orderSubChat,
                          // unreadCount: _chatUnreadCount.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _subTabButton({
    required IconData icon,
    required String label,
    required int index,
    int? unreadCount,
  }) {
    final selected = _orderSubTab == index;
    // White text on the solid primary indicator, full-strength main
    // text color on the inactive side â€” both sides stay readable
    // against the white track without needing muted greys.
    final fg = selected ? Colors.white : AppColors.mainTextColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _orderSubTab = index),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 240),
        style: TextStyle(
          fontFamily: AppConstants.OpenSans,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: fg,
          letterSpacing: 0.2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 240),
              tween: ColorTween(end: fg),
              builder: (_, color, __) =>
                  Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount != null && unreadCount > 0) ...[
              const SizedBox(width: 6),
              // Badge inverts against the active indicator: white pill
              // with primary text sits on the primary fill; primary
              // pill with white text sits on the white track. Either
              // side reads cleanly.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color:
                      selected ? Colors.white : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? AppColors.primaryColor
                        : Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      FeedScreen(
        key: const ValueKey('cab_partner_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  List<Widget> _buildStaticsTab() {
    return [
      ProfileStatisticsScreen(userId: userId),
      SizedBox(height: SizeConfig.size12),
      const EarnStatSections(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // OVERVIEW TAB â€” refined editorial identity dossier (mirrors
  // self_employee / social_main / rider_service):
  //   1. Identity card (cover + avatar + identity block).
  //   2. Stats card with hero-typed numerals.
  //   3. Rental services CTA â€” entry point to the rental dashboard.
  //      Used to be its own tab; we collapsed it into Overview so
  //      the tab strip stays uncluttered while the three rental
  //      categories are still one tap away (each chip primes the
  //      destination's filter before pushing).
  //   4. Action row with Share + Personal Cards pills.
  //   5. Contact + map card (bio / website / phone / address / map).
  //   6. QR card with the profile deep link.
  //   7. Share banner.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Widget> _buildOverviewTab() {
    return [
      _buildIdentityCard(context),
      SizedBox(height: SizeConfig.size12),
      _buildStatsCard(),
      SizedBox(height: SizeConfig.size12),
      // Dedicated bio tile lives between identity-level cards and the
      // action/contact rows â€” bio reads as identity content, not
      // secondary detail.
      const ProfileBioCard(),
      SizedBox(height: SizeConfig.size12),
      const RentalPropertyCard(
        margin: EdgeInsets.only(top: 10, left: 20, right: 10),
      ),
      SizedBox(height: SizeConfig.size12),
      _buildActionRow(),
      SizedBox(height: SizeConfig.size12),
      const ProfileLocationCard(),
      SizedBox(height: SizeConfig.size12),
      _buildQrCard(),
      SizedBox(height: SizeConfig.size12),
      _buildShareBanner(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  Widget _buildIdentityCard(BuildContext context) {
    const bannerHeight = 200.0;
    const avatarSize = 88.0;
    const avatarOverlap = avatarSize / 2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
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
                              label:  AppStrings.editCover.tr,
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
                            padding:
                                EdgeInsets.only(bottom: avatarOverlap - 4),
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
            final hasAnyIdentity =
                hasDesignation || hasName || hasUsername || hasContact;

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
                    label: AppStrings.edit,
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
                    dynamic dataImage =
                        await multiPartImage(imagePath: image);
                    var reqProfile = {ApiKeys.profile_image: dataImage};
                    await _personalCtrl.updateUserProfileDetails(
                        params: reqProfile, isFromProfileOnly: true);
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

  Widget _memberSincePill() {
    return Obx(() {
      final createdAt =
          _viewCtrl.personalProfileDetails.value.user?.createdAt ?? '';
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
              'Member · $since',
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
          label: AppStrings.edit,
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
              Icon(Icons.account_circle_outlined,
                  size: 20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.primaryColor),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
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
              Expanded(child: _statTile(label: 'Posts', value: '$posts')),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: 'Followers',
                  value: _formatCount(followers),
                  onTap: () => Get.to(() => FollowersFollowingPage(
                      tabIndex: 1, userID: userId)),
                ),
              ),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: 'Following',
                  value: _formatCount(following),
                  onTap: () => Get.to(() => FollowersFollowingPage(
                      tabIndex: 0, userID: userId)),
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
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: -0.4,
            height: 1.0,
          ),
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
  Widget _buildActionRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
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
            color:
                AppColors.primaryColor.withValues(alpha: filled ? 1 : 0.30),
            width: filled ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: filled
                  ? AppColors.primaryColor.withValues(alpha: 0.30)
                  : const Color(0x14001120),
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
    // Profile link + share-sheet handoff centralized in ShareService.
    // currentProfileDeepLink() (called inside the service) reads
    // accountTypeGlobal so the partner's business-vs-individual branch
    // no longer needs to live here.
    final userName = _viewCtrl.personalProfileDetails.value.user?.name ?? '';
    await ShareService.instance.shareProfile(
        userId: userId,
        subject: userName
    );
  }

  // Legacy `_buildContactMapCard` was retired â€” the address/map flow
  // lives in [ProfileLocationCard] now, the bio in [ProfileBioCard].
  // Website/phone edit lands through the identity card's edit
  // affordance.

  // â”€â”€â”€ QR CODE CARD (Overview tab) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Delegates to [PersonalQrCodeWidget] so the cab/transport partner
  // QR card matches the business card's UI and behaviour exactly â€”
  // capturable RepaintBoundary, Download to gallery, Share PNG.
  Widget _buildQrCard() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final name = _capitalizeFirst(user?.name ?? 'Profile');
      final designation = user?.designation ?? '';
      return PersonalQrCodeWidget(
        userId: userId,
        name: name,
        designation: designation,
        margin: const EdgeInsets.symmetric(horizontal: 14),
      );
    });
  }

  // â”€â”€â”€ SHARE BANNER (Overview tab) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildShareBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Obx(() {
        final user = _viewCtrl.personalProfileDetails.value.user;
        final name = _capitalizeFirst(user?.name ?? '');
        final photo =
            (_personalCtrl.imagePath?.value.trim().isNotEmpty ?? false)
                ? _personalCtrl.imagePath?.value
                : user?.profileImage;
        final designation = user?.designation ?? '';
        return ProfileShareBanner(
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
    await _personalCtrl.updateUserProfileDetails(
        params: reqProfile, isFromProfileOnly: true);
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
