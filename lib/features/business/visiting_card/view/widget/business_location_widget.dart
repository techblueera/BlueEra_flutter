import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:url_launcher/url_launcher.dart';


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
  late MapplsMapController mapController;

  // Future<void> _onMapCreated(MapplsMapController controller) async {
  //   mapController = controller;
  //   mapController.onStyleLoadedCallback = () async {
  //     await mapController.addSymbol(
  //       SymbolOptions(
  //         geometry: LatLng(widget.latitude, widget.longitude),
  //         iconSize: 1.2,
  //         iconImage: "marker-icon", // default marker
  //       ),
  //     );
  //    };
  //   setState(() {});
  // }

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
    await mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(26.7836, 80.9013),
        iconSize: 1.2,
        iconImage: "marker-icon",
      ),
    );
    setState(() {});
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Icon(Icons.location_on_outlined,
                //     color: AppColors.black1A),
                // SizedBox(width: SizeConfig.size6),
                // Expanded(
                //     child: CustomText(
                //
                //   "KJCJKLJWEN",
                //   fontSize: SizeConfig.size14,
                //   fontWeight: FontWeight.w400,
                //   color: AppColors.black1A,
                // )),
              ],
            ),
            SizedBox( height: SizeConfig.size8,),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // Adjust border radius here
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Stack(
                    children: [
                      MapplsMap(
                        onMapCreated: (controller) => _onMapCreated(controller),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.latitude, widget.longitude),
                          zoom: 14.0,
                        ),
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
                            openGoogleMaps(latitude: widget.latitude, longitude: widget.longitude);
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
