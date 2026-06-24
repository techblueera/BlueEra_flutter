import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller that holds the state for the floating mini-map overlay
/// shown when the rider minimises the pickup/ride navigation screen.
class RideNavigationOverlayController extends GetxController {
  final isOverlayVisible = false.obs;

  // Map data
  final riderLat = 0.0.obs;
  final riderLng = 0.0.obs;
  final destLat = 0.0.obs;
  final destLng = 0.0.obs;
  final destLabel = ''.obs;
  final customerName = ''.obs;
  final fareAmount = 0.0.obs;

  // Customer-side ("customer_tracking") extras — used by the Inquiry-tab
  // "Your Ongoing Ride/Booking" card. `customerName` doubles as the rider name
  // for that flow; these add the avatar, call action and timestamp the card
  // needs. Empty/no-op for the rider-side navigation overlays.
  final riderImage = ''.obs;
  final riderContact = ''.obs;
  final dropLabel = ''.obs;
  final bookingTimeLabel = ''.obs;
  final orderForLabel = ''.obs;

  // Route polyline points
  final polylinePoints = <LatLng>[].obs;

  // Which screen to return to: 'pickup' or 'ride'
  final screenType = ''.obs;

  // Full params needed to re-open the screen
  final screenParams = <String, dynamic>{}.obs;

  void showOverlay({
    required double riderLatVal,
    required double riderLngVal,
    required double destLatVal,
    required double destLngVal,
    required String destLabelVal,
    required String customerNameVal,
    required double fareAmountVal,
    required List<LatLng> routePoints,
    required String type,
    required Map<String, dynamic> params,
    String riderImageVal = '',
    String riderContactVal = '',
    String dropLabelVal = '',
    String bookingTimeLabelVal = '',
    String orderForLabelVal = '',
  }) {
    riderLat.value = riderLatVal;
    riderLng.value = riderLngVal;
    destLat.value = destLatVal;
    destLng.value = destLngVal;
    destLabel.value = destLabelVal;
    customerName.value = customerNameVal;
    fareAmount.value = fareAmountVal;
    riderImage.value = riderImageVal;
    riderContact.value = riderContactVal;
    dropLabel.value = dropLabelVal;
    bookingTimeLabel.value = bookingTimeLabelVal;
    orderForLabel.value = orderForLabelVal;
    polylinePoints.assignAll(routePoints);
    screenType.value = type;
    screenParams.assignAll(params);
    isOverlayVisible.value = true;
  }

  /// True when an accepted customer ride is being tracked — drives the
  /// customer-side "Your Ongoing Ride/Booking" card in the Inquiry tab.
  bool get hasOngoingCustomerRide =>
      hasOngoingRide && screenType.value == 'customer_tracking';

  /// Rebuild the customer-tracking state from a persisted snapshot on app
  /// relaunch. Populates only what the card needs and does NOT raise the
  /// floating mini-map ([isOverlayVisible] stays false) — the card is enough;
  /// tapping it re-opens the live screen.
  void restoreCustomerRide({
    required String orderId,
    required String riderName,
    String riderImageVal = '',
    String riderContactVal = '',
    String pickupLabel = '',
    String dropLabelVal = '',
    String bookingTimeLabelVal = '',
    double riderLatVal = 0.0,
    double riderLngVal = 0.0,
    double pickupLat = 0.0,
    double pickupLng = 0.0,
  }) {
    if (orderId.isEmpty) return;
    customerName.value = riderName;
    riderImage.value = riderImageVal;
    riderContact.value = riderContactVal;
    destLabel.value = pickupLabel;
    dropLabel.value = dropLabelVal;
    bookingTimeLabel.value = bookingTimeLabelVal;
    riderLat.value = riderLatVal;
    riderLng.value = riderLngVal;
    destLat.value = pickupLat;
    destLng.value = pickupLng;
    screenType.value = 'customer_tracking';
    screenParams.assignAll({'orderId': orderId});
    isOverlayVisible.value = false;
  }

  void hideOverlay() {
    isOverlayVisible.value = false;
    polylinePoints.clear();
    screenParams.clear();
    screenType.value = '';
    customerName.value = '';
    fareAmount.value = 0.0;
    riderImage.value = '';
    riderContact.value = '';
    dropLabel.value = '';
    bookingTimeLabel.value = '';
    orderForLabel.value = '';
  }

  /// Dismiss the overlay visually but keep ride data so the ongoing ride card
  /// can still show in the orders tab.
  void dismissOverlay() {
    isOverlayVisible.value = false;
  }

  /// Whether there is an ongoing ride (data present even if overlay is hidden).
  bool get hasOngoingRide =>
      screenParams.isNotEmpty && screenType.value.isNotEmpty;

  /// Fully clear all ride data (call when ride is truly over).
  void clearRideData() {
    isOverlayVisible.value = false;
    polylinePoints.clear();
    screenParams.clear();
    screenType.value = '';
    customerName.value = '';
    fareAmount.value = 0.0;
    riderLat.value = 0.0;
    riderLng.value = 0.0;
    destLat.value = 0.0;
    destLng.value = 0.0;
    destLabel.value = '';
    riderImage.value = '';
    riderContact.value = '';
    dropLabel.value = '';
    bookingTimeLabel.value = '';
    orderForLabel.value = '';
  }
}
