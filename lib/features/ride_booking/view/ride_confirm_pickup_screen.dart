import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_vehicle_select_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_marker_icons.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// "Check your pickup point" (screenshot 2).
///
/// A fixed centre pin over a draggable map: the map moves under the pin and
/// the address resolves on camera-idle, which is steadier than dragging a
/// marker and is the pattern every ride app uses.
class RideConfirmPickupScreen extends StatefulWidget {
  const RideConfirmPickupScreen({super.key});

  @override
  State<RideConfirmPickupScreen> createState() =>
      _RideConfirmPickupScreenState();
}

class _RideConfirmPickupScreenState extends State<RideConfirmPickupScreen>
    with RideLiveRiderMarkers {
  final RideBookingController controller = Get.find<RideBookingController>();
  GoogleMapController? _mapController;

  /// How often the live vehicles around the pin are refreshed while this screen
  /// is open. Riders move, and the customer can sit here a while deciding on a
  /// pickup point, so the map would otherwise show where everyone was when the
  /// screen opened.
  static const Duration _liveRiderRefresh = Duration(minutes: 1);

  /// Drives that refresh. Lives and dies with the screen — polling is only
  /// worth its cost while someone is looking at the map.
  Timer? _liveRiderTimer;

  /// Rebuilds the marker artwork when a lookup brings back a vehicle type that
  /// hasn't been rasterised yet.
  Worker? _liveRiderWorker;

  /// Coordinate under the centre pin right now. Updated on camera-idle.
  late LatLng _pinPosition;

  /// Address for [_pinPosition]; null while it is being resolved.
  RidePlace? _resolved;
  bool _isResolving = false;

  /// Monotonic id for the in-flight reverse geocode. A drag fires several
  /// lookups and they don't come back in order — without this, a slow response
  /// for an old pin lands last and overwrites the address for where the user
  /// actually stopped.
  int _resolveSeq = 0;

  /// Stops listening for a late device fix once the screen goes away.
  Worker? _locationWorker;

  /// Whether the camera has moved since the last idle — i.e. this idle is the
  /// pin LANDING somewhere new, not the map settling into its opening frame.
  /// Gates the tick, so opening the screen is silent.
  bool _cameraMoved = false;

  /// The move currently settling was made by [_moveCameraTo], not by the user's
  /// finger. Silences the tick for it — see that method.
  bool _programmaticMove = false;

  /// False while the pin is still sitting on the fallback centre — no seeded
  /// pickup, no device fix yet.
  ///
  /// The rider lookup and the address resolve are both gated on it. The
  /// controller drops a lookup at 0,0, but this screen never asks for 0,0: a
  /// [GoogleMap] must be handed SOME initial camera position, so it opens on
  /// [_fallbackCentre] rather than the null island — and querying that would
  /// draw a map full of vehicles 800 km from the customer, while geocoding it
  /// would put a strange city's address in the card. Flips true when the fix
  /// lands, or as soon as the user drags the map — at that point they are
  /// looking at a real place and it is the honest answer either way.
  bool _hasRealPin = false;

  /// Where to point the map the moment it exists.
  ///
  /// The device fix routinely lands BEFORE `onMapCreated` on a cold open, and
  /// `_mapController` is null until then — so the camera move was going out to
  /// nothing and the screen sat on the fallback centre for good. Parking the
  /// target here and applying it on creation is what makes the late fix stick.
  LatLng? _pendingCameraTarget;

  /// Frame only until a real point is known — never somewhere to confirm from.
  /// Central India, so the first frame is a country-scale view rather than a
  /// street in a city the user has nothing to do with.
  static const LatLng _fallbackCentre = LatLng(23.2599, 77.4126);
  static const double _fallbackZoom = 4;
  static const double _pinZoom = 17;

  @override
  void initState() {
    super.initState();
    final existing = controller.pickup.value;
    _hasRealPin = (existing != null && existing.hasCoordinates) ||
        controller.currentLat.value != 0 ||
        controller.currentLng.value != 0;
    _pinPosition = existing != null && existing.hasCoordinates
        ? LatLng(existing.latitude, existing.longitude)
        : (_hasRealPin
            ? LatLng(controller.currentLat.value, controller.currentLng.value)
            : _fallbackCentre);
    // Only adopt the seeded pickup if it carries a real address. The
    // controller seeds `{title: 'Current location', subtitle: ''}` from the GPS
    // fix alone, which would otherwise sit in the card as a blank second line
    // and never update as the map moves.
    _resolved = (existing != null && existing.subtitle.isNotEmpty)
        ? existing
        : null;

    // The device fix is resolved asynchronously in the controller, so on a cold
    // open this screen is often built before it lands and frames the fallback
    // centre instead of the user. Follow the first real fix in.
    if (existing == null || !existing.hasCoordinates) {
      _locationWorker = ever<double>(controller.currentLat, (lat) {
        if (lat == 0 || !mounted) return;
        _locationWorker?.dispose();
        _locationWorker = null;
        final target = LatLng(lat, controller.currentLng.value);
        // setState because the address card is showing "Locating…" off
        // [_hasRealPin] and has to stop.
        setState(() {
          _pinPosition = target;
          _hasRealPin = true;
        });
        // Camera-idle then fires and resolves the address for it.
        _moveCameraTo(target);
        // The opening lookup was gated on the fallback centre — run it now we
        // have a real point.
        _fetchLiveRiders();
      });

      // And make sure a fix is actually coming. The controller resolves one
      // once, in `onInit`; if that attempt failed (permission still ungranted,
      // location services off, cold-GPS timeout) nothing ever retried, so this
      // screen framed the fallback centre forever and the worker above had
      // nothing to wait for. This is the retry.
      controller.ensureCurrentLocation();
    }

    _liveRiderWorker = ever<List<RideLiveRider>>(
      controller.liveRiders,
      ensureRiderMarkerIcons,
    );
    // Draw what is out there immediately, then keep it current.
    _fetchLiveRiders();
    _liveRiderTimer =
        Timer.periodic(_liveRiderRefresh, (_) => _fetchLiveRiders());
  }

  /// One `riders/live-in-radius` lookup around the CURRENT pin.
  ///
  /// [_pinPosition], not `controller.pickup` — the pickup isn't committed until
  /// Confirm, so the controller's copy is still wherever the customer arrived
  /// from. Reading the pin means each tick shows the vehicles around the point
  /// they are actually considering.
  ///
  /// No vehicle type is passed: nothing upstream picks a class any more, so the
  /// controller's default coarse category (`rider`) is what we want here.
  void _fetchLiveRiders() {
    if (!_hasRealPin) return;
    controller.fetchLiveRiders(
      atLat: _pinPosition.latitude,
      atLng: _pinPosition.longitude,
    );
  }

  /// Point the camera at [target], now or as soon as the map exists.
  ///
  /// Never call `_mapController?.animateCamera` directly for a move that has to
  /// happen: before `onMapCreated` that `?.` throws the move away silently,
  /// which is exactly how a fix arriving during the first frames left the
  /// screen stranded on the fallback centre.
  void _moveCameraTo(LatLng target) {
    final map = _mapController;
    if (map == null) {
      _pendingCameraTarget = target;
      return;
    }
    // The pin tick answers a GESTURE. A move we made ourselves still fires
    // `onCameraMoveStarted`, so without this the screen clicks at the user as
    // it centres on them.
    _programmaticMove = true;
    map.animateCamera(CameraUpdate.newLatLngZoom(target, _pinZoom));
  }

  @override
  void dispose() {
    _liveRiderTimer?.cancel();
    _liveRiderWorker?.dispose();
    _locationWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Resolve the address under the pin once the camera settles. Reverse
  /// geocoding on every frame of a drag would be both janky and expensive.
  Future<void> _onCameraIdle() async {
    final position = _pinPosition;
    if (_cameraMoved) {
      _cameraMoved = false;
      final wasProgrammatic = _programmaticMove;
      _programmaticMove = false;
      // The pin has landed somewhere real — either the user drove the map here,
      // or we centred it on the device fix. Either way it is no longer the
      // fallback centre.
      if (!_hasRealPin) setState(() => _hasRealPin = true);
      if (!wasProgrammatic) _playPinTick();
    }
    // Don't put the fallback centre's address in the card. It would read as a
    // resolved pickup, and Confirm would light up on a point in a city the user
    // has never been to.
    if (!_hasRealPin) return;
    final seq = ++_resolveSeq;
    setState(() => _isResolving = true);
    try {
      final place = await _resolvePin(position);
      // A newer idle already started — its answer is the one that counts.
      if (!mounted || seq != _resolveSeq) return;
      setState(() => _resolved = place);
    } finally {
      if (mounted && seq == _resolveSeq) {
        setState(() => _isResolving = false);
      }
    }
  }

  /// The keypress-style tick that marks the pin settling on a new point.
  ///
  /// Fired at camera-idle rather than when the address comes back: the tick has
  /// to answer the gesture, and the reverse geocode can take a second. It is
  /// the platform's own keyboard click, not a bundled asset, so it follows the
  /// system sound setting — a user who has key clicks off gets silence here too.
  ///
  /// Paired with the selection haptic because iOS has no [SystemSoundType.click]
  /// (it no-ops there); the haptic is what carries the feedback on that side.
  void _playPinTick() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  /// Reverse-geocode the coordinate under the pin.
  ///
  /// Broadcast dispatch has no pickup-points endpoint (guide §6), so this uses
  /// the on-device geocoder — the same one the old booking screens use for
  /// pincode lookup. It must key off [position], not the seeded pickup:
  /// echoing `controller.pickup` back is why the card used to freeze on
  /// "Current location" no matter where the map was dragged.
  Future<RidePlace> _resolvePin(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Nearest thing to a name, falling back down to the street.
        final title = _firstNonEmpty([p.name, p.street, p.subLocality]) ??
            'Selected pickup point';
        // Everything else, de-duped against the title so we don't render
        // "Jodhpur, Jodhpur, Rajasthan".
        final subtitle = <String?>[
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ]
            .whereType<String>()
            .where((s) => s.isNotEmpty && s != title)
            .toSet()
            .join(', ');

        return RidePlace(
          title: title,
          subtitle: subtitle,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (_) {
      // Geocoder unavailable / offline — fall through to coordinates.
    }

    // Never leave the card empty: coordinates are a poor address but they are
    // honest, and `hasCoordinates` still lets the user confirm.
    return RidePlace(
      title: 'Selected pickup point',
      subtitle: '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  void _confirm() {
    final place = _resolved;
    if (place == null || !place.hasCoordinates) return;
    controller.setPickup(place);
    // Start the fare catalog here rather than on arrival at the picker.
    //
    // Confirming the pickup is the moment both ends of the trip are finally
    // known, and the quote needs a route lookup and a reverse geocode before it
    // even reaches the server — so kicking it off now buys the picker most of
    // that latency for free. It is one call for every vehicle type
    // (`allVehicleTypes=true`), so nothing here depends on which vehicle the
    // user goes on to pick.
    //
    // Unawaited on purpose: the navigation must not wait on the network. The
    // picker asks for the quote in its own initState too — so that it is still
    // correct when reached by any other route — but it asks with
    // `fetchQuotesIfNeeded`, which joins THIS request instead of duplicating
    // it. One `fare/riders/dynamic` call per trip, made as early as possible.
    unawaited(controller.fetchQuotes());
    Get.to(() => const RideVehicleSelectScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(child: _mapArea()),
          _bottomPanel(),
        ],
      ),
    );
  }

  Widget _mapArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Obx so a finished live-rider lookup repaints the markers. It wraps
        // the map rather than sitting inside it because `markers` is a
        // constructor argument — the platform view itself is reused, only the
        // marker set is diffed.
        Obx(
          () => GoogleMap(
            // Zoomed right out until we know where the user is, so the opening
            // frame reads as "still locating" rather than as a confident (and
            // wrong) street-level answer in a city they never asked about.
            initialCameraPosition: CameraPosition(
              target: _pinPosition,
              zoom: _hasRealPin ? _pinZoom : _fallbackZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: liveRiderMarkers(controller.liveRiders),
            onMapCreated: (c) {
              _mapController = c;
              // A fix that landed while the platform view was still coming up.
              final pending = _pendingCameraTarget;
              if (pending != null) {
                _pendingCameraTarget = null;
                _moveCameraTo(pending);
              }
            },
            onCameraMoveStarted: () => _cameraMoved = true,
            onCameraMove: (position) => _pinPosition = position.target,
            onCameraIdle: _onCameraIdle,
          ),
        ),
        // The two halves of the marker, both registered on the map centre: the
        // ring IS the coordinate, the label hangs above it.
        const _PickupGroundRing(),
        const Positioned.fill(child: _PickupPin()),
        Positioned(
          left: 16,
          bottom: 20,
          child: RideCircleButton(icon: Icons.arrow_back, onTap: Get.back),
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: RideCircleButton(
            icon: Icons.my_location,
            iconColor: AppColors.primaryColor,
            onTap: _recentre,
          ),
        ),
      ],
    );
  }

  void _recentre() {
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    if (lat == 0 && lng == 0) {
      // Nothing to centre on yet. The button used to do nothing at all here,
      // and it is the one place the user can ask for their location again — so
      // it asks, and frames whatever comes back.
      controller.ensureCurrentLocation().then((_) {
        if (!mounted) return;
        final fixedLat = controller.currentLat.value;
        final fixedLng = controller.currentLng.value;
        if (fixedLat == 0 && fixedLng == 0) return;
        _moveCameraTo(LatLng(fixedLat, fixedLng));
      });
      return;
    }
    _moveCameraTo(LatLng(lat, lng));
  }

  Widget _bottomPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).padding.bottom + 18,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: RideStyle.pickup, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Check your pickup point',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: RideStyle.ink,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      'Select a nearby point for easier pickup',
                      fontSize: 14,
                      color: RideStyle.inkMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _addressCard(),
          const SizedBox(height: 20),
          RidePrimaryButton(
            label: 'Confirm pickup',
            enabled: _resolved?.hasCoordinates == true && !_isResolving,
            onTap: _confirm,
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RideStyle.pickup, width: 1.4),
      ),
      // "Locating…" covers waiting for the device fix as well as waiting for
      // the reverse geocode. Before the fix, the pin is on the fallback centre
      // and there is deliberately no address to show.
      child: (_isResolving || !_hasRealPin) && _resolved == null
          ? CustomText(
              'Locating…',
              fontSize: 15,
              color: RideStyle.inkMuted,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _resolved?.title ?? 'Pickup point',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: RideStyle.ink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                CustomText(
                  _resolved?.subtitle ?? '',
                  fontSize: 14,
                  color: RideStyle.inkMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

/// The green "Pickup Point" label with its stem, hanging above the map centre.
///
/// Fills the map and aligns itself rather than taking a fixed offset: the stem
/// has to end ON the centre, and the label's height moves with the user's text
/// scale, so a hardcoded padding drifts off the point on any device that isn't
/// at 1.0. Bottom-aligning it inside the TOP HALF of the map puts its foot on
/// the centre line by construction.
class _PickupPin extends StatelessWidget {
  const _PickupPin();

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
                    color: RideStyle.pickup,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: RideStyle.floatingShadow,
                  ),
                  child: CustomText(
                    'Pickup Point',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                // Stops at the ring's core, which the ring draws over.
                Container(width: 2, height: 14, color: RideStyle.pickup),
              ],
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

/// The circle on the ground under the pin — the point the address is being read
/// from.
///
/// A pin alone is ambiguous about which pixel it means, and on a map the whole
/// question is "which spot is this". The ring gives the coordinate a footprint
/// the eye can land on while the map slides underneath, and the solid core is
/// the point itself.
class _PickupGroundRing extends StatelessWidget {
  const _PickupGroundRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Translucent, so the map underneath still reads through the footprint
        // — it marks the spot without hiding what is on it.
        color: RideStyle.pickup.withValues(alpha: 0.16),
        border: Border.all(
          color: RideStyle.pickup.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: RideStyle.floatingShadow,
          ),
        ),
      ),
    );
  }
}
