import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/get_booking_rider_model.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/goods_multi_broadcast_searching_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/goods_multi_call_tracking_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/passenger_booking_main.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/route_polyline_service.dart';
import 'package:BlueEra/core/map/osrm_routing.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// Multi-shop (multi-stop) ride booking screen.
///
/// Map-first: every pickup shop is pinned in the order the rider will visit
/// them (1 = farthest = route start) with the customer's own drop pinned as
/// "You", and the booking controls live in a sheet over it. The route is the
/// thing being priced here — a list of addresses never showed how far apart
/// four shops actually are, which is exactly what the customer is paying for.
///
/// Data comes from `POST /fare/multi-shop/riders` (fired by
/// [InquiryRideOrderSelectionScreen] before this screen opens, so
/// [DiscoverController] already holds the sorted shops + riders on build).
/// Booking goes out either as a broadcast wave race
/// (`/fare/multi-shop/orders/broadcast`) or as the hand-picked fare-call queue
/// (`/fare/multi-shop/orders`, see [FareCallQueueScreen]).
class GoodsMultiOrderBookingMain extends StatefulWidget {
  const GoodsMultiOrderBookingMain({
    super.key,
    required this.pickups,
    required this.dropAddress,
  });

  /// Selected inquiry conversations used as pickup points (pre-resolution).
  final List<ChatList> pickups;

  /// The already-selected drop location.
  final SavedAddress dropAddress;

  @override
  State<GoodsMultiOrderBookingMain> createState() =>
      _GoodsMultiOrderBookingMainState();
}

