import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_searching_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

class _RideVehicleSelectScreenState extends State<RideVehicleSelectScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  GoogleMapController? _mapController;

  /// Re-frames the camera when the road route lands, so the view fits the
  /// actual path rather than the straight line between the endpoints.
  Worker? _routeWorker;

  @override
  void initState() {
    super.initState();
    controller.fetchQuotes();
    // Frame both endpoints once the map is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    _routeWorker = ever<List<LatLng>>(controller.routePoints, (_) {
      if (mounted) _fitBounds();
    });
  }

  @override
  void dispose() {
    _routeWorker?.dispose();
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
          Expanded(flex: 6, child: _vehicleSheet()),
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

  Widget _vehicleSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
        boxShadow: RideStyle.sheetShadow,
      ),
      child: Obx(() {
        if (controller.isQuoting.value) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.4),
          );
        }
        if (controller.vehicleOptions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CustomText(
                'No vehicles available for this route right now.',
                fontSize: 14,
                color: RideStyle.inkMuted,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Column(
          children: [
            const RideSheetHandle(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                itemCount: controller.vehicleOptions.length,
                itemBuilder: (context, index) {
                  final option = controller.vehicleOptions[index];
                  return _VehicleRow(
                    option: option,
                    isSelected:
                        controller.selectedVehicle.value?.quoteId ==
                            option.quoteId,
                    onTap: () => controller.selectVehicle(option),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  // --------------------------------------------------------------- fare bar

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
            final selected = controller.selectedVehicle.value;
            return RidePrimaryButton(
              label: selected == null ? 'Book' : 'Book ${selected.name}',
              enabled: selected != null,
              isLoading: controller.isBooking.value,
              onTap: _book,
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

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final RideVehicleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  /// Clock time the ride is expected to end, derived from the ETA so the row
  /// reads "Drop 3:16 pm" rather than "in 12 mins".
  String get _dropLabel {
    final minutes = option.dropEtaMinutes;
    if (minutes == null) return '';
    final arrival = DateTime.now().add(Duration(minutes: minutes));
    final hour12 = arrival.hour % 12 == 0 ? 12 : arrival.hour % 12;
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour < 12 ? 'am' : 'pm';
    return 'Drop $hour12:$minute $period';
  }

  IconData get _icon {
    switch (option.code) {
      case 'BIKE':
        return Icons.two_wheeler;
      case 'AUTO':
        return Icons.electric_rickshaw;
      case 'PARCEL':
        return Icons.inventory_2_outlined;
      default:
        return Icons.local_taxi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? RideStyle.ink : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Icon(_icon, size: 36, color: RideStyle.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          option.name,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: RideStyle.ink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (option.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: RideStyle.pickup.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            option.badge!,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RideStyle.pickup,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      option.description!,
                      fontSize: 13,
                      color: RideStyle.inkMuted,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CustomText(
                        _dropLabel,
                        fontSize: 13,
                        color: RideStyle.inkMuted,
                      ),
                      if (option.seats != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person,
                            size: 14, color: RideStyle.inkMuted),
                        CustomText(
                          ' ${option.seats}',
                          fontSize: 13,
                          color: RideStyle.inkMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CustomText(
              '₹${option.fare.toStringAsFixed(0)}',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: RideStyle.ink,
            ),
          ],
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
