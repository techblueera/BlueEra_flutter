import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_confirm_pickup_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_destination_search_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// Entry screen of the ride-booking flow (`assets/ride_home_screen.jpeg`).
///
/// Map behind, a pickup pill floating over it, and a draggable sheet holding
/// the search affordance above the service catalogue: what the rider can book,
/// grouped by what the trip IS — Passenger, Parcel/Goods, Out Station.
///
/// The catalogue replaced a single "Explore" rail of four vehicles. Vehicle
/// alone was never the whole choice: the same bike is a passenger ride or a
/// parcel run depending on `orderFor`, and grouping by service is what makes
/// that difference visible before the customer commits to a flow.
///
/// Recent destinations moved off this screen with the same change — the
/// destination search opens with them already listed, so nothing was lost.
class RideHomeScreen extends StatefulWidget {
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen> {
  late final RideBookingController controller;
  BlueMapController? _mapController;

  /// Bhopal — a sane frame while the device fix resolves, so the map never
  /// opens on the null island.
  static const LatLng _fallbackCenter = LatLng(23.2599, 77.4126);

  @override
  void initState() {
    super.initState();
    // The whole flow shares one controller instance; later screens reuse it
    // via Get.find().
    //
    // Permanent, and reused rather than replaced, because an active ride now
    // outlives the flow's screens: minimising to the floating mini-map unwinds
    // to the first route, which popped this screen and disposed the controller
    // — after which tapping the mini-map threw "RideBookingController not
    // found". State is cleared by resetTrip() at the end of a ride, not by
    // disposal, so nothing leaks between bookings.
    controller = getOrPut(() => RideBookingController(), permanent: true);
    // The service tiles ARE the catalogue, so fetch it as the screen opens.
    // Cached for the app run — re-entering the flow doesn't re-hit it.
    controller.fetchVehicleTypes();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _center {
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    return (lat == 0 && lng == 0) ? _fallbackCenter : LatLng(lat, lng);
  }

  /// Destination chosen → confirm the pickup point on the map next.
  ///
  /// [item] is the service tile that started the flow, or null when the user
  /// came in through the search field. It sets the trip type (`orderFor`) the
  /// same way the old flow's horizontal tab does, and pre-selects its vehicle
  /// on the vehicle screen.
  Future<void> _openDestinationSearch({_ServiceItem? item}) async {
    controller.setTripType(
      vehicleType: item?.vehicleType,
      orderFor: item?.orderFor ?? 'InCity',
    );
    final RidePlace? chosen = await Get.to<RidePlace>(
      () => const RideDestinationSearchScreen(),
    );
    if (chosen == null) return;
    controller.setDrop(chosen);
    Get.to(() => const RideConfirmPickupScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _map(),
          _pickupPill(),
          _sheet(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _map() {
    return Obx(() {
      final center = _center;
      return BlueMap(
        initialCenter: center,
        initialZoom: 15.5,
        myLocationEnabled: true,
        onMapCreated: (c) => _mapController = c,
        markers: [
          BlueMapMarker(
            id: 'pickup',
            position: center,
            icon: Icons.location_on,
            color: Colors.green,
          ),
        ],
      );
    });
  }

  /// Floating pill showing the current pickup address; tapping it lets the
  /// user re-pick the pickup point before choosing a destination.
  Widget _pickupPill() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          RideCircleButton(icon: Icons.arrow_back, onTap: Get.back),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              final place = controller.pickup.value;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.to(() => const RideConfirmPickupScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: RideStyle.floatingShadow,
                  ),
                  child: Row(
                    children: [
                      const RideEndpointDot(color: RideStyle.pickup),
                      const SizedBox(width: 10),
                      Expanded(
                        // The resolved address beats the generic label from
                        // the mock — it is the one thing here the customer can
                        // check before booking. 'Current location' stands in
                        // only until the fix lands.
                        child: CustomText(
                          place?.fullAddress.isNotEmpty == true
                              ? place!.fullAddress
                              : 'Current location',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: RideStyle.ink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ sheet

  Widget _sheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RideStyle.sheetRadius),
            ),
            boxShadow: RideStyle.sheetShadow,
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const RideSheetHandle(),
              _searchField(),
              const SizedBox(height: 20),
              for (final section in _sections) ...[
                _serviceSection(section),
                const SizedBox(height: 24),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openDestinationSearch,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: RideStyle.hairline),
            boxShadow: RideStyle.floatingShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: RideStyle.inkMuted, size: 24),
              const SizedBox(width: 12),
              CustomText(
                'Search Anything....',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: RideStyle.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------- service catalogue

  /// What this flow can book, grouped the way the customer thinks about it.
  ///
  /// A section owns the ORDER it wants to show and the `orderFor` it books;
  /// which of those codes actually exist — and what each is called — comes
  /// from the backend catalogue
  /// ([RideBookingController.fetchVehicleTypes], `GET
  /// riders/onboarding/vehicle-enums`). A type retired server-side vanishes
  /// here without a release, and a tile can never send a `vehicleType` the
  /// server would reject.
  ///
  /// The vehicle/trip pairing is the point: the same `twoWheelerRider` is a
  /// passenger ride under Passenger and a parcel run under Parcel/Goods, and
  /// the cars appear again under Out Station at a different `orderFor`.
  static const List<_ServiceSection> _sections = [
    _ServiceSection(
      title: 'Passenger ( City)',
      orderFor: 'InCity',
      codes: [
        'twoWheelerRider',
        'eRickshaw',
        'autoTempo',
        'carMini',
        'carSedan',
        'suvCar',
        'miniBus',
      ],
    ),
    _ServiceSection(
      title: 'Parcel/Goods ( City)',
      orderFor: 'Parcel',
      codes: [
        // A bike carrying a parcel is the same vehicle as a bike carrying a
        // person — only `orderFor` differs, so it is listed in both sections
        // under its own name here.
        'twoWheelerRider',
        'goods3Wheeler',
        'goods4Wheeler',
        'pickupGoods',
        'miniTruckGoods',
        'largeTruckGoods',
      ],
      labelOverrides: {'twoWheelerRider': 'Parcel On Bike'},
    ),
    _ServiceSection(
      title: 'Out Station',
      orderFor: 'OutStation',
      codes: ['carMini', 'carSedan', 'suvCar', 'miniBus'],
    ),
  ];

  /// Artwork per `vehicleType`. Local because the catalogue endpoint carries
  /// no imagery — placeholders from the app's existing transport set until the
  /// dedicated illustrations land, so an unmapped new code still gets a tile
  /// (with the closest vehicle) instead of an empty box.
  static const Map<String, String> _vehicleArtwork = {
    'twoWheelerRider': AppIconAssets.transport_bike,
    'autoTempo': AppIconAssets.transport_auto,
    'eRickshaw': AppIconAssets.transport_big_auto,
    'carMini': AppIconAssets.transport_taxi,
    'carSedan': AppIconAssets.transport_taxi,
    'suvCar': AppIconAssets.transport_7_seater,
    'miniBus': AppImageAssets.miniBus,
    'goods3Wheeler': AppIconAssets.transport_load_auto,
    'goods4Wheeler': AppIconAssets.transport_truck,
    'pickupGoods': AppIconAssets.transport_truck,
    'miniTruckGoods': AppIconAssets.transport_container,
    'largeTruckGoods': AppIconAssets.transport_container,
  };

  /// Parcel artwork for the one vehicle that appears in both sections, so the
  /// goods row doesn't repeat the passenger bike.
  static const Map<String, String> _parcelArtwork = {
    'twoWheelerRider': AppIconAssets.riderIconColorful,
  };

  Widget _serviceSection(_ServiceSection section) {
    return Obx(() {
      final types = controller.vehicleTypesFor(section.codes);
      if (types.isEmpty) {
        // Still loading, or this section has nothing the backend offers.
        return controller.isLoadingVehicleTypes.value
            ? _sectionSkeleton(section.title)
            : const SizedBox.shrink();
      }

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
                    for (final type in types)
                      SizedBox(
                        width: tileWidth,
                        child: _ServiceTile(
                          label: section.labelOverrides[type.code] ?? type.label,
                          assetPath: _artworkFor(section, type.code),
                          onTap: () => _openDestinationSearch(
                            item: _ServiceItem(
                              vehicleType: type.code,
                              orderFor: section.orderFor,
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
    });
  }

  String _artworkFor(_ServiceSection section, String code) {
    if (section.orderFor == 'Parcel' && _parcelArtwork.containsKey(code)) {
      return _parcelArtwork[code]!;
    }
    return _vehicleArtwork[code] ?? AppIconAssets.transport_bike;
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
}

// ---------------------------------------------------------------- sub-widgets

/// One heading, the trip type it books, and the `vehicleType` codes it would
/// like to show — in display order. What is actually rendered is the
/// intersection of [codes] with the backend catalogue.
class _ServiceSection {
  const _ServiceSection({
    required this.title,
    required this.orderFor,
    required this.codes,
    this.labelOverrides = const {},
  });

  final String title;

  /// Trip type this section books: `InCity | OutStation | HourlyRental | Parcel`.
  final String orderFor;

  /// Backend `vehicleType` enums, in the order the section wants them.
  final List<String> codes;

  /// Section-specific names, for a vehicle whose catalogue label doesn't fit
  /// the service (a bike is "Parcel On Bike" under Parcel/Goods).
  final Map<String, String> labelOverrides;
}

/// What a tapped tile hands to the flow: which vehicle to pre-select and which
/// trip type to price it as.
class _ServiceItem {
  const _ServiceItem({required this.vehicleType, required this.orderFor});

  /// Backend `vehicleType` enum value — pre-selects the row on the vehicle
  /// screen and is what the broadcast create call sends.
  final String vehicleType;

  final String orderFor;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;

  /// Asset under `assets/` — see [AppIconAssets] / [AppImageAssets].
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        // Stretch, otherwise the tinted box shrink-wraps its artwork and tiles
        // end up different widths (the rider SVG is near-square while the
        // vehicle SVGs are wide).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            // Slightly wider than tall, as in the reference — and fixed by
            // ratio rather than height so the four tiles stay square-ish on
            // both a small phone and a tablet.
            aspectRatio: 1.22,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RideStyle.surfaceTint,
                borderRadius: BorderRadius.circular(12),
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
            fontWeight: FontWeight.w500,
            color: RideStyle.ink,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
