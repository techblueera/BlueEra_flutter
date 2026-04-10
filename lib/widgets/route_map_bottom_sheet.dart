import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// A reusable bottom sheet that shows a Google Map with a driving route
/// between the user's current location and a destination.
///
/// Usage:
/// ```dart
/// RouteMapBottomSheet.show(
///   context: context,
///   destinationName: 'Store Name',
///   destinationAddress: '123 Main St',
///   destinationLat: 12.9716,
///   destinationLng: 77.5946,
/// );
/// ```
class RouteMapBottomSheet extends StatefulWidget {
  final String destinationName;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double userLat;
  final double userLng;
  final List<String>? livePhotos;

  const RouteMapBottomSheet({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.userLat,
    required this.userLng,
    this.livePhotos,
  });

  /// Convenience method to show the bottom sheet from anywhere.
  static void show({
    required BuildContext context,
    required String destinationName,
    String destinationAddress = '',
    required double destinationLat,
    required double destinationLng,
    double? userLat,
    double? userLng,
    List<String>? livePhotos,
  }) {
    final uLat = userLat ?? LocationService.lat;
    final uLng = userLng ?? LocationService.lng;

    if (destinationLat == 0.0 && destinationLng == 0.0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteMapBottomSheet(
        destinationName: destinationName,
        destinationAddress: destinationAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        userLat: uLat,
        userLng: uLng,
        livePhotos: livePhotos,
      ),
    );
  }

  @override
  State<RouteMapBottomSheet> createState() => _RouteMapBottomSheetState();
}

class _RouteMapBottomSheetState extends State<RouteMapBottomSheet> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _isLoadingRoute = true;

  LatLng get _userLatLng => LatLng(widget.userLat, widget.userLng);
  LatLng get _destinationLatLng => LatLng(widget.destinationLat, widget.destinationLng);

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _fetchRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _setupMarkers() {
    _markers.addAll({
      Marker(
        markerId: const MarkerId('user'),
        position: _userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    });
  }

  Future<void> _fetchRoute() async {
    try {
      final polylinePoints = PolylinePoints(apiKey: googleMapKey);
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_userLatLng.latitude, _userLatLng.longitude),
          destination: PointLatLng(_destinationLatLng.latitude, _destinationLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (!mounted) return;

      if (result.points.isNotEmpty) {
        final routeCoords = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routeCoords,
              width: 5,
              color: Colors.blue,
              geodesic: true,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _userLatLng.latitude < _destinationLatLng.latitude ? _userLatLng.latitude : _destinationLatLng.latitude,
        _userLatLng.longitude < _destinationLatLng.longitude ? _userLatLng.longitude : _destinationLatLng.longitude,
      ),
      northeast: LatLng(
        _userLatLng.latitude > _destinationLatLng.latitude ? _userLatLng.latitude : _destinationLatLng.latitude,
        _userLatLng.longitude > _destinationLatLng.longitude ? _userLatLng.longitude : _destinationLatLng.longitude,
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.userLat},${widget.userLng}'
      '&destination=${widget.destinationLat},${widget.destinationLng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  List<String> get _validPhotos =>
      widget.livePhotos?.where((p) => p.trim().isNotEmpty).toList() ?? [];

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistanceKm(
      widget.userLat, widget.userLng, widget.destinationLat, widget.destinationLng,
    ).toStringAsFixed(2);
    final hasPhotos = _validPhotos.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * (hasPhotos ? 0.8 : 0.6),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        widget.destinationName,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        '$distance Km Away',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                // Navigate button
                GestureDetector(
                  onTap: _openInGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        CustomText(
                          'Navigate',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Close button
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: CloseButton(
                    style: ButtonStyle(
                      iconSize: WidgetStatePropertyAll(18),
                      padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
                      minimumSize: WidgetStatePropertyAll(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Address
          if (widget.destinationAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: CustomText(
                      widget.destinationAddress,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _destinationLatLng,
                      zoom: 13,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: false,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    mapToolbarEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                      Future.delayed(const Duration(milliseconds: 500), _fitBounds);
                    },
                  ),
                  if (_isLoadingRoute)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const CustomText(
                                'Loading route...',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Live Photos
          if (hasPhotos) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  CustomText(
                    'Live Photos (${_validPhotos.length})',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: StoreLivePhotoWidget(
                livePhotos: _validPhotos,
                natureOfBusiness: widget.destinationName,
                height: 150,
                onViewFullScreen: ({
                  required int index,
                  required List<String> storeImage,
                  required String natureOfBusiness,
                }) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewScreen(
                        appBarTitle: widget.destinationName,
                        subTitle: widget.destinationName,
                        imageUrls: storeImage,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
            ),
          ],
        ],
      ),
    );
  }
}
