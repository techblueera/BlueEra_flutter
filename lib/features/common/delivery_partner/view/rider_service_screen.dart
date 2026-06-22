import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_store_section.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/personal_qrcode_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RiderServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const RiderServiceScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<RiderServiceScreen> createState() => _RiderServiceScreenState();
}

class _RiderServiceScreenState extends State<RiderServiceScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final controller = getOrPut(() => DeliveryPartnerController());
  final _ordersCtrl = getOrPut(() => DeliverPartnerOrdersController());
  final _viewCtrl = getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());

  late final TabController _tabController;

  // Chat was its own top-level tab; it now lives as a sub-tab inside
  // My Order (once verification is approved). _orderSubTab tracks
  // which of the two sub-tabs is active. Rentals are not a tab either
  // â€” they're surfaced as a CTA card inside the Overview tab (see
  // _buildRentalCard), so the top strip stays at four entries.
  static const _orderSubOrders = 0;
  static const _orderSubChat = 1;
  int _orderSubTab = _orderSubOrders;

  // ── "Set Preference" sub-tab state ─────────────────────────────
  // Local UI state backing the new Set Preference form that renders
  // in place of the old orders list (see _buildPreferenceTab). Kept
  // entirely self-contained so it never touches the existing order
  // flow, which stays preserved (commented) in _buildOrderTab.
  //
  // _servicePreference   → current radio selection (null until picked).
  // _submittedPreference → the value committed by Submit/Update. Once
  //   set, its radio shows a check-mark; the CTA becomes "Update" and is
  //   only enabled when the current selection differs from it (i.e. the
  //   user picked another option). When selection == submitted, Update
  //   is disabled/not clickable.
  // _pickup/_dropController + lat/lng → Google-backed address fields.
  RiderServicePreference? _servicePreference;
  RiderServicePreference? _submittedPreference;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  double? _pickupLat, _pickupLng, _dropLat, _dropLng;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkRiderStatus();
    _viewCtrl.UserFollowersAndPostsCount(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _checkRiderStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    // We own the orders SSE stream while this screen is alive — tear it
    // down so the connection isn't leaked once the screen is gone.
    _ordersCtrl.stopStream();
    deleteIfRegistered<DeliveryPartnerController>();
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _checkRiderStatus() {
    controller.ridersOnboardingStatusRepoApi();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  // Scaffold mirrors self-employee v2: glassmorphic top bar, an
  // in-flow tab card, and a sticky tab overlay that engages once
  // the in-flow tabs scroll past the top bar.
  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Tab labels are reactive (first label flips Order/Document with
            // the rider's verification status), so the scaffold is rebuilt
            // inside an Obx.
            Obx(() {
              final approved = controller
                      .riderOnboardingStatusData.value?.verificationStatus ==
                  "approved";
              final tabLabels = <String>[
                approved ? AppStrings.myOrder.tr : AppStrings.document.tr,
                AppStrings.overview.tr,
                AppStrings.post.tr,
                AppStrings.store.tr,
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
                  _tabScroll(_buildPostTab()),
                  _tabScroll(const [EarnStoreCards()]),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TABS â€” solid white card with an animated underline that slides
  // beneath the selected tab. The first tab label flips between
  // "Order" and "Document" depending on verification status, mirroring
  // the original rider screen's behaviour.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // Order / Document tab â€” single source of truth: verification
  // status. Unapproved riders see [RiderProfileStatusScreen] which
  // walks them through KYC / pending-review / rejected on its own
  // surface. Approved riders see a two-pill sub-tab:
  //   â€¢ Orders â€” the delivery-partner orders list.
  //   â€¢ Chat   â€” incoming order inquiries (formerly its own
  //     top-level tab, now relocated here so the top strip stays
  //     compact while inquiries remain one tap from the orders).
  //
  // Both bodies run in `isInParentScroll: true` so their inner
  // Scaffold/Expanded chrome and ListViews collapse into shrink-wrap
  // mode â€” the parent CustomScrollView/Column owns the vertical
  // scroll without needing a bounded height.
  List<Widget> _buildOrderTab() {
    return [
      Obx(() {
        final approved = controller.riderOnboardingStatusData.value?.verificationStatus == "approved";
        if (!approved) return RiderProfileStatusScreen();

        // Once approved, this screen OWNS the single orders SSE stream so
        // the order/preference gate below stays live even while the
        // preference card is showing (DeliveryPartnerOrders defers its
        // stream to us when embedded). fetchStream is idempotent.
        if (!_ordersCtrl.isStreaming) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ordersCtrl.fetchStream();
          });
        }

        // Active order = pending (new) OR ongoing (accepted / in-progress
        // / picked-up …). When one exists the first sub-tab becomes the
        // "Order" screen; once every order is completed or cancelled the
        // rider falls back to the "Preference" screen. Driving both the
        // sub-tab LABEL and the body off this single flag keeps them in
        // sync. Reads reactive lists, so the parent Obx rebuilds on every
        // stream update.
        final hasActiveOrders = _ordersCtrl.newOrders.isNotEmpty ||
            _ordersCtrl.onGoingOrders.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSubTabs(hasActiveOrders),
            SizedBox(height: SizeConfig.size12),
            // First sub-tab is order-aware:
            //   • Active order (pending/in-progress) → EXISTING orders
            //     flow (DeliveryPartnerOrders); label reads "Order".
            //   • No active order (complete/cancel/idle) → "Set
            //     Preference" form; label reads "Preference".
            // The Inquiry sub-tab still shows the chat inquiries list
            // (unchanged).
            if (_orderSubTab == _orderSubOrders)
              _buildPreferenceOrOrders(hasActiveOrders)
            else
              BusinessChatsList(
                isForwardUI: false,
                excludeSenderId: userId,
                isInParentScroll: true,
              ),
          ],
        );
      }),
    ];
  }

  // Gate between the existing orders flow and the Set Preference form,
  // using the [hasActiveOrders] flag computed by the caller so the label
  // and body always agree.
  Widget _buildPreferenceOrOrders(bool hasActiveOrders) {
    if (hasActiveOrders) {
      // EXISTING ORDER FLOW — rendered as-is when an order is active.
      return DeliveryPartnerOrders(isInParentScroll: true);
    }
    return _buildPreferenceTab();
  }

  // Level 2 â€” solid pill segmented control inside My Order.
  // The previous tonal-on-tonal version (primary @ 4% track, @ 14%
  // indicator) disappeared against the dashboard's patterned blue
  // background. This version uses a SOLID white track + a SOLID
  // primary indicator so the control anchors clearly on any
  // backdrop. Still pill-shaped (BorderRadius 100) so it stays
  // distinct from the L1 strip (white card, animated underline)
  // and from the L3 filter (white form field with chevron).
  Widget _buildOrderSubTabs(bool hasActiveOrders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const trackPadding = 4.0;
          final pillWidth = (constraints.maxWidth - trackPadding * 2) / 2;
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
                          color: AppColors.primaryColor.withValues(alpha: 0.32),
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
                        // Label + icon flip with the active-order state:
                        // "Order" while an order is live, "Preference"
                        // when idle/complete/cancelled.
                        child: _subTabButton(
                          icon: hasActiveOrders
                              ? Icons.delivery_dining_rounded
                              : Icons.tune_rounded,
                          label: hasActiveOrders ? 'Order' : 'Preference',
                          index: _orderSubOrders,
                        ),
                      ),
                      Expanded(
                        child: _subTabButton(
                          icon: Icons.question_answer_outlined,
                          label: AppStrings.inquiry.tr,
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
              builder: (_, color, __) => Icon(icon, size: 15, color: color),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.primaryColor : Colors.white,
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SET PREFERENCE TAB
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Two stacked cards rendered for the first ("Preference") sub-tab:
  //   1. Service Preference â€” a radio choice between Passenger,
  //      Goods, or Both, with a Submit button that switches to an
  //      Update affordance once a preference has been saved.
  //   2. Pickup & Drop Preference â€” two Google-backed address search
  //      fields (CommonLocationSearchField) plus a Submit button.
  //
  // Responsive by construction: cards stretch to the available width,
  // all spacing flows from SizeConfig (which already scales for
  // tablet), text uses ellipsis/Flexible, and the CTAs span the full
  // card width so the layout adapts across phone/tablet form factors.
  //
  // This surface only REPLACES the visual of the old orders list for
  // this sub-tab â€” it never mutates the existing orders flow, which is
  // preserved (commented) in _buildOrderTab.
  Widget _buildPreferenceTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServicePreferenceCard(),
          SizedBox(height: SizeConfig.size12),
          _buildPickupDropCard(),
        ],
      ),
    );
  }

  // Card 1 â€” Service Preference (radio + Submit/Update).
  Widget _buildServicePreferenceCard() {
    final isUpdateMode = _submittedPreference != null;
    // Enabled when: first submit needs any selection; updates need the
    // selection to differ from what was already committed.
    final ctaEnabled = isUpdateMode
        ? _servicePreference != _submittedPreference
        : _servicePreference != null;
    return CustomFormCard(
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            'Service Preference',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          const CustomText(
            'Choose what you want to deliver',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          _buildPreferenceRadio(
            label: 'Passenger',
            icon: Icons.person_outline_rounded,
            value: RiderServicePreference.passenger,
          ),
          _buildPreferenceRadio(
            label: 'Goods',
            icon: Icons.inventory_2_outlined,
            value: RiderServicePreference.goods,
          ),
          _buildPreferenceRadio(
            label: 'Both Passenger and Goods',
            icon: Icons.swap_horiz_rounded,
            value: RiderServicePreference.both,
          ),
          SizedBox(height: SizeConfig.size16),
          // CTA behaviour:
          //   • Before first submit → "Submit", enabled once an option
          //     is picked.
          //   • After submit → "Update", enabled ONLY when the current
          //     selection differs from the committed one (i.e. the user
          //     chose a different option). When selection == committed,
          //     it is disabled and not clickable (greyed out).
          CustomBtn(
            title: _submittedPreference != null ? 'Update' : 'Submit',
            radius: 10,
            isValidate: ctaEnabled,
            bgColor: ctaEnabled ? AppColors.primaryColor : AppColors.grey9B,
            onTap: ctaEnabled ? _onServicePreferenceSubmit : null,
          ),
        ],
      ),
    );
  }

  // Single selectable radio row inside the Service Preference card.
  // Uses a hand-rolled radio dot (instead of Radio<T>) so it inherits
  // the card's styling and avoids global RadioTheme overrides.
  Widget _buildPreferenceRadio({
    required String label,
    required IconData icon,
    required RiderServicePreference value,
  }) {
    final selected = _servicePreference == value;
    // Show the check-mark variant only on the currently-selected radio
    // while it still matches the committed preference. The moment the
    // user picks a different option the selection no longer equals the
    // committed value, so every radio falls back to the plain dot.
    final showCheck = selected && _servicePreference == _submittedPreference;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _servicePreference = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                label,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Committed selection → filled circle (holds the tick).
                color: showCheck ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primaryColor : AppColors.grey9B,
                  width: 2,
                ),
              ),
              child: showCheck
                  // Submitted & unchanged → white tick on the filled dot.
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 13,
                        color: AppColors.white,
                      ),
                    )
                  : selected
                      // Selected (not yet committed / changed) → plain dot.
                      ? Center(
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  // Card 2 â€” Pickup & Drop Preference (two address searches + Submit).
  Widget _buildPickupDropCard() {
    return CustomFormCard(
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            'Pickup & Drop Preference',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          const CustomText(
            'Set your preferred pickup and drop locations',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          // Drop â€” Google Places autocomplete. onSelected gives us the
          // resolved address + lat/lng which we cache for submission.
          // Shown first per the desired flow (drop before pickup).
          CommonLocationSearchField(
            controller: _dropController,
            title: 'Drop Location',
            hintText: 'Search drop address',
            onSelected: (placeId, lat, lng, address) {
              setState(() {
                _dropController.text = address;
                _dropLat = lat;
                _dropLng = lng;
              });
            },
          ),
          SizedBox(height: SizeConfig.size12),
          // Pickup â€” same Google-backed search field.
          CommonLocationSearchField(
            controller: _pickupController,
            title: 'Pickup Location',
            hintText: 'Search pickup address',
            onSelected: (placeId, lat, lng, address) {
              setState(() {
                _pickupController.text = address;
                _pickupLat = lat;
                _pickupLng = lng;
              });
            },
          ),
          SizedBox(height: SizeConfig.size16),
          CustomBtn(
            title: 'Submit',
            radius: 10,
            bgColor: AppColors.primaryColor,
            onTap: _onPickupDropSubmit,
          ),
        ],
      ),
    );
  }

  // â€” Submit handlers â€”
  // These keep the form self-contained; wire them to the rider
  // preference API once that endpoint is available. They deliberately
  // do not touch the existing orders flow.
  void _onServicePreferenceSubmit() {
    if (_servicePreference == null) {
      commonSnackBar(message: 'Please select a service preference');
      return;
    }
    final isUpdate = _submittedPreference != null;
    // Commit the selection → its radio now shows the tick and the CTA
    // returns to a disabled "Update" state until the user changes it.
    setState(() => _submittedPreference = _servicePreference);
    commonSnackBar(
      message: isUpdate
          ? 'Service preference updated: ${_servicePreference!.label}'
          : 'Service preference saved: ${_servicePreference!.label}',
    );
    // TODO: persist _servicePreference via the rider preference API.
  }

  // Allowed straight-line gap between pickup and drop. Anything below
  // 500 m or above 20 km is rejected with a validation message.
  static const double _minPickupDropKm = 0.5; // 500 meters
  static const double _maxPickupDropKm = 20.0;

  void _onPickupDropSubmit() {
    if (_pickupController.text.trim().isEmpty ||
        _dropController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please select both pickup and drop locations');
      return;
    }
    // Coordinates are only set when a place is chosen from the
    // suggestions — without them we can't measure the distance.
    if (_pickupLat == null ||
        _pickupLng == null ||
        _dropLat == null ||
        _dropLng == null) {
      commonSnackBar(
          message: 'Please pick both locations from the suggestions');
      return;
    }
    // Distance gate: pickup ↔ drop must be 500 m – 20 km apart.
    final distanceKm = calculateDistanceKm(
      _pickupLat!,
      _pickupLng!,
      _dropLat!,
      _dropLng!,
    );
    if (distanceKm < _minPickupDropKm) {
      commonSnackBar(
          message:
              'Pickup and drop are too close. Minimum distance is 500 meters.');
      return;
    }
    if (distanceKm > _maxPickupDropKm) {
      commonSnackBar(
          message: 'Pickup and drop must be within 20 km. '
              'Current distance is ${distanceKm.toStringAsFixed(1)} km.');
      return;
    }
    commonSnackBar(message: 'Pickup & drop preference saved');
    // TODO: persist pickup/drop via the rider preference API. The
    // resolved coordinates are captured alongside the addresses so the
    // request can send precise lat/lng once the endpoint is wired.
    logs('Pickup pref → ${_pickupController.text} '
        '($_pickupLat, $_pickupLng) | '
        'Drop pref → ${_dropController.text} ($_dropLat, $_dropLng) | '
        'distance=${distanceKm.toStringAsFixed(2)} km');
  }

  // Post tab â€” embeds FeedScreen filtered to the user's posts.
  // Mirrors self-employee v2 so creators see the same CTA + feed
  // treatment across me-section dashboards.
  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      FeedScreen(
        key: const ValueKey('rider_service_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  // Statics tab â€” chat-click analytics, same component grocery /
  // medical / self-employee dashboards use. Riders don't have a
  // separate businessId so the analytics key is the user id.
  List<Widget> _buildStaticsTab() {
    return [
      ProfileStatisticsScreen(userId: userId),
      SizedBox(height: SizeConfig.size12),
      const EarnStatSections(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // OVERVIEW TAB â€” refined editorial identity dossier:
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
                    // Reflect the freshly-picked photo immediately.
                    _personalCtrl.imagePath?.value = image;
                    // Only upload freshly-picked local files; a network UzRL is
                    // an already-saved image and has nothing to re-upload.
                    if (isNetworkImage(image)) return;
                    // Surface every failure: this callback is fire-and-forget
                    // (selectImage doesn't await it), so an un-caught throw or
                    // a bare `return` here is invisible to the user and reads
                    // as "nothing happened after crop".
                    try {
                      if (image.isEmpty || !await File(image).exists()) {
                        commonSnackBar(message: 'Could not read the selected image. Please try again.');
                        return;
                      }
                      final dataImage = await multiPartImage(imagePath: image);
                      if (dataImage == null) {
                        commonSnackBar(message: 'Could not prepare the image for upload.');
                        return;
                      }
                      await _personalCtrl.updateUserProfileDetails(
                        params: {ApiKeys.profile_image: dataImage},
                        isFromProfileOnly: true,
                      );
                    } catch (e) {
                      commonSnackBar(message: 'Profile photo upload failed. Please try again.');
                    }
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
              'Member Â· $since',
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
              Icon(Icons.account_circle_outlined, size: 20, color: AppColors.primaryColor),
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
                  onTap: () => Get.to(() => FollowersFollowingPage(tabIndex: 1, userID: userId)),
                ),
              ),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: 'Following',
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
    // Profile link + share-sheet handoff centralized in ShareService.
    // currentProfileDeepLink() (called inside the service) reads
    // accountTypeGlobal so the rider's business-vs-individual branch
    // no longer needs to live here.
    final userName = _viewCtrl.personalProfileDetails.value.user?.name ?? '';
    await ShareService.instance.shareProfile(userId: userId, subject: userName);
  }

  // Legacy `_buildContactMapCard` + `_contactItem` were retired â€” the
  // address/map flow lives in [ProfileLocationCard] now, the bio in
  // [ProfileBioCard]. Website/phone edit lands through the identity
  // card's edit affordance.

  // â”€â”€â”€ QR CODE CARD (Overview tab) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Delegates to [PersonalQrCodeWidget] so the rider QR card matches
  // the business card's UI and behaviour exactly â€” capturable
  // RepaintBoundary, Download to gallery, Share PNG.
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

Future<void> handleGoLiveTap() async {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();

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

// Service-type options for the rider "Set Preference" tab. Local to this
// screen since the values only drive the preference form's radio group.
// `label` is the human-readable text shown beside each radio and reused
// in the submit confirmation.
enum RiderServicePreference {
  passenger('Passenger'),
  goods('Goods'),
  both('Both Passenger and Goods');

  const RiderServicePreference(this.label);

  final String label;
}

