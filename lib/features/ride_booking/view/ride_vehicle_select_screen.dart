import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_searching_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_marker_icons.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_vehicle_presentation.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Vehicle + fare selection (screenshot 3).
///
/// Map with the pickup→drop route on top, the quoted vehicle list in a sheet
/// below, and a persistent fare bar (payment mode / offers / Book).
class RideVehicleSelectScreen extends StatefulWidget {
  const RideVehicleSelectScreen({super.key});

  @override
  State<RideVehicleSelectScreen> createState() =>
      _RideVehicleSelectScreenState();
}

class _RideVehicleSelectScreenState extends State<RideVehicleSelectScreen>
    with RideLiveRiderMarkers {
  final RideBookingController controller = Get.find<RideBookingController>();
  GoogleMapController? _mapController;

  /// Re-frames the camera when the road route lands, so the view fits the
  /// actual path rather than the straight line between the endpoints.
  Worker? _routeWorker;

  /// Rasterises artwork for any vehicle type a live-rider lookup brings back.
  Worker? _liveRiderWorker;

  @override
  void initState() {
    super.initState();
    // Open on the bike. Nothing upstream picks a vehicle any more — the home
    // screen only asks where you are going — so without this the grid arrives
    // with nothing lit and the quote selects whichever class the server happens
    // to list first. Set BEFORE fetchQuotes, which pre-selects this code.
    //
    // Only when nothing is chosen yet: coming back from a later screen must
    // keep the class the customer actually picked.
    if (controller.preselectedVehicleCode.value == null) {
      controller.setTripType(
        vehicleType: RideBookingController.kDefaultVehicleType,
      );
    }
    // Same two calls a tile tap makes, in the same order — see
    // [_selectService].
    _loadForSelection();
    // Frame both endpoints once the map is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    _routeWorker = ever<List<LatLng>>(controller.routePoints, (_) {
      if (mounted) _fitBounds();
    });
    _liveRiderWorker = ever<List<RideLiveRider>>(
      controller.liveRiders,
      ensureRiderMarkerIcons,
    );
  }

  @override
  void dispose() {
    _routeWorker?.dispose();
    _liveRiderWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Zoom the camera so the whole trip is visible with padding.
  ///
  /// Frames the route geometry when we have it: a road route routinely bows
  /// well outside the box drawn around its two endpoints, and fitting only the
  /// endpoints crops the middle of the path off-screen.
  Future<void> _fitBounds() async {
    final map = _mapController;
    if (map == null) return;

    final points = <LatLng>[
      ...controller.routePoints,
      // Always include the endpoints — they must stay visible even if the
      // route failed to resolve.
      for (final place in [controller.pickup.value, controller.drop.value])
        if (place != null && place.hasCoordinates)
          LatLng(place.latitude, place.longitude),
    ];
    if (points.length < 2) return;

    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  /// Book straight through to the searching screen.
  ///
  /// This used to open a sheet listing who was live nearby and ask the customer
  /// to confirm a second time. It was informational only — dispatch is a
  /// BROADCAST, so nothing in that list could be picked — and it sat between a
  /// button already labelled with the vehicle and the price and the action it
  /// promised. The supply it showed is on the map behind it anyway, and the
  /// searching screen is where waiting for a rider belongs.
  void _confirmBooking() {
    if (controller.selectedVehicle.value == null) return;
    _book();
  }

  Future<void> _book() async {
    final booked = await controller.bookRide();
    if (!mounted) return;
    if (!booked) {
      commonSnackBar(message: 'Could not book this ride. Please try again.');
      return;
    }
    Get.to(() => const RideSearchingScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(flex: 4, child: _mapArea()),
          // The hint rides INSIDE the sheet's bounds, over the vehicle list.
          // Given its own row between the two surfaces it sat in the fare bar's
          // upward shadow (`sheetShadow` is offset (0, -6) at 24 blur) with
          // nothing painted over it — which read as a grey band behind the
          // arrow. Here the list is what shows through instead.
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                _vehicleSheet(),
                // Inside the Stack's bounds, so it is hit-tested: a child
                // painted outside a parent's box is drawn but never tappable.
                Positioned(left: 0, right: 0, bottom: 0, child: _bookHint()),
              ],
            ),
          ),
          _fareBar(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _mapArea() {
    return Obx(() {
      final from = controller.pickup.value;
      final to = controller.drop.value;
      final center = from != null && from.hasCoordinates
          ? LatLng(from.latitude, from.longitude)
          : const LatLng(23.2599, 77.4126);

      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              _fitBounds();
            },
            markers: {
              if (from != null && from.hasCoordinates)
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(from.latitude, from.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              if (to != null && to.hasCoordinates)
                Marker(
                  markerId: const MarkerId('drop'),
                  position: LatLng(to.latitude, to.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              // The vehicles of the selected type that are live around the
              // pickup. Read inside this Obx, so picking a row repaints the map
              // as soon as its lookup lands.
              ...liveRiderMarkers(controller.liveRiders),
            },
            polylines: _routePolylines(from, to),
          ),
          _addressChips(from, to),
          Positioned(
            left: 16,
            bottom: 16,
            child: RideCircleButton(icon: Icons.arrow_back, onTap: Get.back),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _addStopButton(),
          ),
        ],
      );
    });
  }

  /// The road route once the controller has it, else a straight placeholder.
  ///
  /// The placeholder is drawn dashed-thin and muted on purpose — a solid line
  /// straight through the city reads as "this is your route", which it isn't.
  ///
  /// Two overlapping lines make the real route: a wide light casing under a
  /// narrower dark stroke, so the path stays legible over dense map tiles.
  Set<Polyline> _routePolylines(RidePlace? from, RidePlace? to) {
    final route = controller.routePoints;
    if (route.length >= 2) {
      final points = route.toList(growable: false);
      return {
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: points,
          color: AppColors.white,
          width: 9,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: RideStyle.ink,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    }

    if (from == null || to == null) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('route_pending'),
        points: [
          LatLng(from.latitude, from.longitude),
          LatLng(to.latitude, to.longitude),
        ],
        color: RideStyle.inkMuted,
        width: 3,
        patterns: [PatternItem.dash(18), PatternItem.gap(10)],
      ),
    };
  }

  Widget _addressChips(RidePlace? from, RidePlace? to) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (to != null)
            _MapAddressChip(
              label: to.title,
              color: RideStyle.drop,
              onEdit: Get.back,
            ),
          const SizedBox(height: 8),
          if (from != null)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _MapAddressChip(
                label: from.title,
                color: RideStyle.pickup,
                onEdit: Get.back,
              ),
            ),
        ],
      ),
    );
  }

  Widget _addStopButton() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        // Stops are modelled in the controller but the picker is not part of
        // this milestone — the affordance is present, wiring comes with the
        // multi-stop quote contract.
        onTap: () => commonSnackBar(message: 'Add stop is coming soon'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 20, color: RideStyle.ink),
              const SizedBox(width: 6),
              CustomText(
                'Add stop',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ sheet

  /// The service catalogue — the same grid the home screen used to carry, now
  /// where it belongs: after the trip is known, so every tile can show what it
  /// costs for THIS trip.
  Widget _vehicleSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
        boxShadow: RideStyle.sheetShadow,
      ),
      child: ListView(
        // Room at the foot for the book hint, which floats over this list —
        // without it the last section can never be scrolled clear of the
        // chevron.
        padding: const EdgeInsets.only(bottom: _BookHintArrow.reservedHeight),
        children: [
          const RideSheetHandle(),
          _quoteNotice(),
          for (final section in _sections) ...[
            _serviceSection(section),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// Why the tiles have no prices, when they don't.
  ///
  /// The catalogue itself never depends on the quote — the customer can always
  /// see and pick a vehicle — so a failed or empty quote is a line above the
  /// grid rather than a screen that replaces it. A failed request and an empty
  /// city are different problems: saying "no vehicles" for a 400 sends you
  /// looking in the wrong place.
  Widget _quoteNotice() {
    return Obx(() {
      if (controller.isQuoting.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        );
      }
      final error = controller.quoteError.value;
      if (error == null && controller.vehicleOptions.isNotEmpty) {
        return const SizedBox(height: 6);
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                error ?? 'No riders available near your pickup right now.',
                fontSize: 13,
                color: RideStyle.inkMuted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: controller.fetchQuotes,
              child: CustomText(
                'Retry',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ------------------------------------------------------- service catalogue

  /// What this flow can book, grouped the way the customer thinks about it.
  ///
  /// A section owns the ORDER it wants to show and the `orderFor` it books;
  /// which of those codes actually exist — and what each is called — comes from
  /// the backend, via [RideBookingController.vehicleTypesFor]. That answers
  /// from this trip's fare catalog first (`fare/riders/dynamic` with
  /// `allVehicleTypes=true`, which prices every type) and falls back to the
  /// vehicle enum (`GET riders/onboarding/vehicle-enums`) for its display names
  /// and for the sections not currently being quoted. A type retired
  /// server-side vanishes here without a release, and a tile can never send a
  /// `vehicleType` the server would reject.
  ///
  /// The vehicle/trip pairing is the point: the same `twoWheelerRider` is a
  /// passenger ride under Passenger and a parcel run under Parcel/Goods, and
  /// the cars appear again under Out Station at a different `orderFor`.
  static const List<_ServiceSection> _sections = [
    _ServiceSection(
      title: 'Passenger ( City)',
      orderFor: 'InCity',
      tiles: [
        _ServiceTileSpec('twoWheelerRider'),
        _ServiceTileSpec('eRickshaw'),
        _ServiceTileSpec('autoTempo'),
        // One tile for the whole car family in the city, four of them out of
        // town. A city ride is chosen by "I want a car" and then by price; Out
        // Station is the opposite — the class IS the decision there, and the
        // price gap is large, so that section keeps them apart.
        _ServiceTileSpec(
          'carMini',
          label: 'Cab',
          alsoCovers: ['carSedan', 'suvCar', 'miniBus'],
        ),
      ],
    ),
    _ServiceSection(
      title: 'Parcel/Goods ( City)',
      orderFor: 'Parcel',
      tiles: [
        // A bike carrying a parcel is the same vehicle as a bike carrying a
        // person — only `orderFor` differs, so it is listed in both sections
        // and renders as "Parcel On Bike" here.
        _ServiceTileSpec('twoWheelerRider'),
        _ServiceTileSpec('goods3Wheeler'),
        // Same collapse as the city cab: a pickup IS a 4-wheeler to the
        // customer sending a load, and mini vs. large truck is a capacity call.
        _ServiceTileSpec(
          'goods4Wheeler',
          label: 'Goods (4 Wheeler)',
          alsoCovers: ['pickupGoods'],
        ),
        _ServiceTileSpec(
          'miniTruckGoods',
          label: 'Truck Goods',
          alsoCovers: ['largeTruckGoods'],
        ),
      ],
    ),
    _ServiceSection(
      title: 'Out Station',
      orderFor: 'OutStation',
      tiles: [
        _ServiceTileSpec('carMini'),
        _ServiceTileSpec('carSedan'),
        _ServiceTileSpec('suvCar'),
        _ServiceTileSpec('miniBus'),
      ],
    ),
  ];

  /// Pick a service: it becomes what gets booked, re-priced, and the map
  /// repainted with the vehicles that would come.
  ///
  /// Two calls, in this order and never overlapping:
  ///
  ///  1. `fare/riders/dynamic` — the fare for this vehicle on this trip.
  ///  2. `riders/live-in-radius` — who is out there in that family.
  ///
  /// Sequential because the second is only worth making once the first has
  /// settled what is being booked: fired together they race, and a tile tapped
  /// twice in quick succession can land its lookups out of order. Awaiting also
  /// keeps the spinner honest — the grid is quoting, then the map fills.
  Future<void> _selectService({
    required String vehicleType,
    required String orderFor,
  }) async {
    // Whether the TRIP changed, not just the vehicle. Read before setTripType
    // overwrites it.
    final tripChanged = controller.orderFor.value != orderFor;

    controller.setTripType(vehicleType: vehicleType, orderFor: orderFor);

    // Selecting a vehicle no longer re-quotes. The catalog call made on entry
    // already carries a fare for every type it prices, so the price for the
    // tapped tile is usually in hand — re-fetching it blanked the whole grid
    // behind a spinner and came back with the same numbers.
    //
    // The SELECTED option is priced for the section that was tapped, not for
    // whatever `orderFor` the catalog was fetched under: it is what the Book
    // button prints, and booking a parcel run at the passenger fare is the same
    // bug the grid had.
    var picked = _optionFor(vehicleType, orderFor);
    if (picked != null) controller.selectVehicle(picked);

    // A trip-type change USED to always re-quote, on the reasoning that "Bike"
    // and "Parcel on Bike" are the same vehicle priced two ways and only the
    // server knows the second. It does — and it already told us, in
    // `serviceFares`. Re-quoting when that block already answers for this trip
    // type replaces the whole catalog with one fetched under a different
    // `orderFor`, which is what made the Passenger bike's price jump to the
    // parcel fare the moment the parcel bike was tapped.
    //
    // Still re-quotes for a type the server priced only one way, and for one it
    // did not price at all — there the fetch is the only way to learn the fare.
    if (tripChanged && !(picked?.hasFareFor(orderFor) ?? false)) {
      await controller.fetchQuotes();
      if (!mounted) return;
      // Re-read the tapped type from the REPLACED catalog.
      //
      // Without this, tapping a tile the first catalog did not price left
      // `selectedVehicle` on the PREVIOUS vehicle: the tile lit up (that runs
      // off `preselectedVehicleCode`) while the Book button went on naming and
      // charging for the one before it. The goods classes are exactly this case
      // today — they render from the vehicle enum but `fares` omits them.
      picked = _optionFor(vehicleType, orderFor);
      if (picked != null) controller.selectVehicle(picked);
    }

    // Always: the map shows who is out there in the SELECTED family, which is
    // a different question from what the ride costs.
    await controller.fetchLiveRiders(
      vehicleType: controller.preselectedVehicleCode.value,
    );
  }

  /// The catalog entry for [vehicleType], priced for [orderFor]. Null when this
  /// trip's catalog does not carry that type at all.
  RideVehicleOption? _optionFor(String vehicleType, String orderFor) {
    for (final option in controller.vehicleOptions) {
      if (option.code == vehicleType) return option.forService(orderFor);
    }
    return null;
  }

  /// The quote, then the live riders — the screen's opening load.
  ///
  /// `IfNeeded`: confirming the pickup already fired this exact quote a moment
  /// ago, so on the normal path this joins that request rather than making a
  /// second identical one. It still fetches when the screen is reached any
  /// other way, or when the trip changed under it.
  Future<void> _loadForSelection() async {
    await controller.fetchQuotesIfNeeded();
    if (!mounted) return;
    await controller.fetchLiveRiders(
      vehicleType: controller.preselectedVehicleCode.value,
    );
  }

  Widget _serviceSection(_ServiceSection section) {
    return Obx(() {
      final catalogue = {
        for (final type in controller.vehicleTypesFor(section.codes))
          type.code: type,
      };
      if (catalogue.isEmpty) {
        // Nothing to show YET, or nothing to show at all. Either source can
        // still fill this in — the vehicle enum or this trip's own fare catalog
        // — so the skeleton stands while either is in flight, and the section
        // only collapses once both have answered and neither knows these types.
        return controller.isLoadingVehicleTypes.value ||
                controller.isQuoting.value
            ? _sectionSkeleton(section.title)
            : const SizedBox.shrink();
      }

      // A tile survives only if the catalogue still carries one of the types it
      // covers, so a class retired server-side takes its tile with it — and the
      // grouped "Cab" tile keeps working as long as ANY car is bookable.
      final tiles = <({_ServiceTileSpec spec, RideVehicleType type})>[
        for (final spec in section.tiles)
          if (spec.resolve(catalogue) case final type?) (spec: spec, type: type),
      ];

      // What is being booked. Both halves have to match: `twoWheelerRider` is a
      // tile in Passenger AND in Parcel/Goods, and only the `orderFor` tells
      // them apart. This still gates the SELECTION — one tile is lit across the
      // whole sheet — even though prices are no longer gated.
      final selectedCode = section.orderFor == controller.orderFor.value
          ? controller.preselectedVehicleCode.value
          : null;

      // Fares are read HERE, in the Obx's own build, and handed down as a plain
      // map — never touched inside the LayoutBuilder below.
      //
      // LayoutBuilder runs its callback at LAYOUT time, after the build phase
      // has ended and GetX has stopped recording which observables were read.
      // An `Obx` therefore never subscribes to anything touched in there: the
      // tiles rendered fine, but a quote landing afterwards updated
      // `vehicleOptions` with nobody listening, so the prices sat at their old
      // values (or at '—') until some unrelated rebuild happened to refresh
      // them.
      //
      // EVERY section reads the same catalog: `allVehicleTypes=true` prices
      // types beyond the `orderFor` the call was made with, so a fare fetched
      // for InCity does say something about Parcel. This used to be gated on
      // the section matching the trip currently being quoted, which cost
      // Parcel/Goods and Out Station a dash on prices the server had already
      // sent.
      //
      // Handed down raw and re-priced per tile with `forService`, NOT read as
      // one fare per code: the same `twoWheelerRider` appears under Passenger
      // and under Parcel/Goods, and keying by code alone made those two tiles
      // literally the same entry.
      //
      // Two limits, both server-side and both tracked in
      // docs/backend/OPEN_BACKEND_QUESTIONS.md — measured against a live
      // response, not assumed:
      //
      //   * `fares` returned 8 of the 12 types; the four goods classes were
      //     absent, so those tiles resolve from the vehicle enum and show '—';
      //   * only `twoWheelerRider` carried more than one entry in
      //     `serviceFares`, so every other type still falls back to its
      //     top-level fare for the section it is listed under.
      final quotes = {
        for (final option in controller.vehicleOptions) option.code: option,
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomText(
              section.title,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: RideStyle.ink,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Fixed four-column measure, laid out by hand rather than with
                // a GridView: a short row must sit at the SAME tile width as
                // the full rows and stay left-aligned, which is what a Wrap
                // over pre-measured tiles gives.
                const columns = 4;
                const gap = 8.0;
                final tileWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: 14,
                  children: [
                    for (final tile in tiles)
                      SizedBox(
                        width: tileWidth,
                        child: _ServiceTile(
                          label: tile.spec.label ??
                              RideVehicleArt.labelFor(
                                tile.type.code,
                                orderFor: section.orderFor,
                                catalogueLabel: tile.type.label,
                              ),
                          assetPath: RideVehicleArt.assetFor(
                            tile.type.code,
                            orderFor: section.orderFor,
                          ),
                          // Priced for THIS section's trip type. Keying by code
                          // alone made the bike's Passenger and Parcel tiles one
                          // and the same entry — see [forService].
                          quote: quotes[tile.type.code]
                              ?.forService(section.orderFor),
                          selected: tile.spec.covers(selectedCode),
                          onTap: () => _selectService(
                            vehicleType: tile.type.code,
                            orderFor: section.orderFor,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
  }

  /// Placeholder tiles while the catalogue loads, so the sheet doesn't jump
  /// from empty to full height under the user's thumb.
  Widget _sectionSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomText(
            title,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: RideStyle.ink,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const columns = 4;
              const gap = 8.0;
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: [
                  for (var i = 0; i < columns; i++)
                    SizedBox(
                      width: tileWidth,
                      child: AspectRatio(
                        aspectRatio: 1.22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: RideStyle.surfaceTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- fare bar

  /// The bobbing chevron at the foot of the vehicle sheet, pointing down at the
  /// thing to tap next.
  ///
  /// Transparent and laid over the list rather than given a row of its own, so
  /// what sits behind it is the vehicle grid — see the note at the call site
  /// for what a dedicated row looked like instead. The sheet's own bottom
  /// padding keeps the last section scrollable clear of it.
  Widget _bookHint() {
    return SizedBox(
      height: _BookHintArrow.reservedHeight,
      child: Obx(() {
        // Only once there is something to book. An arrow pointing at a disabled
        // button, insisting you tap it, is worse than no arrow.
        final ready = controller.selectedVehicle.value != null;
        return AnimatedOpacity(
          opacity: ready ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !ready,
            child: Center(child: _BookHintArrow(onTap: _confirmBooking)),
          ),
        );
      }),
    );
  }

  Widget _fareBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
        boxShadow: RideStyle.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _BarAction(
                    icon: Icons.account_balance_wallet_outlined,
                    label: controller.paymentMode.value == 'CASH'
                        ? 'Cash'
                        : 'Online',
                    onTap: _showPaymentPicker,
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: RideStyle.hairline),
              Expanded(
                child: _BarAction(
                  icon: Icons.percent,
                  label: 'Offers',
                  onTap: () =>
                      commonSnackBar(message: 'No offers available yet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            // The fare rides on the button now that the rows are the list —
            // it is the number the customer is agreeing to, and it must be on
            // the control that agrees to it.
            final selected = controller.selectedVehicle.value;
            return RidePrimaryButton(
              label: selected == null
                  ? 'Book'
                  : 'Book ${selected.name} · '
                      '₹${selected.fare.toStringAsFixed(0)}',
              enabled: selected != null,
              isLoading: controller.isBooking.value,
              onTap: _confirmBooking,
            );
          }),
        ],
      ),
    );
  }

  void _showPaymentPicker() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RideStyle.sheetRadius),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RideSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  'Payment method',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: RideStyle.ink,
                ),
              ),
            ),
            for (final mode in const [
              ('CASH', 'Cash', Icons.payments_outlined),
              ('ONLINE', 'Pay online', Icons.credit_card),
            ])
              ListTile(
                leading: Icon(mode.$3, color: RideStyle.ink),
                title: CustomText(
                  mode.$2,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: RideStyle.ink,
                ),
                trailing: Obx(
                  () => controller.paymentMode.value == mode.$1
                      ? const Icon(Icons.check_circle,
                          color: RideStyle.pickup)
                      : const SizedBox.shrink(),
                ),
                onTap: () {
                  controller.setPaymentMode(mode.$1);
                  Get.back();
                },
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ---------------------------------------------------------------- sub-widgets

/// One heading, the trip type it books, and the tiles it would like to show —
/// in display order. What is actually rendered is the intersection of those
/// tiles with the backend catalogue.
class _ServiceSection {
  const _ServiceSection({
    required this.title,
    required this.orderFor,
    required this.tiles,
  });

  final String title;

  /// Trip type this section books: `InCity | OutStation | HourlyRental | Parcel`.
  final String orderFor;

  /// The tiles, in the order the section wants them.
  ///
  /// A vehicle whose name or artwork doesn't fit the service it is listed under
  /// (a bike is "Parcel On Bike" here) is handled by [RideVehicleArt], keyed off
  /// [orderFor] — the same override the destination search reads.
  final List<_ServiceTileSpec> tiles;

  /// Every `vehicleType` this section touches, for the catalogue lookup.
  List<String> get codes =>
      [for (final tile in tiles) tile.code, ...tiles.expand((t) => t.alsoCovers)];
}

/// One tile in a section, and the vehicle it books.
///
/// Usually one tile is one `vehicleType`. [alsoCovers] is for the case where a
/// section shows a whole family behind a single tile — the city "Cab" — and
/// exists for two reasons: the tile must still appear when [code] itself is
/// retired server-side, and the section's catalogue lookup has to know the
/// covered types are in play.
class _ServiceTileSpec {
  const _ServiceTileSpec(this.code, {this.label, this.alsoCovers = const []});

  /// Backend `vehicleType` enum this tile books.
  final String code;

  /// Name for a tile that doesn't stand for one vehicle ("Cab"). Null takes the
  /// catalogue's own name for [code].
  final String? label;

  /// Other types this tile stands in for, in fallback order.
  final List<String> alsoCovers;

  /// Whether [vehicleType] is one this tile books — [code] or anything it
  /// stands in for. Null (nothing selected yet) covers nothing.
  bool covers(String? vehicleType) =>
      vehicleType != null &&
      (vehicleType == code || alsoCovers.contains(vehicleType));

  /// The catalogue entry to render this tile from: [code], or the first of
  /// [alsoCovers] the backend still offers. Null when none of them exist, in
  /// which case the section drops the tile.
  RideVehicleType? resolve(Map<String, RideVehicleType> catalogue) {
    for (final candidate in [code, ...alsoCovers]) {
      final type = catalogue[candidate];
      if (type != null) return type;
    }
    return null;
  }
}

/// One vehicle in the catalogue grid — the home screen's tile, now carrying
/// what this trip costs in it.
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.assetPath,
    required this.onTap,
    this.quote,
    this.selected = false,
  });

  final String label;

  /// Asset under `assets/` — see [RideVehicleArt.assetFor].
  final String assetPath;

  /// This vehicle's quote for the current trip, or null when the server isn't
  /// pricing it — the tile still shows, so the customer sees the whole
  /// catalogue and not just today's availability.
  final RideVehicleOption? quote;

  final VoidCallback onTap;

  /// This is the vehicle the Book button will send.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Nobody is driving this type in range right now. It is a NOTE, not a gate:
    // the server prices every type in one answer (`allVehicleTypes=true`), so
    // the fare below is real, and dispatch is a broadcast that a rider coming
    // on shift can still answer. Blocking the tap hid a price the customer had
    // already been quoted and left seven of the eight tiles dead on a grid
    // where only bikes happened to be online.
    //
    // Absent availability is NOT unavailable — see [RideVehicleOption
    // .isUnavailable] — so an older response with no flag reads as fine.
    final bool noRidersNearby = quote?.isUnavailable == true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Always live. Tapping is what re-prices the trip for this class AND
      // re-queries `riders/live-in-radius` for it, which is how the map fills
      // with the vehicles that would actually come — see [_selectService].
      onTap: onTap,
      child: Column(
        // Stretch, otherwise the tinted box shrink-wraps its artwork and tiles
        // end up different widths (the rider SVG is near-square while the
        // vehicle SVGs are wide).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            // Slightly wider than tall — and fixed by ratio rather than height
            // so the four tiles stay square-ish on both a small phone and a
            // tablet.
            aspectRatio: 1.22,
            // Selected state is the plate's own border, animated so a tap reads
            // as this tile lighting up rather than the grid silently redrawing.
            // Transparent rather than absent when unselected: a border that
            // appears would change the box's inner size and nudge the artwork.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryColor.withValues(alpha: 0.10)
                    : RideStyle.surfaceTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primaryColor : Colors.transparent,
                  width: 1.6,
                ),
              ),
              // No imgColor — these are full-colour vehicle illustrations, so
              // tinting them would flatten them to a silhouette.
              child: LocalAssets(
                imagePath: assetPath,
                boxFix: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CustomText(
            label,
            fontSize: 13,
            // The name carries the state too — a border on a small tile is easy
            // to miss, and it keeps the cue readable for anyone who can't pick
            // the blue out of the grid.
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryColor : RideStyle.ink,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // The price, on EVERY tile the server priced — which is all of them.
          // An em dash means the vehicle exists but this trip isn't priced for
          // it, a different thing from the tile being missing.
          CustomText(
            quote == null ? '—' : '₹${quote!.fare.toStringAsFixed(0)}',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: quote == null ? RideStyle.inkMuted : RideStyle.ink,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          // ONE line under the price, either way, so every tile is the same
          // height and the grid rows stay level.
          //
          // Normally it says what the fare buys: the distance the server priced
          // this row over and how long the drive takes. A bare number is a
          // number; "₹40" next to "2.0 km · 3 min" is a price the customer can
          // judge. When nobody is online for this class it says that instead —
          // the more useful thing to know at that moment, and it still lets
          // them book and wait if they want to.
          if (noRidersNearby)
            CustomText(
              'None nearby',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: RideStyle.danger,
              textAlign: TextAlign.center,
              maxLines: 1,
            )
          else if (quote?.tripSummary case final summary?)
            CustomText(
              summary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: RideStyle.inkMuted,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}

/// The chevron that nudges the customer toward the Book button, bobbing up and
/// down the way a ride app's does.
///
/// It is a HINT, not the control — the button below is what books — but it is
/// tappable, because an element that beckons and then does nothing when you
/// follow it is a worse answer than one that isn't tappable at all.
class _BookHintArrow extends StatefulWidget {
  const _BookHintArrow({required this.onTap});

  final VoidCallback onTap;

  /// Height the hint occupies at the foot of the sheet. Bigger than the glyph
  /// so the bob has somewhere to travel and the tap target clears the ~44px
  /// minimum on its long axis.
  static const double reservedHeight = 52;

  /// How far the chevron travels upward, in logical pixels. Enough to catch the
  /// eye across the sheet; the rest position stays at the bottom of the stroke,
  /// nearest what it points at. [reservedHeight] carries it so the stroke has
  /// room — raise them together.
  static const double _travel = 20;

  @override
  State<_BookHintArrow> createState() => _BookHintArrowState();
}

class _BookHintArrowState extends State<_BookHintArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  /// Up at the start, resting at the bottom — so a stopped animation leaves the
  /// chevron closest to what it points at, which is the meaningful position.
  late final Animation<double> _offset = Tween<double>(
    begin: -_BookHintArrow._travel,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reduce motion" exists precisely to stop indefinite loops like this one.
    // The chevron stays — it still points at the button — it just holds still.
    final animate = !MediaQuery.of(context).disableAnimations;
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = _controller.upperBound;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque so the whole reserved box takes the tap, not just the glyph's
      // own thin strokes.
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: SizedBox(
        height: _BookHintArrow.reservedHeight,
        width: 64,
        child: Center(
          child: AnimatedBuilder(
            animation: _offset,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _offset.value),
              child: child,
            ),
            // Built once and reused across every frame of the bob — only the
            // transform above it changes.
            child: const Icon(
              CupertinoIcons.chevron_down,
              size: 24,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapAddressChip extends StatelessWidget {
  const _MapAddressChip({
    required this.label,
    required this.color,
    required this.onEdit,
  });

  final String label;
  final Color color;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: RideStyle.floatingShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RideEndpointDot(color: color, size: 12),
            const SizedBox(width: 8),
            Flexible(
              child: CustomText(
                label,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 16, color: RideStyle.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: RideStyle.ink),
            const SizedBox(width: 8),
            CustomText(
              label,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: RideStyle.ink,
            ),
            const Icon(Icons.chevron_right, size: 20, color: RideStyle.ink),
          ],
        ),
      ),
    );
  }
}
