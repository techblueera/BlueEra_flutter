import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../environment_config.dart';
import '../../../auth/controller/live_trach_rider_controller.dart';

class TrackRiderLiveLocationPage extends StatefulWidget {
  const TrackRiderLiveLocationPage(
      {super.key,
      required this.riderId,
      required this.dropLat,
      required this.dropLng});

  final double dropLat;
  final double dropLng;
  final String riderId;

  @override
  State<TrackRiderLiveLocationPage> createState() =>
      _TrackRiderLiveLocationPageState();
}

class _TrackRiderLiveLocationPageState
    extends State<TrackRiderLiveLocationPage> {
  final orderController = Get.put(LiveTrachRiderController());

  @override
  void initState() {
    orderController.fetchStream(widget.riderId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.trackYourRider,
      ),
      body: Obx(() {
        if ((orderController.liveLng.value == 0) ||
            (orderController.liveLat.value == 0)) {
          return Center(
            child: CustomText(AppStrings.findingRiderLocation),
          );
        } else {
          return SimpleGoogleMapsTracking(
            startLng: orderController.liveLng.value,
            startLat: orderController.liveLat.value,
            endLat: widget.dropLat,
            endLng: widget.dropLng,
          );
        }
      }),
    );
  }
}

class SimpleGoogleMapsTracking extends StatefulWidget {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const SimpleGoogleMapsTracking({
    super.key,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  @override
  State<SimpleGoogleMapsTracking> createState() => _SimpleGoogleMapsTrackingState();
}

class _SimpleGoogleMapsTrackingState extends State<SimpleGoogleMapsTracking> {
  List<LatLng> polylineCoordinates = []; // Store road points here
  // PolylinePoints polylinePoints = PolylinePoints(apiKey: googleMapKey);
  GoogleMapController? mapController;
  Marker? startMarker;
  Marker? endMarker;
  Set<Polyline> _polylines = {};
  Circle? liveLocationCircle;
  final riderController = Get.find<LiveTrachRiderController>();

  StreamSubscription<Position>? positionStream;
  LatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();

    ever(riderController.liveLat, (_) => _updateRiderOnMap());
    ever(riderController.liveLng, (_) => _updateRiderOnMap());

  }

  Future<void> _getRoutePolyline() async {
    // final riderLat = 11.6940;
    // final riderLng = 77.9710;
    final riderLat = riderController.liveLat.value;
    final riderLng = riderController.liveLng.value;

    if (riderLat == 0 || riderLng == 0) return;

    PolylinePoints polylinePoints =
    PolylinePoints(apiKey: googleMapKey);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(riderLat, riderLng), // 🔥 LIVE rider location
        destination: PointLatLng(widget.endLat, widget.endLng),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final List<LatLng> routeCoords = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: routeCoords,
            width: 6,
            color: Colors.blue,
            geodesic: true,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
    } else {
      print("NO ROUTE FOUND: ${result.errorMessage}");
    }
  }




  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getRoutePolyline(); // Call the road-fetching function here
    _addInitialMarkers();
  }

  void _addInitialMarkers() {
    setState(() {
      startMarker = Marker(
        markerId: const MarkerId('rider_marker'),
        position: LatLng(widget.startLat, widget.startLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      endMarker = Marker(
        markerId: const MarkerId('drop_marker'),
        position: LatLng(widget.endLat, widget.endLng),
      );
    });
  }

  Future<void> _updateRiderOnMap() async {
    final newLat = riderController.liveLat.value;
    final newLng = riderController.liveLng.value;
    if (newLat == 0 || newLng == 0) return;

    final newPosition = LatLng(newLat, newLng);

    setState(() {
      startMarker = startMarker?.copyWith(positionParam: newPosition);
    });

    // 🔥 REFRESH ROAD ROUTE FROM LIVE RIDER
    await _getRoutePolyline();

    // Optional smooth camera follow
    mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }



  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateLiveLocation(position);
    });
  }

  Future<void> _updateLiveLocation(Position position) async {
    if (mapController == null) return;

    currentPosition = LatLng(position.latitude, position.longitude);

    try {
    setState(() {
      liveLocationCircle = Circle(
        circleId: CircleId('live_location_circle'),
        center: currentPosition!,
        radius: 15.0,
        fillColor: Colors.blue.withOpacity(0.5),
        strokeColor: Colors.white,
        strokeWidth: 3,
      );
    });
    } catch (e) {
      print('Error updating live location: $e');
    }
  }

  // Future<void> _addInitialMarkersAndPolyline() async {
  //   final start = LatLng(widget.startLat, widget.startLng);
  //   final end = LatLng(widget.endLat, widget.endLng);
  //
  //   setState(() {
  //     startMarker = Marker(
  //       markerId: MarkerId('start_marker'),
  //       position: start,
  //     );
  //     endMarker = Marker(
  //       markerId: MarkerId('end_marker'),
  //       position: end,
  //     );
  //     polyline = Polyline(
  //       polylineId: PolylineId('route_polyline'),
  //       points: [start, end],
  //       color: Colors.blue,
  //       width: 5,
  //     );
  //   });
  // }



  // Future<void> _fitBounds() async {
  //   if (mapController == null || startMarker == null || endMarker == null) return;
  //
  //   final LatLng southwest = LatLng(
  //     widget.startLat < widget.endLat ? widget.startLat : widget.endLat,
  //     widget.startLng < widget.endLng ? widget.startLng : widget.endLng,
  //   );
  //   final LatLng northeast = LatLng(
  //     widget.startLat > widget.endLat ? widget.startLat : widget.endLat,
  //     widget.startLng > widget.endLng ? widget.startLng : widget.endLng,
  //   );
  //
  //   final LatLngBounds bounds = LatLngBounds(southwest: southwest, northeast: northeast);
  //
  //   mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  // }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.startLat, widget.startLng),
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: {
            if (startMarker != null) startMarker!,
            if (endMarker != null) endMarker!,
          },
          polylines: _polylines, // 🔥 THIS WILL SHOW REAL ROAD ROUTE
          circles: {
            if (liveLocationCircle != null) liveLocationCircle!,
          },
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    "Rider is ${(_calculateTotalDistance()).toStringAsFixed(1)} km away",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  double _calculateTotalDistance() {
    double total = 0;
    // Calculate distance from rider to end point using Geolocator math
    total = Geolocator.distanceBetween(
      riderController.liveLat.value,
      riderController.liveLng.value,
      widget.endLat,
      widget.endLng,
    );
    return total / 1000; // Convert meters to KM
  }
}
