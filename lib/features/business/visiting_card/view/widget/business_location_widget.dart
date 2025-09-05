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
  final String? locationText;

  const BusinessLocationWidget(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.businessName,
        this.locationText,
      this.isTitleShow = true});

  @override
  State<BusinessLocationWidget> createState() => _BusinessLocationWidgetState();
}

class _BusinessLocationWidgetState extends State<BusinessLocationWidget> {
  late MapplsMapController mapController;

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
    await mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.latitude, widget.longitude),
        iconSize: 1.2,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.black1A),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                    child: CustomText(
                      widget.locationText,
                      fontSize: SizeConfig.size14,
                      color: AppColors.black1A,
                    )),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                  child: Image.asset(
                    "assets/images/map.jpeg",
                    height: SizeConfig.size180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final Uri googleMapUrl = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}");

                      if (await canLaunchUrl(googleMapUrl)) {
                      await launchUrl(googleMapUrl,
                      mode: LaunchMode.externalApplication);
                      } else {
                      throw "Could not open Google Maps";
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blueDF, width: 2),
                      ),
                      child: Transform.rotate(
                        angle: -0.6,
                        child: const Icon(
                          Icons.send_outlined,
                          color: AppColors.blueDF,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  }
}
