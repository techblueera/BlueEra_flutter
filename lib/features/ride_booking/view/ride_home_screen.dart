import 'dart:async';

import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/service/ride_reverse_geocode_service.dart';
import 'package:BlueEra/features/ride_booking/view/ride_confirm_pickup_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_destination_search_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_marker_icons.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ------------------------------------------------------- pickup pin on map
  //
  // The map is not a backdrop any more: it carries a fixed centre pin, the map
  // moves under it, and the address resolves when it settles — the same
  // interaction as the confirm-pickup screen, brought forward so the customer
  // can correct a pickup that landed on the wrong side of the road without
  // leaving home. Tapping the resolved address goes on to confirm it.

  /// Coordinate under the centre pin right now. Updated on camera-move.
  LatLng? _pinPosition;

  /// Address under the pin; null until the first resolve lands.
  RidePlace? _pinPlace;

  /// A lookup is pending or in flight — greys the address pill's tap so a stale
  /// address can't be carried into the confirm screen.
  bool _isResolvingPin = false;

  /// Monotonic id for the in-flight reverse geocode. A drag fires several
  /// lookups and they don't come back in order — without this, a slow response
  /// for an old pin lands last and overwrites the address for where the user
  /// actually stopped.
  int _resolveSeq = 0;

  /// Whether the camera has moved since the last idle — i.e. this idle is the
  /// pin LANDING somewhere new, not the map settling into its opening frame.
  /// Gates the tick, so opening the screen is silent.
  bool _cameraMoved = false;

  /// The move currently settling was made by us (recentre, or following the
  /// first device fix in), not by the user's finger. Silences the tick.
  bool _programmaticMove = false;

  /// How long the camera must stay STILL before the address is looked up.
  ///
  /// Tuned for someone hunting rather than someone who has arrived. A customer
  /// looking for a gate pans, pauses half a second to read the map, pans again
  /// — and every one of those pauses used to buy a geocode for a place they
  /// were never going to pick. 800 ms sits above a reading pause and below the
  /// point where a user who HAS settled starts wondering if it's broken.
  ///
  /// It also absorbs the fact that `onCameraIdle` is not one event per gesture:
  /// a fling settles, reports idle, drifts a few pixels and reports again.
  static const Duration _settleDebounce = Duration(milliseconds: 800);

  /// Runs that debounce. Cancelled on every new idle and on dispose.
  Timer? _settleTimer;

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
        final target = LatLng(lat, controller.currentLng.value);
        setState(() {
          _pinPosition = target;
          // The strip is showing "Locating…" off this and has to stop.
          _hasRealPin = true;
        });
        // Ours, not the user's — don't click at them for it.
        _programmaticMove = true;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 15.5),
        );
      });
    }

    // Seed the pin with the opening frame so the first camera-idle has a point
    // to resolve even when the fix was already in hand.
    _pinPosition = _center;
    _hasRealPin = controller.currentLat.value != 0 ||
        controller.currentLng.value != 0 ||
        controller.drop.value?.hasCoordinates == true;
    // Already on a real point at build time (warm open, fix in hand): the
    // opening camera-idle resolves it. On a cold open the strip reads
    // "Locating…" until the fix lands or the user drags.
    if (_hasRealPin) _isResolvingPin = true;

    _liveRiderWorker = ever<List<RideLiveRider>>(
      controller.liveRiders,
      ensureRiderMarkerIcons,
    );
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _liveRiderWorker?.dispose();
    _locationWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Opening frame for the map.
  ///
  /// Prefers an already-chosen drop over the raw device fix: coming back here
  /// after starting a trip should show the destination the user picked, not
  /// snap back to wherever the phone thinks they are.
  LatLng get _center {
    final drop = controller.drop.value;
    if (drop != null && drop.hasCoordinates) {
      return LatLng(drop.latitude, drop.longitude);
    }
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    return (lat == 0 && lng == 0) ? _fallbackCenter : LatLng(lat, lng);
  }

  /// False while the pin is still sitting on the fallback centre — no device
  /// fix, no previously chosen drop. Gates the address lookup, because
  /// geocoding the fallback would put a stranger's city in the strip and let
  /// the user carry it into the flow.
  ///
  /// A FIELD, not a getter off the controller. It was a getter, and that was a
  /// bug: on a device whose fix hadn't landed (or had failed) it stayed false
  /// forever, so dragging the pin around a perfectly real street never resolved
  /// anything and the strip sat empty. Dragging the map IS the user telling us
  /// they are looking at a real place — so the drag flips it, exactly as
  /// [RideConfirmPickupScreen] already did.
  late bool _hasRealPin;

  // --------------------------------------------------------- pin interaction

  /// The map started moving again.
  ///
  /// Kills anything pending: the debounce timer, AND — via the sequence bump —
  /// the result of a lookup already out on the wire. Without this a lookup
  /// armed by the previous pause fires mid-drag and names a point the map is
  /// currently flying over, which is how a picker ends up briefly showing an
  /// address that was never under the pin.
  ///
  /// The strip goes back to its pending state at the same time, so it never
  /// shows a settled-looking address for somewhere the pin has already left.
  void _onCameraMoveStarted() {
    _cameraMoved = true;
    _settleTimer?.cancel();
    _resolveSeq++;
    if (!_isResolvingPin && _hasRealPin) {
      setState(() => _isResolvingPin = true);
    }
  }

  /// Camera settled. The tick fires immediately — it answers the gesture — but
  /// the address lookup waits out [_settleDebounce] first.
  void _onCameraIdle() {
    if (_cameraMoved) {
      _cameraMoved = false;
      final wasProgrammatic = _programmaticMove;
      _programmaticMove = false;
      // The pin has landed somewhere real — the user drove the map here, or we
      // centred it on the device fix. Either way it is not the fallback now.
      if (!_hasRealPin) setState(() => _hasRealPin = true);
      if (!wasProgrammatic) _playPinTick();
    }
    if (!_hasRealPin || _pinPosition == null) return;
    // Show the pending state at once so the strip can't be tapped through with
    // a stale address while the debounce runs.
    if (!_isResolvingPin) setState(() => _isResolvingPin = true);
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDebounce, _resolvePin);
  }

  /// The debounced half of [_onCameraIdle].
  ///
  /// Cheap unless the pin genuinely moved somewhere new — the service answers
  /// from its movement threshold and grid cache before it will pay for a
  /// platform lookup.
  ///
  /// It deliberately does NOT write the place into the controller. The drop is
  /// only committed when the user taps the strip ([_confirmPinAsDrop]) — and
  /// writing to a controller observable from here also fed the map's own `Obx`,
  /// which reads the same values to frame itself.
  Future<void> _resolvePin() async {
    final position = _pinPosition;
    if (position == null) return;
    final seq = ++_resolveSeq;
    try {
      final place = await RideReverseGeocodeService.instance.resolve(
        position,
        fallbackTitle: 'Selected drop point',
      );
      // A newer idle already started — its answer is the one that counts.
      if (!mounted || seq != _resolveSeq) return;
      setState(() => _pinPlace = place);
    } finally {
      if (mounted && seq == _resolveSeq) {
        setState(() => _isResolvingPin = false);
      }
    }
  }

  /// Tapping the address strip commits the pin as the DESTINATION and moves on
  /// to confirm the pickup — the same landing as choosing a place out of the
  /// search or the recents list.
  ///
  /// One difference: it does NOT go into Recent here. A pin is dragged around
  /// while hunting and every stop is a candidate, not a decision. It gets
  /// remembered only if the ride is actually booked — see
  /// [RideBookingController.bookRide].
  void _confirmPinAsDrop() {
    final place = _pinPlace;
    if (place == null || !place.hasCoordinates || _isResolvingPin) return;
    _startTripTo(place, rememberInRecents: false);
  }

  /// The keypress-style tick that marks the pin settling on a new point. The
  /// platform's own click, so it follows the system sound setting; paired with
  /// the selection haptic because iOS has no [SystemSoundType.click].
  void _playPinTick() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
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
  /// Shared by the search screen, the recent-destination rows and the map pin:
  /// tapping a past destination is the same decision as typing it, so it skips
  /// the search entirely rather than pre-filling a field the user would have to
  /// confirm. Only the pin passes [rememberInRecents] false — see
  /// [_confirmPinAsDrop].
  void _startTripTo(RidePlace place, {bool rememberInRecents = true}) {
    controller.setDrop(place, remember: rememberInRecents);
    Get.to(() => const RideConfirmPickupScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _map(),
          _dropPinOverlay(),
          _backButton(),
          _recentreButton(),
          _dropAddressStrip(),
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
        onCameraMoveStarted: _onCameraMoveStarted,
        onCameraMove: (position) => _pinPosition = position.target,
        onCameraIdle: _onCameraIdle,
        // There used to be a green Marker pinned to `center`. It is a fixed
        // centre OVERLAY now (see [_dropPinOverlay]): a marker is anchored to
        // the world and slides away the moment the map moves, which is the
        // opposite of what a "drag the map under the pin" picker needs.
        markers: {
          // Reads controller.liveRiders inside this Obx, so a lookup finishing
          // repaints the map on its own.
          ...liveRiderMarkers(controller.liveRiders),
        },
      );
    });
  }

  /// The fixed pin over the map centre — label, stem and ground ring.
  ///
  /// Sized to stop at the sheet's top edge rather than filling the screen. The
  /// map is given the same amount as bottom [padding], and Google Maps treats
  /// padding as the viewport's true edges — so the camera target sits at the
  /// centre of the STRIP ABOVE THE SHEET, not at the centre of the widget. A
  /// pin centred on the widget would float well below the coordinate it claims
  /// to mark.
  Widget _dropPinOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: _sheetHeight(context),
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: const [
            _DropGroundRing(),
            Positioned.fill(child: _DropPinLabel()),
          ],
        ),
      ),
    );
  }

  double _sheetHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * _sheetInitialExtent;

  /// Brings the map back to the device position after the user has panned off
  /// it — the map's own button is off, since it would sit under the sheet.
  ///
  /// Parked just above where the sheet opens. It does not follow the sheet as
  /// it is dragged: a control that slides under the user's thumb mid-drag is
  /// worse than one that stays put.
  Widget _recentreButton() {
    return Positioned(
      right: 16,
      // Stacked above the address pill, which now owns the strip directly
      // above the sheet.
      bottom: _sheetHeight(context) + _stripReservedHeight + 14,
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
    // Ours, not the user's — silence the pin tick for it.
    _programmaticMove = true;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.5),
    );
  }

  /// Vertical room the address strip occupies, used to park the recentre button
  /// clear of it. Tracks the strip's own padding + line height — if that gets
  /// taller again, this moves with it.
  static const double _stripReservedHeight = 36;

  /// The live address under the pin, floating just above the sheet — the same
  /// place it sits in the reference design.
  ///
  /// This is the screen's answer to "where are you going": whatever the pin is
  /// on, tapping the strip makes it the DESTINATION and moves on to confirm the
  /// pickup. It replaces the old top-of-screen pickup pill, which showed an
  /// address that never tracked the map.
  Widget _dropAddressStrip() {
    final ready = _pinPlace?.hasCoordinates == true && !_isResolvingPin;
    return Positioned(
      left: 16,
      right: 16,
      bottom: _sheetHeight(context) + 12,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Inert while a lookup is pending, so the trip can't be started on an
        // address that belongs to the previous point.
        onTap: ready ? _confirmPinAsDrop : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // OPAQUE mint → white. It reads as a frosted, see-through strip,
            // but nothing actually shows through it.
            //
            // A real alpha wash was wrong here: the map underneath is not a
            // uniform backdrop — it is roads, park green, a yellow highway —
            // so a translucent strip picks all of that up and the address sits
            // on a different colour every time the map moves. These flat tints
            // are the colour that wash produces over white, frozen, so the
            // strip looks identical wherever the pin is.
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFEAF6EF), Color(0xFFFFFFFF)],
              // Fades out before halfway: these addresses are nearly always
              // long, and the part that has to stay readable is the part that
              // runs past the fade.
              stops: [0.0, 0.45],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE6EFE9), width: 0.8),
            boxShadow: RideStyle.floatingShadow,
          ),
          child: Row(
            children: [
              // Green to match the reference strip, even though the pin above
              // is the red drop marker — asked for explicitly.
              const RideEndpointDot(color: RideStyle.pickup, size: 12),
              const SizedBox(width: 9),
              Expanded(
                child: CustomText(
                  _stripLabel(),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: RideStyle.ink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_isResolvingPin)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 1.8),
                )
              else if (ready)
                // Says the strip is a button, not a caption — without it the
                // one action on this screen is invisible.
                const Icon(Icons.arrow_forward_rounded,
                    size: 17, color: RideStyle.action),
            ],
          ),
        ),
      ),
    );
  }

  /// What the strip reads. The resolved address wins; the two waiting states
  /// are distinct on purpose — "Locating…" means we don't know where the phone
  /// is yet, "Getting address…" means we do and are naming it.
  String _stripLabel() {
    final resolved = _pinPlace?.fullAddress;
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return _hasRealPin ? 'Getting address…' : 'Locating…';
  }

  Widget _backButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: RideCircleButton(icon: Icons.arrow_back, onTap: Get.back),
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

