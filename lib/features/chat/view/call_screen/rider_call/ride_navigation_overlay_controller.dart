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
  }) {
    riderLat.value = riderLatVal;
    riderLng.value = riderLngVal;
    destLat.value = destLatVal;
    destLng.value = destLngVal;
    destLabel.value = destLabelVal;
    customerName.value = customerNameVal;
    fareAmount.value = fareAmountVal;
    polylinePoints.assignAll(routePoints);
    screenType.value = type;
    screenParams.assignAll(params);
    isOverlayVisible.value = true;
  }

  void hideOverlay() {
    isOverlayVisible.value = false;
    polylinePoints.clear();
    screenParams.clear();
    screenType.value = '';
    customerName.value = '';
    fareAmount.value = 0.0;
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
  }
}
