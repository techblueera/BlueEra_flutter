import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import '../../business_chat/widgets/track_rider_live_location_page.dart';
import 'ride_navigation_overlay_controller.dart';
import 'rider_pickup_navigation_screen.dart';
import 'passenger_destination_screen.dart';

/// Draggable floating mini-map overlay shown when rider minimises the
/// pickup / ride navigation screen.
class RideNavigationFloatingOverlay extends StatelessWidget {
  const RideNavigationFloatingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RideNavigationOverlayController());

    return Obx(() {
      if (!controller.isOverlayVisible.value) return const SizedBox.shrink();

      return _DraggableMiniMap(controller: controller);
    });
  }
}

class _DraggableMiniMap extends StatefulWidget {
  final RideNavigationOverlayController controller;
  const _DraggableMiniMap({required this.controller});

  @override
  State<_DraggableMiniMap> createState() => _DraggableMiniMapState();
}

class _DraggableMiniMapState extends State<_DraggableMiniMap> {
  double _xPos = 16;
  double _yPos = 120;
  GoogleMapController? _miniMapController;

  static const double _width = 180;
  static const double _height = 200;

  RideNavigationOverlayController get ctrl => widget.controller;

  LatLng get _riderLatLng => LatLng(ctrl.riderLat.value, ctrl.riderLng.value);
  LatLng get _destLatLng => LatLng(ctrl.destLat.value, ctrl.destLng.value);

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('rider_mini'),
          position: _riderLatLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('dest_mini'),
          position: _destLatLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };

  Set<Polyline> get _polylines => {
        if (ctrl.polylinePoints.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('mini_route'),
            points: ctrl.polylinePoints.toList(),
            width: 3,
            color: const Color(0xFF4285F4),
            geodesic: true,
          ),
      };

  void _fitBounds() {
    if (_miniMapController == null) return;
    final a = _riderLatLng;
    final b = _destLatLng;
    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    _miniMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
  }

  void _onTap() {
    // Capture params before hiding (hideOverlay clears them)
    final p = Map<String, dynamic>.from(ctrl.screenParams);
    final type = ctrl.screenType.value;

    // Hide overlay and navigate back to the full screen
    ctrl.hideOverlay();

    if (type == 'pickup') {
      Get.to(() => RiderPickupNavigationScreen(
            pickupLocation: p['pickupLocation'] ?? '',
            dropLocation: p['dropLocation'] ?? '',
            pickupLat: (p['pickupLat'] as num?)?.toDouble() ?? 0,
            pickupLng: (p['pickupLng'] as num?)?.toDouble() ?? 0,
            dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
            dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
            fareAmount: (p['fareAmount'] as num?)?.toDouble() ?? 0,
            distanceKm: (p['distanceKm'] as num?)?.toDouble() ?? 0,
            customerName: p['customerName'] ?? '',
            customerImage: p['customerImage'] ?? '',
            otp: p['otp'] ?? '',
            paymentMethod: p['paymentMethod'] ?? 'Cash',
            orderId: p['orderId'] ?? '',
            customerUserId: p['customerUserId'] ?? '',
          ));
    } else if (type == 'customer_tracking') {
      Get.to(() => FareCallQueueScreen(
            orderId: p['orderId'] ?? '',
          ));
    } else if (type == 'track_rider') {
      // Customer tapped the floating mini-map for a chat-initiated rider
      // tracking session — re-open the full live-tracking page.
      Get.to(() => TrackRiderLiveLocationPage(
            riderId: p['riderId'] ?? '',
            dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
            dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
            orderId: p['orderId'],
          ));
    } else {
      Get.to(() => PassengerDestinationScreen(
            pickupLocation: p['pickupLocation'] ?? '',
            dropLocation: p['dropLocation'] ?? '',
            pickupLat: (p['pickupLat'] as num?)?.toDouble() ?? 0,
            pickupLng: (p['pickupLng'] as num?)?.toDouble() ?? 0,
            dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
            dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
            fareAmount: (p['fareAmount'] as num?)?.toDouble() ?? 0,
            distanceKm: (p['distanceKm'] as num?)?.toDouble() ?? 0,
            customerName: p['customerName'] ?? '',
            customerImage: p['customerImage'] ?? '',
            paymentMethod: p['paymentMethod'] ?? 'Cash',
            orderId: p['orderId'] ?? '',
          ));
    }
  }

  @override
  void dispose() {
    _miniMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos = (_xPos + details.delta.dx)
                .clamp(0, screenWidth - _width);
            _yPos = (_yPos + details.delta.dy)
                .clamp(0, screenHeight - _height);
          });
        },
        onTap: _onTap,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black45,
          child: Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00C853),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Mini map
                  AbsorbPointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _riderLatLng,
                        zoom: 13,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      rotateGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      liteModeEnabled: false,
                      onMapCreated: (c) {
                        _miniMapController = c;
                        Future.delayed(
                          const Duration(milliseconds: 500),
                          _fitBounds,
                        );
                      },
                    ),
                  ),

                  // Bottom info strip
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ctrl.customerName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${ctrl.fareAmount.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenSans',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => ctrl.dismissOverlay(),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