/// The "Drop Point" label with its stem, hanging above the map centre.
///
/// Fills its box and aligns itself rather than taking a fixed offset: the stem
/// has to end ON the centre, and the label's height moves with the user's text
/// scale, so a hardcoded padding drifts off the point on any device that isn't
/// at 1.0. Bottom-aligning it inside the TOP HALF of the box puts its foot on
/// the centre line by construction.
///
/// Same construction as the confirm-pickup screen's pin, deliberately — the two
/// are the same gesture, and the pin arriving in a different shape when the
/// user taps through would read as a different control. Only the colour differs,
/// and it carries the meaning: red is the destination, green is the pickup.
class _DropPinLabel extends StatelessWidget {
  const _DropPinLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: RideStyle.drop,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: RideStyle.floatingShadow,
                  ),
                  child: CustomText(
                    'Drop Point',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                // Stops at the ring's core, which the ring draws over.
                Container(width: 2, height: 14, color: RideStyle.drop),
              ],
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

/// The circle on the ground under the pin — the point the address is read from.
///
/// A pin alone is ambiguous about which pixel it means, and on a map the whole
/// question is "which spot is this". The ring gives the coordinate a footprint
/// the eye can land on while the map slides underneath, and the solid core is
/// the point itself.
class _DropGroundRing extends StatelessWidget {
  const _DropGroundRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Translucent, so the map underneath still reads through the footprint
        // — it marks the spot without hiding what is on it.
        color: RideStyle.drop.withValues(alpha: 0.16),
        border: Border.all(
          color: RideStyle.drop.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: RideStyle.drop,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: RideStyle.floatingShadow,
          ),
        ),
      ),
    );
  }
}

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
