import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Customer-side "Your Ongoing Ride/Booking" card shown at the top of the
/// Inquiry tab while an accepted ride/goods booking is being tracked.
///
/// Driven entirely by [RideNavigationOverlayController] (populated when the
/// customer minimises [FareCallQueueScreen] after a rider accepts — for both
/// the passenger-booking and multi-order goods flows). The controller is
/// cleared by the `ride:completed` / cancel socket handlers, so the card
/// disappears automatically when the ride ends. Tapping the card re-opens the
/// live tracking screen.
class CustomerOngoingRideCard extends StatelessWidget {
  const CustomerOngoingRideCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RideNavigationOverlayController>()) {
      return const SizedBox.shrink();
    }
    final ctrl = Get.find<RideNavigationOverlayController>();

    return Obx(() {
      // Subscribe to the reactive state.
      ctrl.screenType.value;
      ctrl.screenParams.length;
      ctrl.riderLat.value;

      if (!ctrl.hasOngoingCustomerRide) return const SizedBox.shrink();

      final riderName = ctrl.customerName.value.isNotEmpty
          ? ctrl.customerName.value
          : 'Rider';
      final distanceLabel = _distanceLabel(ctrl);
      final time = ctrl.bookingTimeLabel.value;
      final contact = ctrl.riderContact.value;

      return Padding(
        padding: EdgeInsets.fromLTRB(
            SizeConfig.size12, SizeConfig.size10, SizeConfig.size12, SizeConfig.size4),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openTracking(ctrl),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                CachedAvatarWidget(
                  imageUrl: ctrl.riderImage.value.isEmpty
                      ? null
                      : ctrl.riderImage.value,
                  size: 52,
                  borderRadius: 26,
                  showProfileOnFullScreen: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'Your Ongoing Ride/Booking',
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              riderName,
                              fontSize: SizeConfig.size13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distanceLabel != null) ...[
                            CustomText(
                              '  |  ',
                              fontSize: SizeConfig.size13,
                              color: AppColors.grayText,
                            ),
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.primaryColor),
                            const SizedBox(width: 2),
                            CustomText(
                              distanceLabel,
                              fontSize: SizeConfig.size13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _onCallTap(ctrl, contact),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call,
                            color: Colors.green, size: 20),
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        time,
                        fontSize: SizeConfig.size10,
                        color: AppColors.grayText,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// "<n> KM Away" computed from the last-known rider position to the pickup,
  /// or null when no live position is available yet.
  String? _distanceLabel(RideNavigationOverlayController ctrl) {
    final rLat = ctrl.riderLat.value;
    final rLng = ctrl.riderLng.value;
    final pLat = ctrl.destLat.value;
    final pLng = ctrl.destLng.value;
    if (rLat == 0.0 || rLng == 0.0 || pLat == 0.0 || pLng == 0.0) return null;
    final km = geo.Geolocator.distanceBetween(rLat, rLng, pLat, pLng) / 1000;
    if (km <= 0) return null;
    return '${km < 1 ? km.toStringAsFixed(1) : km.toStringAsFixed(0)} KM Away';
  }

  /// Call the rider directly when a contact is known, otherwise open the
  /// tracking screen (which exposes the in-app call control).
  void _onCallTap(RideNavigationOverlayController ctrl, String contact) {
    if (contact.isNotEmpty) {
      launchUrl(Uri.parse('tel:$contact'));
    } else {
      _openTracking(ctrl);
    }
  }

  /// Re-open the live tracking screen. Capture the orderId before hiding the
  /// overlay (hideOverlay clears the params), mirroring the floating mini-map.
  void _openTracking(RideNavigationOverlayController ctrl) {
    final orderId = (ctrl.screenParams['orderId'] ?? '').toString();
    ctrl.hideOverlay();
    Get.to(() => FareCallQueueScreen(orderId: orderId));
  }
}
