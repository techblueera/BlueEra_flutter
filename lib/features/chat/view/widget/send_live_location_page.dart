import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:permission_handler/permission_handler.dart';

class SendLocationPage extends StatefulWidget {
  final Function(double lat,double long,String? placeName,String? address) onSubmit;
  const SendLocationPage({required this.onSubmit});
  @override
  _SendLocationPageState createState() => _SendLocationPageState();
}

class _SendLocationPageState extends State<SendLocationPage> {
  // GoogleMapController? mapController;
  MapplsMapController? mapController;
  LatLng? _currentPosition;
  // String? _address;
  List<Placemark> _nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      await _fetchNearbyPlaces(pos);
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    setState(() {
      _nearbyPlaces = placemarks;
      if (placemarks.isNotEmpty) {
        // _address =
        // "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.country}";
      }
    });
  }

  // Future<void> _onMapCreated(MapplsMapController controller) async {
  //   mapController = controller;
  //   await _addMarker();
  // }

  Future<void> _addMarker() async {
    if (_currentPosition?.latitude != 0.0 && _currentPosition?.longitude != 0.0) {
      await mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(_currentPosition?.latitude??0.0, _currentPosition?.longitude??0.0),
          iconSize: 1.2,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Send location",
      ),
      body: (_currentPosition == null)
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 250,
            child:
            MapplsMap(
              onMapCreated: (MapplsMapController controller) async {
                mapController = controller;
                await _addMarker();

              },
              initialCameraPosition: CameraPosition(
                target:  _currentPosition!,
                zoom: 15.0,
              ),
              myLocationEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
            ),

            // GoogleMap(
            //   onMapCreated: _onMapCreated,
            //   initialCameraPosition: CameraPosition(
            //     target: _currentPosition!,
            //     zoom: 15,
            //   ),
            //   myLocationEnabled: true,
            //   markers: {
            //     Marker(
            //       markerId: MarkerId('current'),
            //       position: _currentPosition!,
            //     ),
            //   },
            // ),
          ),
          const SizedBox(height: 6,),
          // ListTile(
          //   leading: Icon(Icons.location_on, color: Colors.black),
          //   title: CustomText(
          //       "Share live location",
          //     fontSize: 14,
          //     fontWeight: FontWeight.w600,
          //   ),
          //   onTap: () {
          //     // Handle live location (you can simulate or extend)
          //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //         content: Text("Live location sharing not implemented")));
          //   },
          // ),
          // Divider(),
          ListTile(
            leading: Icon(Icons.my_location,color: Colors.black,),
            title: CustomText("Send your current location",
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            subtitle: CustomText("Accurate to ~8 meters",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
            ),
            onTap: () {
              // Handle send current location
              widget.onSubmit(_currentPosition!.latitude, _currentPosition!.longitude,null,null);
            },
          ),
          Divider(color: AppColors.grey99,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText("Nearby places",
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                )),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyPlaces.length,
              itemBuilder: (context, index) {
                final place = _nearbyPlaces[index];
                return ListTile(
                  leading: Icon(Icons.location_pin,color: Colors.black,),
                  title: CustomText(place.name ?? "Unknown",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  subtitle: CustomText(
                      "${place.street}, ${place.locality}, ${place.postalCode}",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: ()async {
                    // Handle selected place
                    final fullAddress =
                        "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
                    try {
                      List<Location> locations = await locationFromAddress(fullAddress);
                      if (locations.isNotEmpty) {
                        final selected = locations.first;
                        widget.onSubmit(selected.latitude, selected.longitude,"${place.street}, ${place.locality}, ${place.postalCode}","${place.name ?? "Unknown"}");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to get location for this place")),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