class _GoodsMultiOrderBookingMainState
    extends State<GoodsMultiOrderBookingMain> {
  final discoverController = getOrPut(() => DiscoverController());

  BlueMapController? _mapController;

  // Replaced wholesale on every rebuild, never mutated in place: BlueMap diffs
  // the new list against the drawn one to decide what to redraw.
  List<BlueMapMarker> _markers = const [];
  List<BlueMapPolyline> _polylines = const [];

  /// Rebuilds the pins whenever the sorted-shop list changes (first load and
  /// every refresh).
  Worker? _shopsWorker;

  /// Driving geometry through every stop, once Directions has answered.
  List<LatLng> _roadRoute = const [];

  /// Coordinates the current [_roadRoute] was fetched for, so a refresh that
  /// returns the same stops doesn't re-request it.
  String? _routeSignature;

  /// The stop list under the summary row starts OPEN: arriving here, the first
  /// thing to check is that the pickup shops and the drop are the right ones —
  /// map pins show where they are but not their addresses. It collapses on tap
  /// once the customer has read them and wants the room for fares.
  bool _stopsExpanded = true;

  /// Bhopal — a sane frame until the shops resolve, so the map never opens on
  /// the null island.
  static const LatLng _fallbackCenter = LatLng(23.2599, 77.4126);

  /// Pin diameter in LOGICAL pixels (dp) — in the same range as a stock Google
  /// marker, and small enough that adjacent shops stay separate pins instead
  /// of merging into one blob.
  static const double _kPinDiameter = 30;

  /// Where the sheet rests: tall enough that all four priced vehicles are
  /// visible without dragging, since comparing them is the job of this screen.
  /// The map's bottom padding and the recentre button track this, so pins are
  /// never framed underneath the sheet.
  static const double _sheetRestExtent = 0.52;

  // In-City vehicle choices (same set / order as the transport flow, so the
  // shared `getSelectedVehicleData(response, 0, index)` mapping applies).
  List<TransportCategoryDetailsModel> get optionList => [
        TransportCategoryDetailsModel(
            name: AppStrings.transportBike.tr,
            svgImage: AppIconAssets.transport_bike),
        TransportCategoryDetailsModel(
            name: AppStrings.transportTaxi.tr,
            svgImage: AppIconAssets.transport_taxi),
        TransportCategoryDetailsModel(
            name: AppStrings.transportAuto.tr,
            svgImage: AppIconAssets.transport_auto),
        TransportCategoryDetailsModel(
            name: AppStrings.transportERickshaw.tr,
            svgImage: AppIconAssets.transport_big_auto),
      ];

  /// One line of "what is this vehicle for", shown under the name on the
  /// selected row. Load-shape rather than ride-comfort copy: this flow is
  /// collecting goods from several shops, so what the customer is choosing
  /// between is how much fits.
  static const List<String> _vehicleBlurbs = [
    'Best for small, light orders',
    'Roomy — bulk orders with boot space',
    'Good for mid-size loads',
    'Budget option for short routes',
  ];

  @override
  void initState() {
    super.initState();
    _shopsWorker =
        ever(discoverController.multiShopSortedShops, (_) => _rebuildMap());
    // The riders call may already have resolved before this screen mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildMap());
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload keeps this State alive, so neither initState's post-frame
    // build nor the shops worker fires — the map keeps whatever marker set it
    // was given, with the bitmaps it was given. Editing the pins then looks
    // like it changed nothing until a full restart. Debug-only (Flutter never
    // calls reassemble in release).
    // Pins are widgets now — a hot reload rebuilds them like any other widget.
    _rebuildMap();
  }

  @override
  void dispose() {
    _shopsWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------- map

  /// Pickups in visit order followed by the drop — the sequence the pins,
  /// the connector line and the collapsed stop list all read from.
  List<_Stop> get _stops {
    final shops = discoverController.multiShopSortedShops;
    final stops = <_Stop>[
      for (var i = 0; i < shops.length; i++)
        _Stop(
          label: '${i + 1}',
          title: shops[i].name.isNotEmpty ? shops[i].name : 'Pickup ${i + 1}',
          subtitle: shops[i].address,
          position: LatLng(shops[i].latitude, shops[i].longitude),
          color: AppColors.primaryColor,
          isDrop: false,
        ),
    ];
    stops.add(
      _Stop(
        label: 'You',
        title: widget.dropAddress.label.isNotEmpty
            ? widget.dropAddress.label
            : 'Drop location',
        subtitle: widget.dropAddress.fullAddress,
        position: LatLng(
          widget.dropAddress.lat ?? 0,
          widget.dropAddress.lng ?? 0,
        ),
        color: AppColors.red00,
        isDrop: true,
      ),
    );
    // A stop the geocoder never resolved would drag the camera to (0,0) and
    // make every real pin invisible.
    return stops.where((s) => s.hasPosition).toList();
  }

  Future<void> _rebuildMap() async {
    final stops = _stops;
    if (stops.isEmpty || !mounted) return;

    final markers = <BlueMapMarker>[
      for (final stop in stops)
        BlueMapMarker(
          id: 'stop_${stop.label}',
          position: stop.position,
          child: _circlePin(
            label: stop.isDrop ? null : stop.label,
            icon: stop.isDrop ? Icons.person : null,
            color: stop.color,
          ),
          // Anchored at the pin's tail, not its centre, so the point of the
          // pin sits on the coordinate.
          anchor: BlueMarkerAnchor.bottom,
        ),
    ];

    if (!mounted) return;
    setState(() {
      _markers = markers;
      _polylines = _buildPolylines(stops);
    });
    _fitStops();
    // Straight lines are on screen already; swap in the real roads as soon as
    // Directions answers.
    unawaited(_loadRoadRoute(stops));
  }

  /// The route line. Uses the real driving geometry once [_loadRoadRoute] has
  /// it, and a straight connector until then.
  List<BlueMapPolyline> _buildPolylines(List<_Stop> stops) {
    final onRoads = _roadRoute.isNotEmpty;
    final points = onRoads ? _roadRoute : stops.map((s) => s.position).toList();
    if (points.length < 2) return const [];

    return [
      BlueMapPolyline(
        id: 'route',
        points: points,
        color: AppColors.primaryColor,
        width: 5,
        // White casing, so the line stays readable over roads and parks alike.
        // One bordered line rather than two stacked ones: the plugin draws the
        // casing natively, so the two can never disagree about geometry.
        borderColor: Colors.white,
        borderWidth: 2.5,
        // Solid once it follows the roads, because then it IS the path the
        // rider drives. While it is still the straight placeholder it stays
        // dotted — a solid straight line would claim a route through the
        // buildings between two shops.
        isDotted: !onRoads,
      ),
    ];
  }

  /// Fetch the driving geometry through every stop in order.
  ///
  /// One Directions call with the intermediate shops as waypoints, so the line
  /// follows the same road order the rider will actually drive (farthest shop
  /// → … → nearest → you) rather than a straight hop per leg.
  ///
  /// Guarded by a coordinate signature: [_rebuildMap] runs on every riders
  /// refresh, and re-requesting an unchanged route would just spend quota.
  /// Failure is silent — the straight connector stays, which is a worse map
  /// but never a blank one.
  Future<void> _loadRoadRoute(List<_Stop> stops) async {
    if (stops.length < 2) return;
    final signature = stops
        .map((s) => '${s.position.latitude},${s.position.longitude}')
        .join('|');
    if (signature == _routeSignature) return;
    _routeSignature = signature;

    try {
      final result = await RoutePolylineService.fetch(
        origin: PointLatLng(
            stops.first.position.latitude, stops.first.position.longitude),
        destination: PointLatLng(
            stops.last.position.latitude, stops.last.position.longitude),
        wayPoints: [
          for (final stop in stops.sublist(1, stops.length - 1))
            PolylineWayPoint(
              location: '${stop.position.latitude},${stop.position.longitude}',
            ),
        ],
      );
      // Null = throttled or failed. Clear the signature so the next refresh
      // retries rather than treating this leg as already drawn.
      if (result == null) {
        _routeSignature = null;
        return;
      }
      if (!mounted || result.points.length < 2) return;
      _roadRoute =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      setState(() => _polylines = _buildPolylines(stops));
    } catch (_) {
      // Keep the straight hint — a missing route must never blank the map.
      _routeSignature = null; // let the next refresh retry
    }
  }

  /// Frame every stop. Called on data changes and from the recentre button.
  Future<void> _fitStops() async {
    final map = _mapController;
    final stops = _stops;
    if (map == null || stops.isEmpty) return;

    if (stops.length == 1) {
      await map.moveTo(stops.first.position, zoom: 15);
      return;
    }

    // The hand-rolled min/max sweep this used to do now lives in
    // LatLngBounds.containing, behind fitPoints.
    await map.fitPoints(stops.map((s) => s.position), padding: 64);
  }

  /// A compact circular map pin: white ring, coloured disc, and either the
  /// stop's visit number or a glyph inside.
  ///
  /// Sized so several can sit close together without covering the streets
  /// between the shops.
  ///
  /// Numbered rather than identical dots because the ORDER is the information:
  /// the rider starts at the farthest shop and works back, and a customer
  /// checking the fare wants to see that path.
  ///
  /// This used to rasterise onto a ui.Canvas, with a cache and a devicePixelRatio
  /// threaded through it, purely because the map would only accept bitmaps and
  /// `BitmapDescriptor.bytes` measures in physical pixels. Marker children are
  /// widgets now, so the pin is laid out in logical pixels like everything else
  /// and none of that machinery is needed.
  Widget _circlePin({
    String? label,
    IconData? icon,
    required Color color,
  }) {
    return SizedBox(
      width: _kPinDiameter,
      height: _kPinDiameter + 7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _kPinDiameter,
            height: _kPinDiameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: _kPinDiameter * 0.5)
                : Text(
                    label ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: _kPinDiameter * 0.42,
                    ),
                  ),
          ),
          // Tail, so the pin points at its coordinate.
          CustomPaint(
            size: const Size(9, 7),
            painter: _PinTailPainter(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ actions

  /// Re-runs the multi-shop riders search with the same pickups + drop so the
  /// user can pull the latest nearby riders without leaving the screen. Reuses
  /// [DiscoverController.resolveAndFindMultiShopRiders], which clears the
  /// previous selection and refreshes the route, vehicle fares and rider list.
  Future<void> _onRefreshRiders() async {
    if (discoverController.findRiderDetailsLoading.value) return;
    await discoverController.resolveAndFindMultiShopRiders(
      pickups: widget.pickups,
      drop: widget.dropAddress,
    );
  }

  /// Broadcast (wave race) booking — no rider is picked. Creates the order on
  /// `/fare/multi-shop/orders/broadcast`, then hands over to the searching
  /// screen, which switches itself to tracking when a rider wins.
  Future<void> _onBroadcastToNearbyRiders() async {
    // Register the listeners BEFORE creating the order so a wave that starts
    // immediately isn't missed. `ride:queue:accepted` (the full winner
    // payload) lives on the fare-call listeners, which broadcast reuses.
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
    // Setup queue listeners BEFORE the API call so we don't miss
    // ride:queue:calling if the server fires it immediately after creation.
    discoverController.setupFareCallQueueListeners();
    final success = await discoverController.makeMultiShopOrderApi();
    if (success && discoverController.selectedRiders.isNotEmpty) {
      // Multi-shop goods orders use the dedicated tracking screen (rider info +
      // drop OTP) instead of the standard fare-call screen.
      Get.to(() => GoodsMultiCallTrackingScreen(
            orderId: discoverController.fareCallOrderId.value,
          ));
    }
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: _bookingBar(),
      body: Stack(
        children: [
          _map(),
          _topBar(),
          _recentreButton(),
          _sheet(),
        ],
      ),
    );
  }

  Widget _map() {
    return Obx(() {
      // Subscribe to the shops so a late riders response re-centres the map.
      final shops = discoverController.multiShopSortedShops;
      final center = shops.isNotEmpty
          ? LatLng(shops.first.latitude, shops.first.longitude)
          : _fallbackCenter;
      return BlueMap(
        initialCenter: center,
        initialZoom: 13,
        myLocationEnabled: true,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (c) {
          _mapController = c;
          _fitStops();
        },
      );
    });
  }

  Widget _topBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: Row(
        children: [
          _circleButton(Icons.arrow_back, Get.back),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              final shops = discoverController.multiShopSortedShops;
              final count =
                  shops.isNotEmpty ? shops.length : widget.pickups.length;
              final km = discoverController.multiShopRouteDistanceKm.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alt_route,
                        size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        '$count pickup${count == 1 ? '' : 's'} • 1 drop',
                        fontSize: SizeConfig.size14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Sits just above the sheet's resting edge — the map is mostly covered, so
  /// re-framing the whole route is the one map control worth surfacing.
  Widget _recentreButton() {
    return Positioned(
      right: 14,
      bottom: MediaQuery.of(context).size.height * _sheetRestExtent + 12,
      child: _circleButton(Icons.center_focus_strong, _fitStops),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: AppColors.mainTextColor),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- sheet

  Widget _sheet() {
    return DraggableScrollableSheet(
      initialChildSize: _sheetRestExtent,
      minChildSize: 0.28,
      maxChildSize: 0.88,
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
              Obx(() => _stopsSection()),
              const Divider(height: 1, color: AppColors.whiteE5),
              SizedBox(height: SizeConfig.size8),
              _vehicleList(),
              SizedBox(height: SizeConfig.size12),
            ],
          ),
        );
      },
    );
  }

  /// The route, collapsed to one tappable line. Expanded it becomes the same
  /// numbered stop list the pins show, in the same order.
  Widget _stopsSection() {
    final stops = _stops;
    final km = discoverController.multiShopRouteDistanceKm.value;
    final pickupCount = stops.where((s) => !s.isDrop).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _stopsExpanded = !_stopsExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    pickupCount > 0
                        ? 'Route • $pickupCount stop${pickupCount == 1 ? '' : 's'} then you'
                        : 'Route',
                    fontSize: SizeConfig.size15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                if (km > 0) ...[
                  CustomText(
                    '${km.toStringAsFixed(1)} km',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  _stopsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
        if (_stopsExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Column(
              children: [
                for (var i = 0; i < stops.length; i++)
                  _routeStop(stops[i], isLast: i == stops.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  /// One stop: the same numbered badge the map pin carries, with a connecting
  /// line down to the next one.
  Widget _routeStop(_Stop stop, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(color: stop.color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: stop.isDrop
                    ? const Icon(Icons.location_on,
                        size: 14, color: Colors.white)
                    : CustomText(
                        stop.label,
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
                          stop.title,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (stop.label == '1' && !stop.isDrop)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1),
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
                  if (stop.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      stop.subtitle,
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

  /// The priced vehicle list — one row per option, the selected one lifted
  /// into an outlined card.
  ///
  /// Vertical, not the old horizontal rail: the fare is the thing being
  /// compared here, and prices only read as a comparison when they line up in
  /// a column. The rail also had to drop the vehicle NAME to fit the price.
  Widget _vehicleList() {
    return Obx(() {
      final response = discoverController.ridersDetailsList.value;
      final selected = discoverController.selectedVehicleOptionIndex.value;
      final routeKm = discoverController.multiShopRouteDistanceKm.value;

      return Column(
        children: [
          for (var i = 0; i < optionList.length; i++)
            _vehicleRow(
              index: i,
              data: getSelectedVehicleData(response, 0, i),
              isSelected: selected == i,
              routeKm: routeKm,
            ),
        ],
      );
    });
  }

  Widget _vehicleRow({
    required int index,
    required VehicleData? data,
    required bool isSelected,
    required double routeKm,
  }) {
    final fare = data?.fare;
    final nearby = data?.users?.length ?? 0;
    final option = optionList[index];
    // No fare means the server didn't price this type for this route — it
    // stays visible but unbookable rather than silently disappearing.
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
            ? () => discoverController.selectedVehicleOptionIndex.value = index
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Only the selection is boxed — unselected rows sit flat on the
            // sheet, so the eye lands on the one that will be booked.
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
                    imagePath: option.svgImage,
                    boxFix: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        option.name ?? '',
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          _vehicleBlurbs[index],
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

  /// Hand-picking a rider is now a detour off the main path, not a wall in
  /// front of it: the default booking rings every nearby rider, so the list
  /// only opens for someone who wants a specific one.
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
              Flexible(
                child: SingleChildScrollView(child: _buildRiderList()),
              ),
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
              onTap: loading ? null : _onRefreshRiders,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        final response = discoverController.ridersDetailsList.value;
        final vehicleData = getSelectedVehicleData(
            response, 0, discoverController.selectedVehicleOptionIndex.value);
        final riders = vehicleData?.users ?? [];

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

  /// Payment + rider-choice row above one full-width CTA, the way the rest of
  /// the ride flows end. The button is the app's primary blue — this screen
  /// commits an order, and every other commit action in the app is that
  /// colour.
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
            final index = discoverController.selectedVehicleOptionIndex.value;
            final data = getSelectedVehicleData(
                discoverController.ridersDetailsList.value, 0, index);
            final vehicleName = optionList[index].name ?? '';
            final canBook = data?.fare != null;

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
                      const VerticalDivider(
                          width: 1, color: AppColors.whiteE5),
                      Expanded(
                        child: _footerAction(
                          icon: Icons.person_search_outlined,
                          label: discoverController.selectedRiders.isEmpty
                              ? 'Pick a rider'
                              : '${discoverController.selectedRiders.length} rider selected',
                          onTap: _openRiderPicker,
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
                  title: canBook
                      ? 'Book $vehicleName'
                      : 'No fare for $vehicleName',
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
}

/// A pin on the map and its row in the stop list — one source for both, so the
/// badge on the map and the badge in the sheet can never disagree.
class _Stop {
  const _Stop({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.color,
    required this.isDrop,
  });

  /// What the pin shows: the visit number, or "You" for the drop.
  final String label;
  final String title;
  final String subtitle;
  final LatLng position;
  final Color color;
  final bool isDrop;

  bool get hasPosition =>
      position.latitude != 0 || position.longitude != 0;
}

/// The downward tail under a map pin, so the pin points at its coordinate.
///
/// A tiny painter rather than part of the pin's decoration because a triangle
/// is not expressible as a BoxDecoration, and rotating a square would soften
/// the tip.
class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}
