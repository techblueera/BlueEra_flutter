import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/route_polyline_service.dart';
import 'package:BlueEra/core/map/osrm_routing.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

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
  final VoidCallback? visitCallback;

  const RouteMapBottomSheet({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.userLat,
    required this.userLng,
    this.visitCallback,
    this.livePhotos,
  });

  /// Convenience method to show the bottom sheet from anywhere.
  static void show({
    required BuildContext context,
    required String destinationName,
    String destinationAddress = '',
    required double destinationLat,
    required double destinationLng,
    VoidCallback? visitCallback,
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
        visitCallback: visitCallback,
      ),
    );
  }

  @override
  State<RouteMapBottomSheet> createState() => _RouteMapBottomSheetState();
}

class _RouteMapBottomSheetState extends State<RouteMapBottomSheet> {
  BlueMapController? _mapController;
  List<LatLng> _routeCoords = const [];

  List<BlueMapPolyline> get _polylines => [
        if (_routeCoords.length >= 2)
          BlueMapPolyline(
            id: "route",
            points: _routeCoords,
            width: 5,
            color: Colors.blue,
          ),
      ];
  bool _isLoadingRoute = true;

  LatLng get _userLatLng => LatLng(widget.userLat, widget.userLng);
  LatLng get _destinationLatLng => LatLng(widget.destinationLat, widget.destinationLng);

  @override
  void initState() {
    super.initState();
    // Markers derive from state — nothing to set up.
    _fetchRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// User position and destination. Derived from state — nothing to set up.
  List<BlueMapMarker> get _markers => [
        BlueMapMarker(
          id: 'user',
          position: _userLatLng,
          icon: Icons.location_on,
          color: Colors.blue,
          anchor: BlueMarkerAnchor.bottom,
        ),
        BlueMapMarker(
          id: 'destination',
          position: _destinationLatLng,
          icon: Icons.location_on,
          color: Colors.red,
          anchor: BlueMarkerAnchor.bottom,
        ),
      ];

  Future<void> _fetchRoute() async {
    try {
      final result = await RoutePolylineService.fetch(
        origin: PointLatLng(_userLatLng.latitude, _userLatLng.longitude),
        destination: PointLatLng(
            _destinationLatLng.latitude, _destinationLatLng.longitude),
      );

      if (!mounted) return;

      if (result != null && result.points.isNotEmpty) {
        final routeCoords = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        setState(() => _routeCoords = routeCoords);
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
    _mapController?.fitPoints([_userLatLng, _destinationLatLng], padding: 60);
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
      // height: MediaQuery.of(context).size.height * (hasPhotos ? 0.7 : 0.4),
      // height: MediaQuery.of(context).size.height * (hasPhotos ? 0.8 : 0.6),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    child: InkWell(
                     onTap: widget.visitCallback!=null ? widget.visitCallback : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            widget.destinationName,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '$distance Km Away',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Visit Store button
                  if(widget.visitCallback!=null)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).maybePop();
                      widget.visitCallback!();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          CustomText(
                            AppStrings.view,
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
        
        
        
            const SizedBox(height: 4),
        
            // Map (card view)
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greyE5, width: 1.0),
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      BlueMap(
                        initialCenter: _destinationLatLng,
                        initialZoom: 13,
                        markers: _markers,
                        polylines: _polylines,
                        showZoomControls: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          // No delay: BlueMap queues camera work until ready.
                          _fitBounds();
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
              ),
            ),

            // Expanded(
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //     child: Card(
            //       elevation: 3,
            //       color: AppColors.white,
            //       clipBehavior: Clip.antiAlias,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(16),
            //         side: BorderSide(color: AppColors.greyE5, width: 0.5),
            //       ),
            //       child: Stack(
            //         children: [
            //           GoogleMap(
            //           initialCameraPosition: CameraPosition(
            //             target: _destinationLatLng,
            //             zoom: 15,
            //           ),
            //           markers: _markers,
            //           polylines: _polylines,
            //           myLocationEnabled: false,
            //           zoomControlsEnabled: false,
            //           zoomGesturesEnabled: false,
            //           scrollGesturesEnabled: false,
            //           rotateGesturesEnabled: false,
            //           tiltGesturesEnabled: false,
            //           mapToolbarEnabled: false,
            //           liteModeEnabled: true,
            //           onTap: (_) => _openInGoogleMaps(),
            //           onMapCreated: (controller) {
            //             _mapController = controller;
            //           },
            //         ),
            //         if (_isLoadingRoute)
            //           Positioned(
            //             top: 12,
            //             left: 0,
            //             right: 0,
            //             child: Center(
            //               child: Container(
            //                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            //                 decoration: BoxDecoration(
            //                   color: AppColors.white,
            //                   borderRadius: BorderRadius.circular(20),
            //                   boxShadow: [
            //                     BoxShadow(
            //                       color: Colors.black.withValues(alpha: 0.1),
            //                       blurRadius: 8,
            //                     ),
            //                   ],
            //                 ),
            //                 child: Row(
            //                   mainAxisSize: MainAxisSize.min,
            //                   children: [
            //                     SizedBox(
            //                       height: 14,
            //                       width: 14,
            //                       child: CircularProgressIndicator(
            //                         strokeWidth: 2,
            //                         color: Colors.blue.shade400,
            //                       ),
            //                     ),
            //                     const SizedBox(width: 8),
            //                     const CustomText(
            //                       'Loading route...',
            //                       fontSize: 11,
            //                       fontWeight: FontWeight.w500,
            //                       color: AppColors.secondaryTextColor,
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // Address

            const SizedBox(height: 4),

            if (widget.destinationAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 6.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: AppColors.white,
                        border: Border.all(
                          color: AppColors.greyE5
                        ),
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: AppColors.secondaryTextColor,
                        height: 24,
                        width: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        widget.destinationAddress,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
        
            // Live Photos
            if (hasPhotos) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    CustomText(
                      'Store Photos (${_validPhotos.length})',
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
                  height: 160,
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
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
