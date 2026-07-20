import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_vehicle_select_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
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
    _resolved = existing;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Resolve the address under the pin once the camera settles. Reverse
  /// geocoding on every frame of a drag would be both janky and expensive.
  Future<void> _onCameraIdle() async {
    setState(() => _isResolving = true);
    try {
      // The pickup-points endpoint doubles as reverse geocoding: it returns
      // the snapped address plus nearby suggested points.
      final place = await _resolvePin(_pinPosition);
      if (!mounted) return;
      setState(() => _resolved = place);
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  /// While the controller runs in stub mode this returns a synthetic address;
  /// once the backend is live it will come from `places/pickup-points`.
  Future<RidePlace> _resolvePin(LatLng position) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final existing = controller.pickup.value;
    return RidePlace(
      title: existing?.title.isNotEmpty == true && existing!.hasCoordinates
          ? existing.title
          : 'Selected pickup point',
      subtitle: existing?.subtitle ??
          '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
      latitude: position.latitude,
      longitude: position.longitude,
    );
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
