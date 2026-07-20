import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_tracking_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_cancel_sheets.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_trip_details_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// "Searching in progress" (screenshot 4).
///
/// Owns no polling of its own — [RideBookingController] already started it on
/// booking. This screen only reacts: when a captain is attached it replaces
/// itself with the tracking screen, and when the search dies it pops back.
class RideSearchingScreen extends StatefulWidget {
  const RideSearchingScreen({super.key});

  @override
  State<RideSearchingScreen> createState() => _RideSearchingScreenState();
}

class _RideSearchingScreenState extends State<RideSearchingScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  late final Worker _statusWorker;
  GoogleMapController? _mapController;

  /// Fare bumps offered while searching, matching the reference chips.
  static const List<double> _boostAmounts = [10, 20, 30, 40];

  @override
  void initState() {
    super.initState();
    // A single worker owns every transition out of this screen, so there is
    // exactly one place that can navigate away.
    _statusWorker = ever(controller.activeBooking, _onBookingChanged);
  }

  @override
  void dispose() {
    _statusWorker.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onBookingChanged(RideBooking? booking) {
    if (booking == null || !mounted) return;

    if (booking.status.hasCaptain) {
      // `off` replaces this route: once a captain is assigned there is nothing
      // to come back to here.
      Get.off(() => const RideTrackingScreen());
      return;
    }

    if (!booking.status.isActive) {
      _handleSearchFailed(booking.status);
    }
  }

  void _handleSearchFailed(RideStatus status) {
    final message = status == RideStatus.cancelled
        ? 'This ride was cancelled.'
        : 'No captains available right now. Please try again.';
    controller.resetTrip();
    Get.back();
    Get.snackbar('Ride', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Back / cancel while searching. No captain is attached yet, so this skips
  /// the "already on the way" confirmation and goes straight to reasons.
  Future<void> _confirmCancel() async {
    final cancelled = await showRideCancelFlow(
      controller: controller,
      skipCaptainConfirm: true,
    );
    if (cancelled == true && mounted) {
      controller.resetTrip();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Backing out of a live search must cancel the booking, not orphan it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Expanded(flex: 3, child: _mapArea()),
            Expanded(flex: 7, child: _sheet()),
          ],
        ),
      ),
    );
  }

  Widget _mapArea() {
    return Obx(() {
      final pickup = controller.activeBooking.value?.pickup;
      final center = pickup != null && pickup.hasCoordinates
          ? LatLng(pickup.latitude, pickup.longitude)
          : const LatLng(23.2599, 77.4126);
      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            circles: {
              // Pulsing-style search radius around the pickup.
              Circle(
                circleId: const CircleId('search-radius'),
                center: center,
                radius: 900,
                fillColor: AppColors.primaryColor.withOpacity(0.10),
                strokeColor: AppColors.primaryColor.withOpacity(0.35),
                strokeWidth: 1,
              ),
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                RideCircleButton(
                  icon: Icons.close,
                  onTap: _confirmCancel,
                ),
                const SizedBox(width: 10),
                Expanded(child: _statusPill()),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: RideStyle.floatingShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: CustomText(
              'Waiting for Captain to accept',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: RideStyle.ink,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ sheet

  Widget _sheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
        boxShadow: RideStyle.sheetShadow,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        children: [
          const RideSheetHandle(),
          const SizedBox(height: 8),
          CustomText(
            'Searching in progress',
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: RideStyle.ink,
          ),
          const SizedBox(height: 14),
          _progressBar(),
          const SizedBox(height: 20),
          _fareCard(),
          // Fare-bump chips are hidden: broadcast dispatch has no raise-fare
          // endpoint (RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §6), so the
          // bump would never reach the server or re-ring riders. Shipping it
          // would charge more for nothing.
          if (RideBookingController.kFareRaiseEnabled) ...[
            const SizedBox(height: 20),
            _boostCard(),
          ],
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Obx(
      () => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: controller.searchProgress.value,
          minHeight: 20,
          backgroundColor: RideStyle.surfaceTint,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B3A6B)),
        ),
      ),
    );
  }

  Widget _fareCard() {
    return Obx(() {
      final booking = controller.activeBooking.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RideStyle.hairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.two_wheeler, size: 34, color: RideStyle.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Total Fare',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: RideStyle.ink,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    '₹${(booking?.fare ?? 0).toStringAsFixed(0)}',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => showRideTripDetailsSheet(controller),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RideStyle.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: CustomText(
                'Trip Details',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RideStyle.ink,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// "Increase your chances by adding extra" — each chip raises the offered
  /// fare, which the backend re-broadcasts to nearby captains.
  Widget _boostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RideStyle.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Increase your chances by adding extra',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: RideStyle.ink,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final amount in _boostAmounts)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _BoostChip(
                      amount: amount,
                      onTap: () => controller.raiseFare(amount),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostChip extends StatelessWidget {
  const _BoostChip({required this.amount, required this.onTap});

  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: CustomText(
            '+ ₹${amount.toStringAsFixed(0)}',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: RideStyle.ink,
          ),
        ),
      ),
    );
  }
}
