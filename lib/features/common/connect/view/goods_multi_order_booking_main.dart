import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/get_booking_rider_model.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/goods_multi_broadcast_searching_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/goods_multi_call_tracking_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/passenger_booking_main.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-shop (multi-stop) goods booking — **shop selection and vehicle choice
/// on one screen**.
///
/// This used to be two: `InquiryRideOrderSelectionScreen` ticked the shops and
/// pushed here to price them. Splitting it meant the customer could not change
/// their mind about a shop without backing out and losing the fares, and the
/// second screen's whole first section existed to tell them what they had
/// picked on the first. One screen, one decision surface: tick shops, watch the
/// route and the fares update, book.
///
/// **No map.** It carried pins, a Directions polyline, per-pin bitmap
/// rasterisation and a recentre control, to answer a question the stop list
/// answers in text — and the stop list has the addresses, which the pins never
/// did. The route distance still shows; it comes from the riders response, not
/// from drawing anything.
///
/// Vehicles are **logistics only**. This flow collects orders from shops and
/// delivers them, so a passenger sedan was never a thing anyone could pick;
/// offering one priced a booking the rider could not fulfil.
///
/// Riders + fares come from `POST /fare/multi-shop/riders`
/// ([DiscoverController.resolveAndFindMultiShopRiders]), re-run whenever the
/// shop selection changes. Booking goes out either as a broadcast wave race
/// (`/fare/multi-shop/orders/broadcast`) or as the hand-picked fare-call queue
/// (`/fare/multi-shop/orders`).
class GoodsMultiOrderBookingMain extends StatefulWidget {
  const GoodsMultiOrderBookingMain({super.key, required this.dropAddress});

  /// The drop location chosen in the preceding bottom sheet.
  final SavedAddress dropAddress;

  @override
  State<GoodsMultiOrderBookingMain> createState() =>
      _GoodsMultiOrderBookingMainState();
}

/// One bookable vehicle: what the customer sees, and the backend key that is
/// sent when they pick it.
///
/// The key travels WITH the row rather than being decoded from its index. The
/// old screen kept the two apart, and the index then had to be re-decoded in
/// three separate switches — the fare on the order, the vehicleType on a
/// broadcast, and the rider list in the picker. Four things had to agree; here
/// there is one.
typedef _VehicleOption = ({String key, String name, String asset, String blurb});

