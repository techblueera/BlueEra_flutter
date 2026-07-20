import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_cancel_sheets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Trip-details sheet (screenshot 6): vehicle, both endpoints, total fare,
/// payment mode and the Cancel Ride entry point.
///
/// Opening the cancel flow from here closes this sheet first, so the user
/// never ends up with two stacked sheets.
Future<void> showRideTripDetailsSheet(RideBookingController controller) {
  return Get.bottomSheet<void>(
    _RideTripDetailsSheet(controller: controller),
    isScrollControlled: true,
    barrierColor: Colors.black54,
  );
}

class _RideTripDetailsSheet extends StatelessWidget {
  const _RideTripDetailsSheet({required this.controller});

  final RideBookingController controller;

  Future<void> _openCancelFlow() async {
    Get.back(); // close this sheet before stacking the cancel flow
    final cancelled = await showRideCancelFlow(controller: controller);
    if (cancelled == true) {
      controller.resetTrip();
      // Unwind to the ride home screen — the tracking route is now dead.
      Get.until((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final booking = controller.activeBooking.value;
      if (booking == null) return const SizedBox.shrink();

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: RideStyle.surfaceTint,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RideStyle.sheetRadius),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RideSheetHandle(),
              _vehicleHeader(booking),
              const SizedBox(height: 14),
              _locationCard(booking),
              const SizedBox(height: 14),
              _fareCard(booking),
              const SizedBox(height: 20),
              RideOutlineButton(
                label: 'Cancel Ride',
                color: RideStyle.danger,
                onTap: _openCancelFlow,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _vehicleHeader(RideBooking booking) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
      child: Row(
        children: [
          const Icon(Icons.two_wheeler, size: 44, color: RideStyle.ink),
          const SizedBox(width: 16),
          CustomText(
            booking.vehicleName.isEmpty ? 'Ride' : booking.vehicleName,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: RideStyle.ink,
          ),
        ],
      ),
    );
  }

  Widget _locationCard(RideBooking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Location Details',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: RideStyle.ink,
          ),
          const SizedBox(height: 16),
          _endpointRow(
            place: booking.pickup,
            color: RideStyle.pickup,
            isSaved: booking.pickup.isSaved,
          ),
          // Dotted connector between the two endpoints.
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 1.5,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: RideStyle.inkMuted,
                ),
              ),
            ),
          ),
          _endpointRow(
            place: booking.drop,
            color: RideStyle.drop,
            isSaved: booking.drop.isSaved,
          ),
        ],
      ),
    );
  }

  Widget _endpointRow({
    required RidePlace place,
    required Color color,
    required bool isSaved,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: RideEndpointDot(color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                place.title,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                place.subtitle,
                fontSize: 14,
                color: RideStyle.inkMuted,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.toggleSavedPlace(place),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              size: 22,
              color: isSaved ? RideStyle.drop : RideStyle.inkMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fareCard(RideBooking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Total Fare',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: RideStyle.ink,
                ),
                CustomText(
                  '₹${booking.fare.toStringAsFixed(0)}',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: RideStyle.ink,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: RideStyle.hairline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 22, color: RideStyle.ink),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    booking.paymentMode == 'CASH'
                        ? 'Paying via cash'
                        : 'Paying online',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: RideStyle.ink,
                  ),
                ),
                // Payment mode is locked once a captain is assigned — the fare
                // has already been broadcast to them on those terms.
                if (!(booking.status.hasCaptain))
                  GestureDetector(
                    onTap: () => controller.setPaymentMode(
                      booking.paymentMode == 'CASH' ? 'ONLINE' : 'CASH',
                    ),
                    child: CustomText(
                      'Change',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
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
