import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_vehicle_select_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
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

class _RideConfirmPickupScreenState extends State<RideConfirmPickupScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  GoogleMapController? _mapController;

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

  @override
  void initState() {
    super.initState();
    final existing = controller.pickup.value;
    _pinPosition = existing != null && existing.hasCoordinates
        ? LatLng(existing.latitude, existing.longitude)
        : LatLng(
            controller.currentLat.value == 0
                ? 23.2599
                : controller.currentLat.value,
            controller.currentLng.value == 0
                ? 77.4126
                : controller.currentLng.value,
          );
    // Only adopt the seeded pickup if it carries a real address. The
    // controller seeds `{title: 'Current location', subtitle: ''}` from the GPS
    // fix alone, which would otherwise sit in the card as a blank second line
    // and never update as the map moves.
    _resolved = (existing != null && existing.subtitle.isNotEmpty)
        ? existing
        : null;

    // The device fix is resolved asynchronously in the controller, so on a cold
    // open this screen is often built before it lands and frames the fallback
    // city instead of the user. Follow the first real fix in.
    if (existing == null || !existing.hasCoordinates) {
      _locationWorker = ever<double>(controller.currentLat, (lat) {
        if (lat == 0 || !mounted) return;
        _locationWorker?.dispose();
        _locationWorker = null;
        final target = LatLng(lat, controller.currentLng.value);
        _pinPosition = target;
        // Camera-idle then fires and resolves the address for it.
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 17),
        );
      });
    }
  }

  @override
  void dispose() {
    _locationWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Resolve the address under the pin once the camera settles. Reverse
  /// geocoding on every frame of a drag would be both janky and expensive.
  Future<void> _onCameraIdle() async {
    final position = _pinPosition;
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
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pinPosition, zoom: 17),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (c) => _mapController = c,
          onCameraMove: (position) => _pinPosition = position.target,
          onCameraIdle: _onCameraIdle,
        ),
        // Centre pin sits slightly above true centre so its point, not its
        // body, marks the coordinate.
        const Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: _PickupPin(),
        ),
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
    if (lat == 0 && lng == 0) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17),
    );
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
      child: _isResolving && _resolved == null
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

/// The green "Pickup Point" label with its stem, drawn over the map centre.
class _PickupPin extends StatelessWidget {
  const _PickupPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        Container(width: 2, height: 12, color: RideStyle.pickup),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: RideStyle.floatingShadow,
          ),
        ),
      ],
    );
  }
}
