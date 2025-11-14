import 'dart:async';

import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../auth/controller/live_trach_rider_controller.dart';

class TrackRiderLiveLocationPage extends StatefulWidget {
  const TrackRiderLiveLocationPage({super.key, required this.riderId, required this.dropLat, required this.dropLng});
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
        title: "Track Your Rider",
      ),
      body: Obx(() {
        if ((orderController.liveLng.value == 0) ||
            (orderController.liveLng.value == 0)){
          return  Center(
            child: CustomText("Finding Rider Location..."),
          );
        }else{
          return SimpleMapplsTracking(
            startLng: orderController.liveLng.value ?? 0,
            startLat: orderController.liveLat.value ?? 0,
            endLat: widget.dropLat,
            endLng: widget.dropLng,
          );
        }
      }),
    );
  }
}


class SimpleMapplsTracking extends StatefulWidget {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const SimpleMapplsTracking({
    super.key,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  @override
  State<SimpleMapplsTracking> createState() => _SimpleMapplsTrackingState();
}

class _SimpleMapplsTrackingState extends State<SimpleMapplsTracking> {
  MapplsMapController? mapController;
  Line? polyline;
  Symbol? startMarker;
  Symbol? endMarker;
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
  Future<void> _updateRiderOnMap() async {
    if (mapController == null) return;

    final newLat = riderController.liveLat.value;
    final newLng = riderController.liveLng.value;

    if (newLat == 0 || newLng == 0) return; // invalid skip

    final newPosition = LatLng(newLat, newLng);

    try {
      // MOVE existing start marker instead of recreating
      if (startMarker != null) {
        await mapController!.updateSymbol(
          startMarker!,
          SymbolOptions(
            geometry: newPosition,
            iconSize: 1.0,
          ),
        );
      }

      // UPDATE POLYLINE
      if (polyline != null) {
        await mapController!.updateLine(
          polyline!,
          LineOptions(
            geometry: [
              newPosition, // updated rider location
              LatLng(widget.endLat, widget.endLng)
            ],
            lineColor: '#2196F3',
            lineWidth: 5.0,
            lineOpacity: 0.8,
          ),
        );
      }

    } catch (e) {
      print("Error updating rider marker: $e");
    }
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
      // Remove old circle
      if (liveLocationCircle != null) {
        await mapController!.removeCircle(liveLocationCircle!);
      }

      // Add new circle for live location
      liveLocationCircle = await mapController!.addCircle(
        CircleOptions(
          geometry: currentPosition!,
          circleRadius: 15.0,
          circleColor: '#2196F3',
          circleOpacity: 0.8,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    } catch (e) {
      print('Error updating live location: $e');
    }
  }

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    if (mapController == null) return;

    try {
      // Add start marker (default pin)
      startMarker = await mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.startLat, widget.startLng),
          iconSize: 1.0,
        ),
      );

      // Add end marker (default pin)
      endMarker = await mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.endLat, widget.endLng),
          iconSize: 1.0,
        ),
      );

      // Create polyline
      polyline = await mapController!.addLine(
        LineOptions(
          geometry: [
            LatLng(widget.startLat, widget.startLng),
            LatLng(widget.endLat, widget.endLng),
          ],
          lineColor: '#2196F3',
          lineWidth: 5.0,
          lineOpacity: 0.8,
        ),
      );

      await _fitBounds();
    } catch (e) {
      print('Error in onStyleLoaded: $e');
    }
  }

  Future<void> _fitBounds() async {
    if (mapController == null) return;

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          widget.startLat < widget.endLat ? widget.startLat : widget.endLat,
          widget.startLng < widget.endLng ? widget.startLng : widget.endLng,
        ),
        northeast: LatLng(
          widget.startLat > widget.endLat ? widget.startLat : widget.endLat,
          widget.startLng > widget.endLng ? widget.startLng : widget.endLng,
        ),
      );

      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
            bounds, left: 50, top: 50, right: 50, bottom: 50),
      );
    } catch (e) {

    }
  }
  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MapplsMap(
      onMapCreated: (controller) => _onMapCreated(controller),
      initialCameraPosition: CameraPosition(
        target: LatLng(26.7836, 80.9013),
        zoom: 14.0,
      ),
      onStyleLoadedCallback: _onStyleLoaded,
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.tracking,
    );
  }
}
