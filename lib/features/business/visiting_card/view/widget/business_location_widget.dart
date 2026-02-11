import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusinessLocationWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String businessName;
  final bool isTitleShow;
  final String? locationText;
  final double? padding;

  const BusinessLocationWidget(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.businessName,
      this.locationText,
      this.isTitleShow = true,
      this.padding});

  @override
  State<BusinessLocationWidget> createState() => _BusinessLocationWidgetState();
}

class _BusinessLocationWidgetState extends State<BusinessLocationWidget> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};


  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)),
        AppImageAssets.markerBlue,
      );

      // 2. Create Marker
      final Marker customMarker = Marker(
        markerId: const MarkerId("custom_marker_id"),
        position: LatLng(widget.latitude, widget.longitude),
        icon: customIcon,
      );

      setState(() {
        _markers.add(customMarker);
      });

      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(widget.latitude, widget.longitude), 14.0),
      );

    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // margin: EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size10),
      ),
      elevation: 0,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(widget.padding ?? SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.locationText?.isNotEmpty ?? false)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.black1A),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: CustomText(
                    widget.locationText ?? "",
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black1A,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // Adjust border radius here
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.latitude, widget.longitude),
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        myLocationEnabled: false,
                        compassEnabled: false,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                      ),
                      Positioned(
                        right: SizeConfig.size10,
                        bottom: SizeConfig.size10,
                        child: InkWell(
                          onTap: () async {
                            openGoogleMaps(
                                latitude: widget.latitude,
                                longitude: widget.longitude);
                          },
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.size12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.skyBlueDF, width: 1),
                            ),
                            child: Transform.rotate(
                              angle: -0.6,
                              child: const Icon(
                                Icons.send_outlined,
                                color: AppColors.skyBlueDF,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
