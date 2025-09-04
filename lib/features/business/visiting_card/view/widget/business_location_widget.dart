import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessLocationWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String businessName;
  final bool isTitleShow;

  const BusinessLocationWidget(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.businessName,
      this.isTitleShow = true});

  @override
  State<BusinessLocationWidget> createState() => _BusinessLocationWidgetState();
}

class _BusinessLocationWidgetState extends State<BusinessLocationWidget> {
  late MapplsMapController mapController;

  void _onMapCreated(MapplsMapController controller) {
    mapController = controller;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isTitleShow)
            CustomText(
              "Business Location",
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            // Adjust border radius here
            child: SizedBox(
              width: double.infinity,
              height: 180, // ✅ Set a fixed height (adjust as needed)
              child: Stack(
                children: [
                  MapplsMap(
                    onMapCreated: (controller) async {
                      _onMapCreated(controller);
                      await mapController.addSymbol(
                        SymbolOptions(
                          geometry: LatLng(widget.latitude, widget.longitude),
                          iconSize: 1.2,
                        ),
                      );
                      setState(() {});
                    },
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
                       logs("TTTTT");
    final Uri googleMapUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}");

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open Google Maps";
    }
                      },
                      child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(5)),
                          height: SizeConfig.size40,
                          width: SizeConfig.size40,
                          child: Icon(
                            Icons.directions,
                            color: AppColors.white,
                          )),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
