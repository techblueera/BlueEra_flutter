import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_confirm_pickup_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_destination_search_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_marker_icons.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Entry screen of the ride-booking flow.
///
/// Live map behind with the pickup pill over it, and a sheet holding the
/// destination search with the customer's last destinations under it. One
/// question per screen: *where are you going* — the map answers *what is around
/// me* while they decide.
///
/// Nothing here picks a vehicle. Choosing one before naming a destination meant
/// choosing before any price existed; the whole catalogue now lives on the
/// vehicle-select screen after the pickup is confirmed, where every class is
/// listed against its own fare. The map still shows live vehicles nearby — for
/// whatever the flow currently defaults to — as a sense of supply, not a
/// choice.
class RideHomeScreen extends StatefulWidget {
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen>
    with RideLiveRiderMarkers {
  late final RideBookingController controller;
  GoogleMapController? _mapController;

  /// Bhopal — a sane frame while the device fix resolves, so the map never
  /// opens on the null island.
  static const LatLng _fallbackCenter = LatLng(23.2599, 77.4126);

  /// How many past destinations the sheet lists. The rest stay one tap away in
  /// the destination search, which opens on the full list.
  static const int _recentPlacesShown = 5;

  /// Fraction of the screen the sheet opens at.
  ///
  /// The map is padded by the same amount, so its centre — where the pickup
  /// sits — lands in the middle of the strip the user can actually SEE rather
  /// than in the middle of a widget whose bottom half is under the sheet.
  static const double _sheetInitialExtent = 0.42;

  /// Rebuilds the marker artwork when a lookup brings back a vehicle type we
  /// have not rasterised yet.
  Worker? _liveRiderWorker;

  /// Fires the first live-rider lookup once the device fix lands, for the cold
  /// open where the screen is built before the position resolves.
  Worker? _locationWorker;

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
    // Not for this screen any more — the fare list two screens on names its
    // rows from the catalogue, and it is cached for the app run, so fetching
    // it here means it has landed by the time that screen opens.
    controller.fetchVehicleTypes();

    // Show what is out there straight away, for whatever class is currently
    // selected (the bike by default). The picker re-runs it.
    if (controller.currentLat.value != 0 || controller.currentLng.value != 0) {
      controller.fetchLiveRiders();
    } else {
      // Cold open: the device fix is still resolving, and a lookup at 0,0 is
      // dropped by the controller. Follow the first real fix in.
      _locationWorker = ever<double>(controller.currentLat, (lat) {
        if (lat == 0 || !mounted) return;
        _locationWorker?.dispose();
        _locationWorker = null;
        controller.fetchLiveRiders();
        // And move the camera there. `initialCameraPosition` is exactly that —
        // INITIAL: GoogleMap ignores changes to it once created, so rebuilding
        // this widget with a new centre does nothing. Without this the map
        // opens on the fallback city and silently stays there for the whole
        // session, however long ago the real fix landed.
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(lat, controller.currentLng.value),
            15.5,
          ),
        );
      });
    }

    _liveRiderWorker = ever<List<RideLiveRider>>(
      controller.liveRiders,
      ensureRiderMarkerIcons,
    );
  }

  @override
  void dispose() {
    _liveRiderWorker?.dispose();
    _locationWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _center {
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    return (lat == 0 && lng == 0) ? _fallbackCenter : LatLng(lat, lng);
  }

  /// Open the destination search; a chosen place goes on to confirm pickup.
  Future<void> _openDestinationSearch() async {
    final RidePlace? chosen = await Get.to<RidePlace>(
      () => const RideDestinationSearchScreen(),
    );
    if (chosen == null) return;
    _startTripTo(chosen);
  }

  /// Destination settled → confirm the pickup point on the map next.
  ///
  /// Shared by the search screen and the recent-destination rows: tapping a
  /// past destination is the same decision as typing it, so it skips the search
  /// entirely rather than pre-filling a field the user would have to confirm.
  void _startTripTo(RidePlace place) {
    controller.setDrop(place);
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
          _recentreButton(),
          _sheet(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _map() {
    return Obx(() {
      final center = _center;
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 15.5),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        // Reserve the sheet's footprint. Google Maps treats padding as the
        // viewport's true edges, so the camera target — and the "my location"
        // dot the map draws itself — centre in the visible strip instead of
        // behind the sheet. It also lifts Google's own logo and attribution
        // clear of it, which their terms require stay visible.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * _sheetInitialExtent,
        ),
        onMapCreated: (c) => _mapController = c,
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: center,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          // Reads controller.liveRiders inside this Obx, so a lookup finishing
          // repaints the map on its own.
          ...liveRiderMarkers(controller.liveRiders),
        },
      );
    });
  }

  /// Brings the map back to the device position after the user has panned off
  /// it — the map's own button is off, since it would sit under the sheet.
  ///
  /// Parked just above where the sheet opens. It does not follow the sheet as
  /// it is dragged: a control that slides under the user's thumb mid-drag is
  /// worse than one that stays put.
  Widget _recentreButton() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).size.height * _sheetInitialExtent + 16,
      child: RideCircleButton(
        icon: Icons.my_location,
        iconColor: AppColors.primaryColor,
        onTap: _recentre,
      ),
    );
  }

  void _recentre() {
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    if (lat == 0 && lng == 0) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.5),
    );
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
      // Kept in step with the map's bottom padding — see [_sheetInitialExtent].
      initialChildSize: _sheetInitialExtent,
      minChildSize: 0.30,
      maxChildSize: 0.88,
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
              _recentPlaces(),
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
                'Where do you want to go?',
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

  /// Where this customer has been before, straight under the search field.
  ///
  /// Same list and same rows the destination search opens on — most trips are a
  /// repeat, and a repeat should not cost a search screen and a keyboard. The
  /// hearted state comes along with the place, so a saved destination reads the
  /// same in both places.
  Widget _recentPlaces() {
    return Obx(() {
      final places =
          controller.recentPlaces.take(_recentPlacesShown).toList();
      if (places.isEmpty) {
        // Nothing to show rather than an empty-state block: on a first run the
        // search field is the whole screen's job, and a "no recent trips" panel
        // under it is just furniture.
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: CustomText(
              'Recent',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: RideStyle.inkMuted,
            ),
          ),
          for (final place in places)
            _RecentPlaceRow(
              place: place,
              onTap: () => _startTripTo(place),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------- sub-widgets

/// A past destination in the home sheet.
///
/// Deliberately the same shape as the destination search's own rows — clock
/// glyph, title, address — so the list doesn't change identity when the user
/// opens the full search.
class _RecentPlaceRow extends StatelessWidget {
  const _RecentPlaceRow({required this.place, required this.onTap});

  final RidePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.history, size: 22, color: RideStyle.inkMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    place.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      place.subtitle,
                      fontSize: 13,
                      color: RideStyle.inkMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (place.isSaved) ...[
              const SizedBox(width: 10),
              const Icon(Icons.favorite, size: 18, color: RideStyle.drop),
            ],
          ],
        ),
      ),
    );
  }
}