class _GoodsMultiOrderBookingMainState
    extends State<GoodsMultiOrderBookingMain> {
  final discoverController = getOrPut(() => DiscoverController());
  final chatViewController = Get.find<ChatViewController>();

  /// Conversation ids the customer has ticked.
  final Set<String> _selectedIds = {};

  /// True while `/fare/multi-shop/riders` is in flight for the current
  /// selection.
  bool _resolving = false;

  /// Collapsed once shops are chosen — the picker is the first job, the fares
  /// are the second, and both fitting on screen at once matters more than
  /// keeping the list open.
  bool _shopsExpanded = true;

  /// **Logistics only.** Passenger classes (`carMini`, `carSedan`, `suvCar`)
  /// are deliberately absent: this books a rider to collect goods from shops.
  ///
  /// Every key here is a field on `VehicleAllResponse` and a value the backend
  /// accepts as `vehicleType` — see [DiscoverController.multiShopVehicleData].
  static const List<_VehicleOption> _vehicles = [
    (
      key: 'twoWheelerRider',
      name: 'Bike',
      asset: AppIconAssets.transport_bike,
      blurb: 'Small, light orders — one or two bags',
    ),
    (
      key: 'autoTempo',
      name: 'Auto',
      asset: AppIconAssets.transport_auto,
      blurb: 'Mid-size loads from a few shops',
    ),
    (
      key: 'pickupGoods',
      name: 'Load Auto',
      asset: AppIconAssets.transport_load_auto,
      blurb: 'Bulk orders, open loading bed',
    ),
    (
      key: 'miniTruckGoods',
      name: 'Mini Truck',
      asset: AppIconAssets.transport_truck,
      blurb: 'Heavy or bulky — many shops in one trip',
    ),
    (
      key: 'largeTruckGoods',
      name: 'Large Truck',
      asset: AppIconAssets.transport_container,
      blurb: 'Full-load runs',
    ),
  ];

  /// Inquiry chats whose last message is within the last 12 hours, newest
  /// first. Shared with the Discover "Orders in 12 Hrs." rail so the two can't
  /// drift on what counts as a recent order.
  List<ChatList> get _recentInquiries => recentInquiryChats(
        chatViewController.getBusinessChatListModel?.value.chatList,
      );

  List<ChatList> get _selectedShops => _recentInquiries
      .where((c) => _selectedIds.contains(c.conversationId))
      .toList();

  @override
  void initState() {
    super.initState();
    // Nothing is selected yet, so there is nothing to price. Clearing here
    // matters because DiscoverController is long-lived: a previous multi-shop
    // booking would otherwise leave its shops and fares on screen under a fresh
    // empty selection.
    discoverController.multiShopSortedShops.clear();
    discoverController.multiShopVehicleType.value = '';
  }

  // ------------------------------------------------------------------ actions

  /// Tick / untick a shop and re-price.
  ///
  /// The riders call runs on every change rather than behind a Submit button:
  /// the fares ARE the feedback for adding a shop, and a customer who adds a
  /// fourth stop wants to see what it costs before committing, not after.
  Future<void> _toggle(String? id) async {
    if (id == null || id.isEmpty) return;
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
    await _resolveRiders();
  }

  /// Re-resolve pickups + riders for the current selection.
  ///
  /// Clearing on an empty selection is not just tidiness: the stop list and the
  /// fares both read the controller, so leaving the previous shops there would
  /// show a route the customer has just emptied.
  Future<void> _resolveRiders() async {
    final shops = _selectedShops;
    if (shops.isEmpty) {
      discoverController.multiShopSortedShops.clear();
      discoverController.multiShopRouteDistanceKm.value = 0;
      discoverController.multiShopVehicleType.value = '';
      if (mounted) setState(() {});
      return;
    }

    setState(() => _resolving = true);
    await discoverController.resolveAndFindMultiShopRiders(
      pickups: shops,
      drop: widget.dropAddress,
    );
    if (!mounted) return;
    setState(() => _resolving = false);
    _ensureVehicleSelection();
  }

  /// Land on the first vehicle the server actually priced.
  ///
  /// Defaulting to a fixed index would sit the selection on a type with no fare
  /// whenever the cheapest class has no riders nearby — the CTA then reads "No
  /// fare for Bike" on arrival, which looks broken rather than informative.
  void _ensureVehicleSelection() {
    final current = discoverController.multiShopVehicleType.value;
    if (current.isNotEmpty &&
        discoverController.multiShopFare(current) != null) {
      return;
    }
    final priced = _vehicles.firstWhere(
      (v) => discoverController.multiShopFare(v.key) != null,
      orElse: () => _vehicles.first,
    );
    discoverController.multiShopVehicleType.value = priced.key;
  }

  Future<void> _onBroadcastToNearbyRiders() async {
    // Register the listeners BEFORE creating the order so a wave that starts
    // immediately isn't missed. `ride:queue:accepted` (the full winner payload)
    // lives on the fare-call listeners, which broadcast reuses.
    discoverController.setupFareCallQueueListeners();
    discoverController.setupMultiShopBroadcastListeners();
    final success = await discoverController.makeMultiShopBroadcastOrder();
    if (success) {
      Get.to(() => GoodsMultiBroadcastSearchingScreen(
            orderId: discoverController.fareCallOrderId.value,
          ));
    }
  }

  Future<void> _onCallToRider() async {
    // Queue listeners before the API call so `ride:queue:calling` isn't missed
    // if the server fires it immediately after creation.
    discoverController.setupFareCallQueueListeners();
    final success = await discoverController.makeMultiShopOrderApi();
    if (success && discoverController.selectedRiders.isNotEmpty) {
      Get.to(() => GoodsMultiCallTrackingScreen(
            orderId: discoverController.fareCallOrderId.value,
          ));
    }
  }

  // -------------------------------------------------------------------- build

  /// Where the vehicle sheet rests, as a fraction of the screen.
  ///
  /// Tuned so two or three priced vehicles are visible without dragging — the
  /// fare comparison is the second half of this screen's job — while the shop
  /// list behind it still shows enough rows to be worth scrolling.
  static const double _sheetRestExtent = 0.46;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: 'Pick Up & Deliver'),
      bottomNavigationBar: _bookingBar(),
      body: SafeArea(
        top: false,
        // Shops BEHIND, vehicles in a sheet over them. The two halves of this
        // screen are "what am I collecting" and "what is carrying it", and they
        // are consulted in that order but changed in either — stacking them
        // keeps both live instead of making the customer scroll one out of
        // sight to reach the other.
        child: Stack(
          children: [
            _backdrop(),
            _vehicleSheet(),
          ],
        ),
      ),
    );
  }

  /// The shop picker, scrolling under the sheet.
  ///
  /// Selection only. The resulting ROUTE lives in the sheet with the vehicles —
  /// the stops and the fares are read together ("four stops, 6 km, what does a
  /// load auto cost for that"), so splitting them across the two layers meant
  /// scrolling the answer out of sight to reach the question.
  Widget _backdrop() {
    return ListView(
      padding: EdgeInsets.only(
        // Clears the sheet at rest, so the last shop can still be scrolled into
        // view rather than being permanently parked underneath it.
        bottom: MediaQuery.of(context).size.height * _sheetRestExtent + 16,
      ),
      children: [
        _dropBanner(),
        _shopsSection(),
      ],
    );
  }

  /// The vehicle chooser, as a draggable sheet with a curved top edge.
  ///
  /// Draggable rather than fixed: five vehicles plus their fares do not fit in
  /// the resting height, and a customer comparing a mini truck against a load
  /// auto should be able to pull the list up without losing the shops.
  Widget _vehicleSheet() {
    return DraggableScrollableSheet(
      initialChildSize: _sheetRestExtent,
      minChildSize: 0.28,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.whiteE5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Pickup stops then the drop, directly above the fares they are
              // being priced for. Collapses to nothing until shops are picked,
              // so an empty sheet opens straight onto the vehicle list.
              Obx(() => _routeSection()),
              Obx(
                () => discoverController.multiShopSortedShops.isEmpty
                    ? const SizedBox.shrink()
                    : const Divider(height: 1, color: AppColors.whiteE5),
              ),
              _vehicleSection(),
              SizedBox(height: SizeConfig.size12),
            ],
          ),
        );
      },
    );
  }

  Widget _dropBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.red00, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Drop location',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  widget.dropAddress.fullAddress.isNotEmpty
                      ? widget.dropAddress.fullAddress
                      : widget.dropAddress.label,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- shop selection

  Widget _shopsSection() {
    final inquiries = _recentInquiries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _shopsExpanded = !_shopsExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    _selectedIds.isEmpty
                        ? 'Select shops to pick up from'
                        : '${_selectedIds.length} shop${_selectedIds.length == 1 ? '' : 's'} selected',
                    fontSize: SizeConfig.size15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                if (_resolving) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _shopsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
        if (_shopsExpanded)
          if (inquiries.isEmpty)
            _emptyState()
          else
            ...inquiries.map(_inquiryRow),
      ],
    );
  }

  Widget _inquiryRow(ChatList chat) {
    final id = chat.conversationId ?? '';
    final isSelected = _selectedIds.contains(id);

    return InkWell(
      onTap: _resolving ? null : () => _toggle(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),
            CachedAvatarWidget(
              imageUrl: chat.sender?.profileImage ?? '',
              size: 42,
              borderRadius: 21,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          chat.sender?.name ?? 'Unknown',
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        _timeAgo(chat.updatedAt ?? chat.createdAt),
                        fontSize: SizeConfig.size10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _orderTypeChip(chat.lastMessageType),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          _lastMessagePreview(chat),
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeChip(String? type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        _orderTypeLabel(type),
        fontSize: SizeConfig.size10,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          CustomText(
            'No active inquiries in the last 12 hours',
            fontSize: SizeConfig.size14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- route

  /// The stops in visit order — farthest shop first, then back towards the
  /// customer. This is what the map used to draw; as text it also carries the
  /// addresses, which the pins never did.
  Widget _routeSection() {
    final shops = discoverController.multiShopSortedShops;
    if (shops.isEmpty) return const SizedBox.shrink();
    final km = discoverController.multiShopRouteDistanceKm.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Route • ${shops.length} stop${shops.length == 1 ? '' : 's'} then you',
                  fontSize: SizeConfig.size15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (km > 0)
                CustomText(
                  '${km.toStringAsFixed(1)} km',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < shops.length; i++)
            _routeStop(
              label: '${i + 1}',
              title: shops[i].name.isNotEmpty ? shops[i].name : 'Pickup ${i + 1}',
              subtitle: shops[i].address,
              color: AppColors.primaryColor,
              isFirst: i == 0,
              isLast: false,
            ),
          _routeStop(
            label: 'You',
            title: widget.dropAddress.label.isNotEmpty
                ? widget.dropAddress.label
                : 'Drop location',
            subtitle: widget.dropAddress.fullAddress,
            color: AppColors.red00,
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _routeStop({
    required String label,
    required String title,
    required String subtitle,
    required Color color,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: isLast
                    ? const Icon(Icons.location_on, size: 14, color: Colors.white)
                    : CustomText(
                        label,
                        fontSize: SizeConfig.size11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.whiteE5)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // The rider starts at the FARTHEST shop and works back,
                      // which is not obvious from a numbered list alone.
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            'Start',
                            fontSize: SizeConfig.size10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- vehicles

  Widget _vehicleSection() {
    return Obx(() {
      // Read inside the Obx so a finished riders call re-prices every row.
      discoverController.ridersDetailsList.value;
      final selectedKey = discoverController.multiShopVehicleType.value;
      final routeKm = discoverController.multiShopRouteDistanceKm.value;
      final hasShops = discoverController.multiShopSortedShops.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Choose a vehicle',
                    fontSize: SizeConfig.size15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                // Says these are goods vehicles without a paragraph — the set
                // is deliberately narrower than the transport flow's, and
                // someone who knows that flow will otherwise wonder where the
                // cab went.
                CustomText(
                  'Logistics',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          if (!hasShops)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: CustomText(
                'Pick at least one shop to see fares.',
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            )
          else
            for (final vehicle in _vehicles)
              _vehicleRow(
                vehicle: vehicle,
                data: discoverController.multiShopVehicleData(vehicle.key),
                isSelected: selectedKey == vehicle.key,
                routeKm: routeKm,
              ),
        ],
      );
    });
  }

  Widget _vehicleRow({
    required _VehicleOption vehicle,
    required VehicleData? data,
    required bool isSelected,
    required double routeKm,
  }) {
    final fare = data?.fare;
    final nearby = data?.users?.length ?? 0;
    // No fare means the server didn't price this type for this route — it stays
    // visible but unbookable rather than silently disappearing, so the customer
    // can see the option exists and simply isn't available here.
    final available = fare != null;

    final meta = <String>[
      nearby > 0 ? '$nearby nearby' : 'No riders nearby',
      if (routeKm > 0) '${routeKm.toStringAsFixed(1)} km route',
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: available
            ? () => discoverController.multiShopVehicleType.value = vehicle.key
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Only the selection is boxed — unselected rows sit flat, so the
            // eye lands on the one that will be booked.
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              width: 1.4,
            ),
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Opacity(
            opacity: available ? 1 : 0.45,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 44,
                  child: LocalAssets(
                    imagePath: vehicle.asset,
                    boxFix: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        vehicle.name,
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          vehicle.blurb,
                          fontSize: SizeConfig.size13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      CustomText(
                        meta,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CustomText(
                  available
                      ? '₹${fare % 1 == 0 ? fare.toInt() : fare.toStringAsFixed(1)}'
                      : '—',
                  fontSize: SizeConfig.size18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- rider picker

  /// Hand-picking a rider is a detour off the main path, not a wall in front of
  /// it: the default booking rings every nearby rider, so this only opens for
  /// someone who wants a specific one.
  void _openRiderPicker() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.whiteE5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _riderHeader(),
              const SizedBox(height: 6),
              Flexible(child: SingleChildScrollView(child: _buildRiderList())),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Obx(
                  () => CustomBtn(
                    height: 48,
                    isLoading: discoverController.bookRiderBtnLoading.value,
                    isValidate: discoverController.selectedRiders.isNotEmpty,
                    onTap: () {
                      if (discoverController.selectedRiders.isEmpty) return;
                      Get.back();
                      _onCallToRider();
                    },
                    title: AppStrings.callToRider.tr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _riderHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.chooseYourRider.tr,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          Obx(() {
            final loading = discoverController.findRiderDetailsLoading.value;
            return InkWell(
              onTap: loading ? null : _resolveRiders,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh,
                            size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                    CustomText(
                      AppStrings.refresh.tr,
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiderList() {
    return Obx(() {
      final status = discoverController.bookingRiderListResponse.value.status;
      final loading = discoverController.findRiderDetailsLoading.value;

      if (loading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (status == Status.COMPLETE) {
        final riders = discoverController
                .multiShopVehicleData(
                    discoverController.multiShopVehicleType.value)
                ?.users ??
            [];

        // Subscribe this Obx to the selection so the rider cards re-render
        // their selected state on tap (RiderCardWidget reads selectedRiders
        // inside its own build, which this Obx wouldn't otherwise track).
        discoverController.selectedRiders.length;

        if (riders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: CustomText(AppStrings.noRidersAvailable.tr)),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children:
                riders.map((rider) => RiderCardWidget(rider: rider)).toList(),
          ),
        );
      }

      if (status == Status.ERROR) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: CustomText(AppStrings.noRidersAvailable.tr)),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: CustomText(AppStrings.loadingRiders.tr)),
      );
    });
  }

  // ------------------------------------------------------------- booking bar

  Widget _bookingBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Obx(() {
            final loading = discoverController.bookRiderBtnLoading.value;
            final key = discoverController.multiShopVehicleType.value;
            final vehicle = _vehicles.firstWhere(
              (v) => v.key == key,
              orElse: () => _vehicles.first,
            );
            final hasShops = discoverController.multiShopSortedShops.isNotEmpty;
            final canBook =
                hasShops && discoverController.multiShopFare(key) != null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _footerAction(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Prepaid',
                          // Payment mode is fixed for multi-shop orders
                          // (`modeOfPayment: 'prepaid'` on create), so this
                          // states it rather than pretending to offer a choice.
                          onTap: null,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.whiteE5),
                      Expanded(
                        child: _footerAction(
                          icon: Icons.person_search_outlined,
                          label: discoverController.selectedRiders.isEmpty
                              ? 'Pick a rider'
                              : '${discoverController.selectedRiders.length} rider selected',
                          onTap: hasShops ? _openRiderPicker : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // One-tap default: broadcast to every nearby rider of the
                // chosen type; the first to accept wins.
                CustomBtn(
                  height: 50,
                  radius: 26,
                  isLoading: loading,
                  isValidate: canBook,
                  onTap: canBook ? _onBroadcastToNearbyRiders : null,
                  title: !hasShops
                      ? 'Select shops to continue'
                      : (canBook
                          ? 'Book ${vehicle.name}'
                          : 'No fare for ${vehicle.name}'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _footerAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.mainTextColor),
            const SizedBox(width: 6),
            Flexible(
              child: CustomText(
                label,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- helpers

  String _lastMessagePreview(ChatList chat) {
    final msg = chat.lastMessage ?? '';
    if (msg.isNotEmpty) return msg;
    return _orderTypeLabel(chat.lastMessageType) == AppStrings.inquiry.tr
        ? AppStrings.newMessage.tr
        : '${_orderTypeLabel(chat.lastMessageType)} order';
  }

  String _orderTypeLabel(String? type) {
    switch (type) {
      case 'food_selfpickup':
        return AppStrings.food.tr;
      case 'homemade_food_selfpickup':
        return AppStrings.homeMadeFood.tr;
      case 'product_selfpickup':
        return AppStrings.product.tr;
      case 'selfpickup':
        return AppStrings.grocery.tr;
      case 'order_request':
      case 'rider':
      case 'rider_map':
      case 'rider_association':
        return AppStrings.order.tr;
      default:
        return AppStrings.inquiry.tr;
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    DateTime dt;
    try {
      dt = DateTime.parse(raw).toLocal();
    } catch (_) {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}
