import 'dart:developer';
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
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/service/rider_auto_golive_scheduler.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen_v2.dart';
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
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
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
  // Hydrates _servicePreference/_submittedPreference from the rider's saved
  // vehicleUsesType once the onboarding status arrives. Guarded so a manual
  // edit isn't clobbered by a later status refresh.
  Worker? _prefWorker;
  bool _prefHydrated = false;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  double? _pickupLat, _pickupLng, _dropLat, _dropLng;

  // ── Pickup location source ─────────────────────────────────────
  // The pickup address can come from either of two sources, chosen via a
  // pair of radio buttons:
  //   • _pickupUseCurrentLocation == true  → device GPS. We resolve the
  //     current coordinates + readable address through LocationController
  //     and surface them read-only.
  //   • _pickupUseCurrentLocation == false → custom address. The Google
  //     Places search field is shown along with an extra free-text field
  //     for the house no. / landmark detail that maps lookups miss.
  // Defaults to current location so the common case is one tap.
  bool _pickupUseCurrentLocation = true;
  bool _fetchingCurrentPickup = false;
  // Extra free-text detail (flat/house no., landmark) for the custom
  // address — captured alongside the resolved pickup coordinates.
  // final TextEditingController _pickupAddressDetailController =
  //     TextEditingController();
  final _locationCtrl = getOrPut(() => LocationController());


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    registerMeTabBackHandler(_tabController);
    _checkRiderStatus();
    // Resume the best-effort daily auto go-live scheduler if the rider opted in
    // on a previous session (10:00–12:00 auto open/close while the app is open;
    // backend cron is authoritative — see the scheduler doc).
    RiderAutoGoLiveScheduler().ensureStartedIfEnabled();
    // Pre-select the rider's saved service preference as soon as the
    // onboarding status loads (and hydrate immediately if it's already there).
    _hydratePreference(controller.riderOnboardingStatusData.value);
    _prefWorker = ever(controller.riderOnboardingStatusData, _hydratePreference);
    _viewCtrl.UserFollowersAndPostsCount(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prefWorker?.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    // _pickupAddressDetailController.dispose();
    // We own the orders SSE stream while this screen is alive — tear it
    // down so the connection isn't leaked once the screen is gone.
    _ordersCtrl.stopStream();
    deleteIfRegistered<DeliveryPartnerController>();
    super.dispose();
  }

  // Status is fetched once in initState. We deliberately do NOT re-fetch on
  // every back-press (the old RouteAware.didPopNext) — that hammered the API.
  // The only return that can change onboarding status is coming back from the
  // deposit-payment flow, which handleGoLiveTap refreshes explicitly. Other
  // changes are covered: in-app mutations self-refresh via forceRefresh, and
  // RiderMeScreen (sharing this controller + reactive riderOnboardingStatusData)
  // refreshes on its own return / app resume, which this screen's Obx reflects.
  void _checkRiderStatus() {
    controller.ridersOnboardingStatusRepoApi();
  }

  // Sets the radio selection + committed value to the rider's saved
  // preference. Runs once (first time a non-empty vehicleUsesType arrives)
  // so it never overwrites a choice the rider is actively editing.
  void _hydratePreference(RiderOnboardingStatusData? data) {
    if (_prefHydrated) return;
    final pref = RiderServicePreference.fromSlug(data?.vehicleUsesType);
    if (pref == null) return;
    _prefHydrated = true;
    if (!mounted) {
      _servicePreference = pref;
      _submittedPreference = pref;
      return;
    }
    setState(() {
      _servicePreference = pref;
      _submittedPreference = pref;
    });
  }

  // BUILD
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
            else ...[
              OrderActionsCarousel(
                onAddCatalog: () => _tabController.animateTo(2),
                catalogIcon: Icons.storefront_rounded,
                catalogTitle: AppStrings.store.tr,
                catalogSubtitle: 'Manage your store',
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
                          label: hasActiveOrders
                              ? AppStrings.order.tr
                              : AppStrings.preferenceTab.tr,
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

  // SET PREFERENCE TAB
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: OrderActionsCarousel(
              onAddCatalog: () => _tabController.animateTo(2),
              catalogIcon: Icons.storefront_rounded,
              catalogTitle: AppStrings.store.tr,
              catalogSubtitle: 'Manage your store',
            ),
          ),
          SizedBox(height: 20,),
          // Red notice shown while the rider is offline (Go Live toggle off).
          // Preferences can still be edited, but they won't receive orders
          // until they go live — surface that up-front above the cards.
          Obx(() {
            if (_viewCtrl.shopStatusOpenClose.value) {
              return const SizedBox.shrink();
            }
            return _buildGoLiveNotice();
          }),
          // Service-preference card only makes sense when the rider actually
          // has a CHOICE (bike riders → Passenger/Goods/Both). For single-
          // preference professions (auto/car → Passenger, goods → Goods) the
          // option is fixed, so the whole card is hidden.
          if (_allowedPreferences.length > 1) ...[
            _buildServicePreferenceCard(),
            SizedBox(height: SizeConfig.size12),
          ],
          _buildPickupDropCard(),
        ],
      ),
    );
  }

  // Red inline banner telling the rider they're offline. Rendered above the
  // Set Preference cards whenever the Go Live toggle is off.
  Widget _buildGoLiveNotice() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.red,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              "Go Live To Receive Orders",
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
              maxLines: 3,
            ),
          ),
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
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: CustomText(
                  AppStrings.servicePreference.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            AppStrings.chooseWhatToDeliver.tr,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          // Segmented selector — the options offered depend on the rider's
          // profession (see [_allowedPreferences]): bike riders get
          // Passenger / Goods / Both; auto & car taxis get Passenger only;
          // goods taxis get Goods only.
          Row(
            children: [
              for (int i = 0; i < _allowedPreferences.length; i++) ...[
                if (i > 0) SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _buildPreferenceSegment(
                    label: _allowedPreferences[i].label,
                    value: _allowedPreferences[i],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          // CTA behaviour:
          //   • Before first submit → "Submit", enabled once an option
          //     is picked.
          //   • After submit → "Update", enabled ONLY when the current
          //     selection differs from the committed one (i.e. the user
          //     chose a different option). When selection == committed,
          //     it is disabled and not clickable (greyed out).
          Obx(() {
            final loading = controller.isRiderPreferenceUpdating.value;
            return CustomBtn(
              title: _submittedPreference != null
                  ? AppStrings.update.tr
                  : AppStrings.submit.tr,
              radius: 10,
              isValidate: ctaEnabled,
              isLoading: loading,
              bgColor:
                  ctaEnabled ? AppColors.primaryColor : AppColors.grey9B,
              onTap: ctaEnabled && !loading
                  ? _onServicePreferenceSubmit
                  : null,
            );
          }),
        ],
      ),
    );
  }

  /// Service-preference options offered for the signed-in rider's profession:
  ///   • BIKE_RIDER      → Passenger / Goods / Both
  ///   • AUTO_TAXI       → Passenger only
  ///   • CAR_TAXI_DRIVER → Passenger only
  ///   • GOODS_TAXI      → Goods only
  /// Any other rider profession falls back to the full set.
  List<RiderServicePreference> get _allowedPreferences {
    switch (userProfessionGlobal) {
      case GOODS_TAXI:
        return const [RiderServicePreference.goods];
      case AUTO_TAXI:
      case CAR_TAXI_DRIVER:
        return const [RiderServicePreference.passenger];
      default:
        // BIKE_RIDER (and any other rider profession) get the full choice.
        return const [
          RiderServicePreference.passenger,
          RiderServicePreference.goods,
          RiderServicePreference.both,
        ];
    }
  }

  // Single selectable segment inside the Service Preference card. Up to three
  // of these sit side-by-side in one row (Passenger / Goods / Both), filtered
  // by the rider's profession. The selected segment fills with the primary
  // tint; when the selection still matches the committed preference it shows a
  // leading check-mark.
  Widget _buildPreferenceSegment({
    required String label,
    required RiderServicePreference value,
  }) {
    final selected = _servicePreference == value;
    // Check-mark shows only while the selected segment still equals the
    // committed value — the moment the user picks a different option every
    // segment drops the tick.
    final showCheck = selected && _servicePreference == _submittedPreference;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _servicePreference = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showCheck) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size4),
            ],
            Flexible(
              child: CustomText(
                label,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
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
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: CustomText(
                  "Drop/Destination Preference",
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            AppStrings.setPreferredPickupDrop.tr,
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
            title: AppStrings.dropLocation.tr,
            hintText: AppStrings.searchDropAddress.tr,
            onSelected: (placeId, lat, lng, address) {
              setState(() {
                _dropController.text = address;
                _dropLat = lat;
                _dropLng = lng;
              });
            },
          ),
          // Pickup only surfaces once a drop is chosen — the pickup section
          // (and the Submit CTA) stay hidden until the rider has picked a
          // drop/destination, so the flow reads drop → pickup → submit.
          if (_dropController.text.trim().isNotEmpty &&
              _dropLat != null &&
              _dropLng != null) ...[
            SizedBox(height: SizeConfig.size12),
            // Pickup — sourced from the device's current location OR a custom
            // searched address, chosen via radio (see _buildPickupLocationSection).
            _buildPickupLocationSection(),
            SizedBox(height: SizeConfig.size16),
            Obx(() {
              final loading = controller.isRiderRouteSubmitting.value;
              return CustomBtn(
                title: AppStrings.submit.tr,
                radius: 10,
                isLoading: loading,
                bgColor: AppColors.primaryColor,
                onTap: loading ? null : _onPickupDropSubmit,
              );
            }),
          ],
        ],
      ),
    );
  }

  // Pickup location source picker — two radio rows + the body that swaps
  // with the selection:
  //   • Current Location → a read-only tile showing the GPS-resolved
  //     address (fetched on selection) with a refresh affordance.
  //   • Custom Address → the Google Places search field plus a free-text
  //     detail field (flat/house no., landmark).
  Widget _buildPickupLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.pickupLocation.tr,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size10),
        Row(
          children: [
            Expanded(
              child: _buildPickupModeRadio(
                label: AppStrings.currentLocation.tr,
                icon: Icons.my_location_rounded,
                isCurrent: true,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: _buildPickupModeRadio(
                label: AppStrings.customAddress.tr,
                icon: Icons.edit_location_alt_outlined,
                isCurrent: false,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size12),
        if (_pickupUseCurrentLocation)
          _buildCurrentLocationTile()
        else
          _buildCustomAddressFields(),
      ],
    );
  }

  // One pickup-mode radio (Current Location / Custom Address). Hand-rolled
  // dot mirrors the service-preference radios for visual consistency.
  Widget _buildPickupModeRadio({
    required String label,
    required IconData icon,
    required bool isCurrent,
  }) {
    final selected = _pickupUseCurrentLocation == isCurrent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_pickupUseCurrentLocation == isCurrent) return;
        setState(() => _pickupUseCurrentLocation = isCurrent);
        // Selecting Current Location auto-fetches the address (unless we
        // already have it). Switching to Custom clears the GPS-sourced
        // value so a stale current address can't leak into a custom pick.
        if (isCurrent) {
          if (_pickupLat == null || _pickupLng == null) {
            _fetchCurrentPickupLocation();
          }
        } else {
          setState(() {
            _pickupController.clear();
            _pickupLat = null;
            _pickupLng = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              size: 18,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                label,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primaryColor : AppColors.grey9B,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check, size: 11, color: AppColors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Read-only tile for the GPS-resolved pickup address. Shows a loader
  // while fetching, the resolved address + coordinates once available, and
  // a tappable "Use current location" prompt otherwise. The whole tile
  // re-fetches on tap so the rider can refresh after moving.
  Widget _buildCurrentLocationTile() {
    final hasAddress = _pickupController.text.trim().isNotEmpty &&
        _pickupLat != null &&
        _pickupLng != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _fetchingCurrentPickup ? null : _fetchCurrentPickupLocation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_fetchingCurrentPickup)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              )
            else
              Icon(
                Icons.my_location_rounded,
                size: 20,
                color: AppColors.primaryColor,
              ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    _fetchingCurrentPickup
                        ? AppStrings.fetchingLocation.tr
                        : (hasAddress
                            ? _pickupController.text
                            : AppStrings.fetchCurrentLocation.tr),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAddress && !_fetchingCurrentPickup) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      '${_pickupLat!.toStringAsFixed(5)}, '
                      '${_pickupLng!.toStringAsFixed(5)}',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ],
              ),
            ),
            if (!_fetchingCurrentPickup) ...[
              SizedBox(width: SizeConfig.size8),
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Custom-address branch: Google Places search (resolves the pickup
  // coordinates) + a free-text detail field for the part maps can't infer.
  Widget _buildCustomAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonLocationSearchField(
          controller: _pickupController,
          title: AppStrings.pickupLocation.tr,
          hintText: AppStrings.searchPickupAddress.tr,
          onSelected: (placeId, lat, lng, address) {
            setState(() {
              _pickupController.text = address;
              _pickupLat = lat;
              _pickupLng = lng;
            });
          },
        ),
        SizedBox(height: SizeConfig.size12),
        // Extra free-text detail (flat/house no., landmark) the autocomplete
        // can't capture — kept separate from the resolved address.
        // CommonTextField(
        //   textEditController: _pickupAddressDetailController,
        //   title: AppStrings.houseNoAndLandMark.tr,
        //   hintText: AppStrings.landmarkHint.tr,
        //   maxLine: 2,
        // ),
      ],
    );
  }

  // Resolves the device's current location (permission → GPS → reverse
  // geocode) and fills the pickup address + coordinates from it. Used by
  // the Current Location radio and the tile's refresh tap.
  Future<void> _fetchCurrentPickupLocation() async {
    setState(() => _fetchingCurrentPickup = true);
    final data = await _locationCtrl.checkPermissionAndSetData();
    if (!mounted) return;
    if (data == null) {
      setState(() => _fetchingCurrentPickup = false);
      commonSnackBar(message: AppStrings.currentLocationUnavailable.tr);
      return;
    }
    setState(() {
      _pickupController.text = data.fullAddress;
      _pickupLat = double.tryParse(data.lat);
      _pickupLng = double.tryParse(data.long);
      _fetchingCurrentPickup = false;
    });
  }

  // â€” Submit handlers â€”
  // These keep the form self-contained; wire them to the rider
  // preference API once that endpoint is available. They deliberately
  // do not touch the existing orders flow.
  Future<void> _onServicePreferenceSubmit() async {
    final selection = _servicePreference;
    if (selection == null) {
      commonSnackBar(message: AppStrings.pleaseSelectServicePreference.tr);
      return;
    }
    // No change since the last commit → nothing to persist. The CTA guard
    // already disables this path, but keep it defensive.
    if (selection == _submittedPreference) return;

    final isUpdate = _submittedPreference != null;
    // Persist the rider's vehicleUsesType — the field the nearby-rider filter
    // keys off (docs/backend/RIDER_PREFERENCE_FILTER.md). Only commit the UI
    // once the backend confirms the save.
    final ok = await controller.updateRiderServicePreference(selection.slugId);
    if (!ok || !mounted) return;
    setState(() {
      _submittedPreference = selection;
      _prefHydrated = true;
    });
    commonSnackBar(
      message: isUpdate
          ? '${AppStrings.servicePreferenceUpdatedTo.tr} ${selection.label}'
          : '${AppStrings.servicePreferenceSavedTo.tr} ${selection.label}',
    );
  }

  // Allowed straight-line gap between pickup and drop. Anything below
  // 500 m or above 20 km is rejected with a validation message.
  static const double _minPickupDropKm = 0.5; // 500 meters
  static const double _maxPickupDropKm = 20.0;

  Future<void> _onPickupDropSubmit() async {
    if (_pickupController.text.trim().isEmpty ||
        _dropController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectPickupDrop.tr);
      return;
    }
    // Coordinates are only set when a place is chosen from the
    // suggestions — without them we can't measure the distance.
    if (_pickupLat == null ||
        _pickupLng == null ||
        _dropLat == null ||
        _dropLng == null) {
      commonSnackBar(message: AppStrings.pickBothFromSuggestions.tr);
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
      commonSnackBar(message: AppStrings.pickupDropTooClose.tr);
      return;
    }
    if (distanceKm > _maxPickupDropKm) {
      commonSnackBar(
          message: '${AppStrings.pickupDropTooFar.tr} '
              '${distanceKm.toStringAsFixed(1)} km.');
      return;
    }
    // Declare this pickup→drop as the rider's active en-route route. Any
    // open order whose pickup AND drop both fall within the corridor (and
    // matching the rider's vehicle-use preference) then becomes claimable.
    // Creating a route supersedes the previous active one.
    final ok = await controller.createRiderRoute(
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      pickupAddress: _pickupController.text.trim(),
      dropLat: _dropLat!,
      dropLng: _dropLng!,
      dropAddress: _dropController.text.trim(),
    );
    if (!ok || !mounted) return;
    commonSnackBar(message: AppStrings.pickupDropPreferenceSaved.tr);
    logs('Route created → ${_pickupController.text} '
        '($_pickupLat, $_pickupLng) '
        'source=${_pickupUseCurrentLocation ? 'current' : 'custom'} '
        'Drop → ${_dropController.text} ($_dropLat, $_dropLng) | '
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

  // Already online → allow toggling offline without re-checking.
  if (_viewCtrl.shopStatusOpenClose.value) {
    _viewCtrl.toggleShopStatus();
    // If they manually go offline inside the auto window, don't let the
    // scheduler re-open them for the rest of today.
    RiderAutoGoLiveScheduler().noteManualOffDuringWindow();
    return;
  }

  // Going live is allowed only for a verified (approved) rider. Otherwise
  // block it and tell them to finish document verification first.
  final riderCtrl = Get.find<DeliveryPartnerController>();
  if (riderCtrl.riderVerificationState != RiderVerificationState.completed) {
    commonSnackBar(
        message:
            'Please complete your document verification before going live.');
    return;
  }

  // After document verification, the security deposit must be paid before
  // going online. This gate applies only to bike riders / cab drivers (the
  // professions that pay a deposit); other roles skip it.
  //
  // FIRST RIDE FREE: the deposit is WAIVED until the rider completes their
  // first ride (backend `freeRideUsed == false`). Once that free ride is used,
  // the deposit is enforced on every subsequent go-live. Absent flag → not
  // free → deposit enforced (safe default).
  final isRiderRole = userProfessionGlobal == BIKE_RIDER ||
      userProfessionGlobal == CAR_TAXI_DRIVER;
  final depositBlocked = isRiderRole &&
      !riderCtrl.isSecurityDepositPaid &&
      !riderCtrl.isFirstRideFree;

  if (depositBlocked) {
    commonSnackBar(
        message:
            'Your payment is incomplete. Please complete the payment process to go live.');
    // Await the deposit flow, then refresh so a freshly-paid deposit is picked
    // up (it's reconciled server-side by a Razorpay webhook with no in-app
    // trigger). This replaces the old RouteAware.didPopNext refresh — it targets
    // the one return that can actually change onboarding status.
    await Get.to(() => const ContributionScreenV2());
    await riderCtrl.ridersOnboardingStatusRepoApi(forceRefresh: true);
    return;
  }

  // Battery optimization is excluded from the gate — see
  // GoLivePermissionService.areRequiredGranted. Gating on it looped the
  // permission screen forever on Android 13+/16.
  if (await GoLivePermissionService.areRequiredGranted()) {
    _viewCtrl.toggleShopStatus();
    // First successful manual go-live opts the rider into the daily 10–12
    // auto window from tomorrow on.
    RiderAutoGoLiveScheduler().enableAfterManualGoLive();
    return;
  }
  final granted = await Get.to(() => const GoLivePermissionScreen());
  if (granted == true) {
    _viewCtrl.toggleShopStatus();
    RiderAutoGoLiveScheduler().enableAfterManualGoLive();
  }
}

