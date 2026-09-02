import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
// Store "Manage your store" CTA + Inquiry chat list removed with the Store /
// Inquiry tabs — Inquiry import kept commented for easy restore.
import 'package:BlueEra/widgets/order_actions_carousel.dart';
// import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_service_preference.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/rider_payment_qr_card.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_tab_scroll.dart';

/// **My Order / Document tab** of the rider dashboard.
///
/// Before verification this is the onboarding form; once approved it is the
/// live orders list plus the "Set Preference" card (service preference +
/// pickup/drop route).
///
/// Stateful because it OWNS that preference form's state — the radio
/// selection, the committed value, the two address fields and their
/// coordinates, and the worker that hydrates them from the rider's saved
/// `vehicleUsesType`. All of it used to live on the dashboard's own State
/// object, where it sat beside the QR card and the feed.
class RiderOrderTab extends StatefulWidget {
  const RiderOrderTab({super.key, required this.onAddCatalog});

  /// Opens the Overview tab. The actions deck's "add catalog" lives here but
  /// its destination is a sibling tab, and this widget has no business knowing
  /// the dashboard's TabController.
  final VoidCallback onAddCatalog;

  @override
  State<RiderOrderTab> createState() => _RiderOrderTabState();
}

class _RiderOrderTabState extends State<RiderOrderTab> {
  final controller = getOrPut(() => DeliveryPartnerController());
  final _ordersCtrl = getOrPut(() => DeliverPartnerOrdersController());
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final _locationCtrl = getOrPut(() => LocationController());

  /// Pre-selected so the card never opens with nothing chosen. "Both" is the
  /// widest option (a rider who takes everything gets the most orders), and it
  /// is only a DEFAULT — [_hydratePreference] overwrites it the moment the
  /// rider's saved `vehicleUsesType` arrives. Falls back to the sole allowed
  /// option for professions that can't take both.
  late RiderServicePreference? _servicePreference = _defaultPreference;

  /// Stays null until something is actually committed — the CTA reads this to
  /// decide "Submit" vs "Update", so the default above must not seed it.
  RiderServicePreference? _submittedPreference;

  RiderServicePreference get _defaultPreference =>
      _allowedPreferences.contains(RiderServicePreference.both)
          ? RiderServicePreference.both
          : _allowedPreferences.first;

  /// Hydrates the two fields above from the rider's saved `vehicleUsesType`
  /// once the onboarding status arrives. Guarded so a manual edit isn't
  /// clobbered by a later status refresh.
  Worker? _prefWorker;
  bool _prefHydrated = false;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  double? _pickupLat, _pickupLng, _dropLat, _dropLng;

  /// The pickup address comes from one of two sources, chosen by a radio pair:
  ///   • true  → device GPS, resolved through [LocationController] and shown
  ///     read-only.
  ///   • false → a custom address: the Places field plus a free-text line for
  ///     the house no. / landmark a map lookup misses.
  /// Defaults to current location so the common case is one tap.
  bool _pickupUseCurrentLocation = true;
  bool _fetchingCurrentPickup = false;

  @override
  void initState() {
    super.initState();
    // Pre-select the rider's saved service preference as soon as the onboarding
    // status loads (and hydrate immediately if it is already there).
    _hydratePreference(controller.riderOnboardingStatusData.value);
    _prefWorker = ever(controller.riderOnboardingStatusData, _hydratePreference);
  }

  @override
  void dispose() {
    _prefWorker?.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Promo strip appended INSIDE the tab's own scroll, so it travels with the
    // content and settles after the last row rather than sitting as a pinned
    // band. This screen passes its tabs to HomeTabScaffold directly (no shared
    // `_tabScroll` helper), so the wrap goes here rather than at the scaffold.
    return RiderTabScroll(
      children: withQurekaPromoBelowAll(
        _buildOrderTab(),
        // The scroll has no horizontal padding; the tab guts itself at size12.
        stripMargin: qurekaStripMarginFor(SizeConfig.size12),
      ),
    );
  }

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

        // Inquiry sub-tab removed — the Preference/Order | Inquiry toggle and
        // the Inquiry (chat inquiries) content are gone, so the order-aware
        // preference/orders content renders directly:
        //   • Active order (pending/in-progress) → EXISTING orders flow
        //     (DeliveryPartnerOrders).
        //   • No active order (complete/cancel/idle) → "Set Preference" form.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actions deck pinned to the top of the Order tab (contribution,
            // bank/UPI, profile, refer & earn), above the order/preference
            // content. Catalog slide routes to the Overview tab since riders
            // have no product/service catalog.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              child: OrderActionsCarousel(
                onAddCatalog: widget.onAddCatalog,
                catalogIcon: Icons.person_outline_rounded,
                catalogTitle: 'Complete Profile',
                catalogSubtitle: 'Manage your details',
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            // _buildOrderSubTabs(hasActiveOrders),
            // SizedBox(height: SizeConfig.size12),
            _buildPreferenceOrOrders(hasActiveOrders),
            // Inquiry sub-tab content removed:
            // BusinessChatsList(isForwardUI: false, excludeSenderId: userId, …)
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
  // Commented out — Inquiry sub-tab removed, so this segmented toggle and its
  // button builder below are unused.

  /*
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
  */

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
      // size12, matching the actions deck above it — this was a literal 14
      // while the deck sat at 12, so the two disagreed by 2pt and the promo
      // strip appended under the tab could line up with only one of them.
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store "Manage your store" CTA removed with the Store tab.
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          //   child: OrderActionsCarousel(
          //     onAddCatalog: () => _tabController.animateTo(2),
          //     catalogIcon: Icons.storefront_rounded,
          //     catalogTitle: AppStrings.store.tr,
          //     catalogSubtitle: 'Manage your store',
          //   ),
          // ),
          // SizedBox(height: 20,),
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
          SizedBox(height: SizeConfig.size12),
          // Payment QR sits last: it isn't needed to receive orders, but it is
          // needed to get PAID at the end of one, and the idle screen is the
          // only moment a rider has to set it up.
          const RiderPaymentQrCard(),
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
      // isBoxShadowAvail: true,
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
          vertical: SizeConfig.size8,
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
            // One icon slot, not two: three segments share a phone width, so a
            // check AND a type glyph would squeeze the label to an ellipsis on
            // small screens. The committed option shows the tick (the label
            // still says which type it is); every other option shows its glyph.
            Icon(
              showCheck ? Icons.check_circle_rounded : value.icon,
              size: 15,
              color: selected ? AppColors.primaryColor : AppColors.grey9B,
            ),
            SizedBox(width: SizeConfig.size6),
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
      // isBoxShadowAvail: true,
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
}
