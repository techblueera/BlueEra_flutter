import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../widgets/custom_text_cm.dart';

class VisitBusinessLocationViewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;

  const VisitBusinessLocationViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<VisitBusinessLocationViewWidget> createState() => _VisitBusinessLocationViewWidgetState();
}

class _VisitBusinessLocationViewWidgetState extends State<VisitBusinessLocationViewWidget> {
  MapplsMapController? mapController;

  Future<void> _addMarker() async {
    if (widget.latitude != 0.0 && widget.longitude != 0.0) {
      await mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.latitude, widget.longitude),
          iconSize: 1.2,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
            "Business Location",
            fontWeight: FontWeight.bold,
            fontFamily: "Arial",
            fontSize: 16
        ),
        const SizedBox(height: 18),

        widget.latitude != 0.0 && widget.longitude != 0.0
            ? Container(
          height: 200,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: MapplsMap(
              onMapCreated: (MapplsMapController controller) async {
                mapController = controller;
                await _addMarker();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15.0,
              ),
              myLocationEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
            ),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 50,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 10),
                Text(
                  'Location not available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

         if (widget.address.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Color(0xFF2399F5),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                   widget.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 20),
      ],
    );
  }
}