// Service-type options for the rider "Set Preference" tab. Each option maps
// to a backend `vehicleUsesType` slug — the field the nearby-rider filter
// keys off (see docs/backend/RIDER_PREFERENCE_FILTER.md):
//   passenger → passenger rides only
//   goods     → delivery (goods) only
//   both      → passenger&delivery
// `labelKey` is an AppStrings key resolved with `.tr` so the radio labels
// and submit confirmation stay localized.
enum RiderServicePreference {
  passenger('passenger', AppStrings.servicePassenger),
  goods('delivery', AppStrings.serviceGoods),
  both('passenger&delivery', AppStrings.serviceBoth);

  const RiderServicePreference(this.slugId, this.labelKey);

  /// Backend `vehicleUsesType` value persisted for this preference.
  final String slugId;

  /// AppStrings key for the human-readable label.
  final String labelKey;

  String get label => labelKey.tr;

  /// Maps a backend `vehicleUsesType` slug back to a UI option so the card
  /// can pre-select the rider's saved choice. `goodsTransport` (a heavy-goods
  /// onboarding type) collapses to the Goods option.
  static RiderServicePreference? fromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    for (final p in RiderServicePreference.values) {
      if (p.slugId == slug) return p;
    }
    if (slug == 'goodsTransport') return RiderServicePreference.goods;
    return null;
  }
}

