
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/static_map_preview.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusinessLocationWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String businessName;
  final bool isTitleShow;
  final String? locationText;
  final double? padding;

  const BusinessLocationWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.businessName,
    this.locationText,
    this.isTitleShow = true,
    this.padding,
  });

  @override
  State<BusinessLocationWidget> createState() => _BusinessLocationWidgetState();
}

class _BusinessLocationWidgetState extends State<BusinessLocationWidget> {
  // No GoogleMapController, markers or custom-icon loading any more: the map is
  // a static image (see build). That also removes the iOS controller-disposal
  // crash this widget used to have to guard against.

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(widget.padding ?? SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.locationText?.isNotEmpty ?? false)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.black1A),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    widget.locationText ?? "",
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black1A,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          SizedBox(height: SizeConfig.size8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                children: [
                  // A picture, not a live `GoogleMap`. This is the strongest
                  // case for it in the app: a business's location is IDENTICAL
                  // for every person who opens the profile, so a live map means
                  // buying the same image once per viewer. As a static image it
                  // is a cheaper SKU and disk-cached per device — and once the
                  // backend serves these from our own storage (backend guide
                  // §B5) Google is paid once per location, ever.
                  StaticMapPreview(
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    width: MediaQuery.of(context).size.width,
                    height: 180,
                    zoom: 14,
                  ),
                  // ... rest of your UI (Send button)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


class BusinessLocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String businessName;

  const BusinessLocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.businessName,
  });

  @override
  State<BusinessLocationMapWidget> createState() => _BusinessLocationMapWidgetState();
}


class _BusinessLocationMapWidgetState extends State<BusinessLocationMapWidget> {
  // 1. Move the controller INSIDE the state
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  void _loadMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId("business_id"),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: widget.businessName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          mapType: MapType.normal,
          compassEnabled: false,
          myLocationEnabled: true, // Requires Info.plist permissions!
          myLocationButtonEnabled: false,
          // Use the widget's actual location for the initial position
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 14.0,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 2. CRITICAL: Dispose the controller to stop the iOS crash
    _mapController?.dispose();
    super.dispose();
  }
}

