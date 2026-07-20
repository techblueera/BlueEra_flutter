import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_cancel_sheets.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_trip_details_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Captain assigned + live tracking (screenshot 5).
///
/// The captain marker is driven by the controller's 5s location poll; this
/// screen only renders. When the ride reaches a terminal state it unwinds the
/// whole flow back to the home screen.
class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  late final Worker _terminalWorker;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _terminalWorker = ever(controller.terminalStatus, _onTerminalStatus);
  }

  @override
  void dispose() {
    _terminalWorker.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onTerminalStatus(RideStatus? status) {
    if (status == null || !mounted) return;
    final message = switch (status) {
      RideStatus.completed => 'Ride completed. Thanks for riding with us!',
      RideStatus.cancelled => 'This ride was cancelled.',
      _ => 'This ride has ended.',
    };
    controller.resetTrip();
    Get.until((route) => route.isFirst);
    Get.snackbar('Ride', message, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _openCancelFlow() async {
    final cancelled = await showRideCancelFlow(controller: controller);
    if (cancelled == true && mounted) {
      controller.resetTrip();
      Get.until((route) => route.isFirst);
    }
  }

  Future<void> _callCaptain() async {
    final phone = controller.activeBooking.value?.captain?.phone;
    if (phone == null || phone.isEmpty) {
      commonSnackBar(message: 'Captain phone number is unavailable');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving tracking must go through the cancel flow, never a silent pop.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openCancelFlow();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Expanded(flex: 5, child: _mapArea()),
            Expanded(flex: 5, child: _sheet()),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _mapArea() {
    return Obx(() {
      final booking = controller.activeBooking.value;
      final pickup = booking?.pickup;
      final captain = booking?.captain;

      final pickupLatLng = pickup != null && pickup.hasCoordinates
          ? LatLng(pickup.latitude, pickup.longitude)
          : const LatLng(23.2599, 77.4126);
      final captainLatLng =
          (captain?.latitude != null && captain?.longitude != null)
              ? LatLng(captain!.latitude!, captain.longitude!)
              : null;

      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: pickupLatLng, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Pickup'),
              ),
              if (captainLatLng != null)
                Marker(
                  markerId: const MarkerId('captain'),
                  position: captainLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: InfoWindow(title: captain?.name ?? 'Captain'),
                ),
            },
            polylines: {
              if (captainLatLng != null)
                Polyline(
                  polylineId: const PolylineId('captain-route'),
                  points: [captainLatLng, pickupLatLng],
                  color: AppColors.primaryColor,
                  width: 5,
                ),
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: RideCircleButton(
              icon: Icons.arrow_back,
              onTap: _openCancelFlow,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                RideCircleButton(
                  icon: Icons.share_outlined,
                  iconColor: AppColors.primaryColor,
                  onTap: () => commonSnackBar(
                    message: 'Ride sharing is coming soon',
                  ),
                ),
                const SizedBox(width: 10),
                RideCircleButton(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primaryColor,
                  onTap: () => commonSnackBar(
                    message: 'Safety options are coming soon',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
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
      child: Obx(() {
        final booking = controller.activeBooking.value;
        if (booking == null) return const SizedBox.shrink();
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).padding.bottom + 18,
          ),
          children: [
            const RideSheetHandle(),
            _etaBanner(booking),
            if (booking.startOtp != null) ...[
              const SizedBox(height: 18),
              _otpRow(booking.startOtp!),
            ],
            const SizedBox(height: 16),
            _captainCard(booking),
            const SizedBox(height: 16),
            _pickupFromRow(booking),
          ],
        );
      }),
    );
  }

  Widget _etaBanner(RideBooking booking) {
    final minutes = booking.pickupEtaMinutes;
    final metres = booking.captainDistanceMeters;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RideStyle.pickup.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
              children: [
                TextSpan(
                  text: booking.status == RideStatus.onTrip
                      ? 'On the way to drop'
                      : 'Pickup in ',
                ),
                if (booking.status != RideStatus.onTrip)
                  TextSpan(
                    text: minutes == null ? '—' : '$minutes mins',
                    style: const TextStyle(color: RideStyle.pickup),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          CustomText(
            metres == null
                ? 'Captain is on the way'
                : 'Captain ${_formatDistance(metres)} away',
            fontSize: 15,
            color: RideStyle.inkMuted,
          ),
        ],
      ),
    );
  }

  String _formatDistance(int metres) =>
      metres >= 1000 ? '${(metres / 1000).toStringAsFixed(1)} km' : '$metres m';

  /// The 4-digit start PIN, one boxed digit each.
  Widget _otpRow(String otp) {
    final digits = otp.split('');
    return Row(
      children: [
        Expanded(
          child: CustomText(
            'Start your order with PIN',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RideStyle.ink,
          ),
        ),
        for (final digit in digits)
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RideStyle.hairline),
            ),
            child: CustomText(
              digit,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: RideStyle.ink,
            ),
          ),
      ],
    );
  }

  Widget _captainCard(RideBooking booking) {
    final captain = booking.captain;
    if (captain == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RideStyle.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      captain.vehicleNumber ?? '',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: RideStyle.ink,
                    ),
                    if (captain.vehicleModel != null)
                      CustomText(
                        captain.vehicleModel!,
                        fontSize: 15,
                        color: RideStyle.inkMuted,
                      ),
                    const SizedBox(height: 2),
                    CustomText(
                      captain.name.toUpperCase(),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: RideStyle.ink,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    backgroundImage: (captain.photoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(captain.photoUrl!)
                        : null,
                    child: (captain.photoUrl?.isEmpty ?? true)
                        ? const Icon(Icons.person,
                            size: 30, color: RideStyle.inkMuted)
                        : null,
                  ),
                  if (captain.rating != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            captain.rating!.toStringAsFixed(1),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: RideStyle.ink,
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star,
                              size: 14, color: RideStyle.action),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _callCaptain,
              icon: const Icon(Icons.phone_in_talk_outlined,
                  size: 20, color: RideStyle.ink),
              label: CustomText(
                'Message ${captain.name.split(' ').first}',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: RideStyle.ink,
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white,
                side: const BorderSide(color: RideStyle.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupFromRow(RideBooking booking) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Pickup From',
                fontSize: 14,
                color: RideStyle.inkMuted,
              ),
              const SizedBox(height: 2),
              CustomText(
                booking.pickup.fullAddress,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: RideStyle.ink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
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
    );
  }
}
