import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';

import '../../../auth/controller/auth_controller.dart';
import '../../../map/view/searchLocationScreen.dart';
import '../../controller/discover_controller.dart';


class SearchTransportAddress extends StatefulWidget {
  final Function(double?, double?, String?)? onPlaceSelected;


  const SearchTransportAddress({Key? key, this.onPlaceSelected,}) : super(key: key);

  @override
  State<SearchTransportAddress> createState() => _SearchTransportAddressState();
}

class _SearchTransportAddressState extends State<SearchTransportAddress> {

  final authController = getOrPut(() => AuthController());
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  final discoverController = getOrPut(() => DiscoverController());
  Set<Polyline> _polylines = {};

  String selectedRideType = "One Way";
  String selectedBookingFor = "Myself";

  LatLng? fromLatLng;
  LatLng? toLatLng;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCurrentLocation();
    });

    authController.isSearchOpen.value=true;

  }

  @override
  void dispose() {

    super.dispose();
  }


  Future<void> _setInitialCurrentLocation() async {
    try {
      // Get current location from your LocationService



      // Get address
      String address = await LocationService.getAddressUsingLatLng(
        latitude: LocationService.lat,
        longitude: LocationService.lng,
      );
      discoverController.selectedFromLat?.value=LocationService.lat;
      discoverController.selectedFromLong?.value=LocationService.lng;
      discoverController.selectedFromAddress?.value = address;

      // Add blue marker (FROM)
      final fromLatLng = LatLng(LocationService.lat, LocationService.lng);

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("from"),
            position: fromLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue, // 🔵 FROM = Blue
            ),
          ),
        );
      });

      // Move camera to current location
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(fromLatLng, 15),
      );

    } catch (e) {
      log("Error setting initial location: $e");
    }
  }


  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      // final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
      //   const ImageConfiguration(size: Size(30, 30)),
      //   AppImageAssets.markerBlue,
      // );

      // final Marker customMarker = Marker(
      //   markerId: const MarkerId("custom_marker_id"),
      //   position:  LatLng(LocationService.lat, LocationService.lng),
      //   icon: customIcon,
      // );
      //
      // setState(() {
      //   _markers.add(customMarker);
      // });

      // Smoothly animate camera to marker
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(  LatLng(LocationService.lat, LocationService.lng), 14.0),
      );

    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }
  void _addMarkers(LatLng pickup, LatLng drop) {
    _markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("drop"),
        position: drop,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );
  }
  void onLocationsSelected(LatLng pickup, LatLng drop) {
    if(discoverController.selectedFromLat?.value != 0.0 &&
       discoverController.selectedFromLong?.value != 0.0 &&
       discoverController.selectedToLat?.value != 0.0 &&
       discoverController.selectedToLong?.value != 0.0){
      _addMarkers(pickup, drop);
      _getRoutePolyline(pickup, drop);
    }

  }
  Future<void> _getRoutePolyline(LatLng start, LatLng end) async {
    PolylinePoints polylinePoints = PolylinePoints(apiKey: googleMapKey);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> routeCoords = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.clear(); // Important (avoid dotted layering)
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: routeCoords,
            width: 8, // 🔥 Increase width for smooth road look
            color: Colors.blue,
            geodesic: true,
            jointType: JointType.round, // 🔥 Smooth corners
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      });
    }
  }
  void _updateMarkersAndRoute() {
    _markers.clear();

    // From Marker (Blue)
    if (discoverController.selectedFromLat?.value != 0.0 &&
        discoverController.selectedFromLong?.value != 0.0) {

      fromLatLng = LatLng(
        discoverController.selectedFromLat!.value,
        discoverController.selectedFromLong!.value,
      );

      _markers.add(
        Marker(
          markerId: const MarkerId("from"),
          position: fromLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // To Marker (Red)
    if (discoverController.selectedToLat?.value != 0.0 &&
        discoverController.selectedToLong?.value != 0.0) {

      toLatLng = LatLng(
        discoverController.selectedToLat!.value,
        discoverController.selectedToLong!.value,
      );

      _markers.add(
        Marker(
          markerId: const MarkerId("to"),
          position: toLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      // Call your existing polyline (UNCHANGED)
      _getRoutePolyline(fromLatLng!, toLatLng!);
    }

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    // final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(),
      bottomSheet: _rideBookingBottomSheet(),
      body: Stack(
        children: [
      SizedBox(
      height: Get.height * 0.8,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition:  CameraPosition(
            target: LatLng(LocationService.lat, LocationService.lng),
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          markers: _markers,
          polylines: _polylines,
          onTap: (LatLng latLng) async {
            // Case 1: From already selected → set To
            if (discoverController.selectedFromLat ?.value != 0.0 &&
                discoverController.selectedFromLong?.value != 0.0 &&
                (discoverController.selectedToLat?.value == 0.0 ||
                    discoverController.selectedToLong?.value == 0.0)) {

              // Set TO location
              discoverController.selectedToLat?.value = latLng.latitude;
              discoverController.selectedToLong?.value = latLng.longitude;

              toLatLng = latLng;

            }
            // Case 2: From not selected OR cleared → set From
            else if (discoverController.selectedFromLat?.value == 0.0 ||
                discoverController.selectedFromLong?.value == 0.0) {

              discoverController.selectedFromLat?.value = latLng.latitude;
              discoverController.selectedFromLong?.value = latLng.longitude;

              fromLatLng = latLng;

              // Clear old markers when new journey starts
              _markers.clear();
              _polylines.clear();
            }
            // Case 3: Both already selected → reset journey (Uber behaviour)
            else {
              // Reset and make this new FROM
              discoverController.selectedFromLat?.value = latLng.latitude;
              discoverController.selectedFromLong?.value = latLng.longitude;
              discoverController.selectedToLat?.value = 0.0;
              discoverController.selectedToLong?.value = 0.0;

              fromLatLng = latLng;
              toLatLng = null;

              _markers.clear();
              _polylines.clear();
            }

            // Get address (your existing service)
            String address = await LocationService.getAddressUsingLatLng(
              latitude: latLng.latitude,
              longitude: latLng.longitude,
            );

            // Update address text
            if (toLatLng == latLng) {
              discoverController.selectedToAddress?.value = address;
            } else {
              discoverController.selectedFromAddress?.value = address;
            }

            _updateMarkersAndRoute();
          },
// 🔥 ADD THIS LINE
        ),
      ),
          Positioned(

              child: Container(
                height: 100,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),

                    color: AppColors.white

                ),
                padding: EdgeInsets.symmetric(horizontal: 14,vertical: 16),
                margin: EdgeInsets.symmetric(horizontal: 8,vertical: 10),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchLocationScreen(
                                  onPlaceSelected: (lat, long,
                                      address) {
                                    discoverController
                                        .selectedFromLat
                                        ?.value =
                                        lat ?? 0;
                                    discoverController
                                        .selectedFromLong
                                        ?.value =
                                        long ?? 0;
                                    discoverController
                                        .selectedFromAddress
                                        ?.value = address ?? "";
                                    discoverController
                                        .getBookingRidersApi();
                                    onLocationsSelected(
                                        LatLng(discoverController.selectedFromLat?.value??0.0,
                                            discoverController.selectedFromLong?.value??0.0),
                                        LatLng(discoverController
                                            .selectedToLat?.value??0, discoverController
                                            .selectedToLong?.value??0));
                                  }, fromScreen: '',

                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                LocalAssets(imagePath: AppIconAssets
                                    .transport_from_location,height: 20,width: 20,),
                                SizedBox(width: 12,),
                                Expanded(
                                  child: CustomText(
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    (discoverController.selectedFromAddress
                                        ?.value == '' ||
                                        discoverController
                                            .selectedFromAddress
                                            ?.value == null)
                                        ?
                                    "${LocationService.userCurrentAddress.value.formattedAddress}"
                                        : discoverController
                                        .selectedFromAddress?.value,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12,),
                          GestureDetector(
                            onTap: () {
                              // Clear FROM
                              discoverController.selectedFromLat?.value = 0.0;
                              discoverController.selectedFromLong?.value = 0.0;
                              discoverController.selectedFromAddress?.value = "";

                              fromLatLng = null;

                              _markers.clear();
                              _polylines.clear();

                              // If TO exists, keep only red marker
                              if (toLatLng != null) {
                                _markers.add(
                                  Marker(
                                    markerId: const MarkerId("to"),
                                    position: toLatLng!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                  ),
                                );
                              }

                              setState(() {});
                            },
                            child: LocalAssets(imagePath: AppIconAssets.close_black),
                          )

                        ],
                      ),
                    ),
                    // SizedBox(height: 10,),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: AppColors.whiteE5,
                    ),
                    // SizedBox(height: 10,),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchLocationScreen(
                                  onPlaceSelected: (lat, long,
                                      address) {
                                    discoverController
                                        .selectedToLat?.value =
                                        lat ?? 0;

                                    discoverController
                                        .selectedToLong?.value =
                                        long ?? 0;
                                    discoverController
                                        .selectedToAddress
                                        ?.value = address ?? "";
                                    discoverController
                                        .getBookingRidersApi();
                                    onLocationsSelected(
                                        LatLng(discoverController.selectedFromLat?.value??0.0,
                                            discoverController.selectedFromLong?.value??0.0),
                                    LatLng(discoverController
                                        .selectedToLat?.value??0, discoverController
                                        .selectedToLong?.value??0));
                                  }, fromScreen: '',
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                LocalAssets(
                                  imagePath: AppIconAssets.location_new,
                                  imgColor: AppColors.red00,
                                  height: 20,width: 20,
                                ),
                                SizedBox(width: 12,),
                                Expanded(
                                  child: CustomText(
                                    (discoverController.selectedToAddress
                                        ?.value == '' ||
                                        discoverController.selectedToAddress
                                            ?.value == null) ?
                                    "Select Drop Location" : discoverController
                                        .selectedToAddress?.value,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12,),
                          GestureDetector(
                            onTap: () {
                              // Clear TO
                              discoverController.selectedToLat?.value = 0.0;
                              discoverController.selectedToLong?.value = 0.0;
                              discoverController.selectedToAddress?.value = "";

                              toLatLng = null;

                              _polylines.clear(); // remove route

                              // Keep only FROM marker
                              _updateMarkersAndRoute();
                            },
                            child: LocalAssets(imagePath: AppIconAssets.close_black),
                          )

                        ],
                      ),
                    ),
                  ],
                ),

              ))
        ],
      ),
    );
  }
  Widget _rideBookingBottomSheet() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                "Ride Type",
               fontSize: 14, fontWeight: FontWeight.w600
              ),
              const SizedBox(height: 10),

              /// Ride Type Buttons
              /// Ride Type Buttons
              Row(
                children: [
                  _selectableChip(
                    text: "One Way",
                    isSelected: selectedRideType == "One Way",
                    onTap: () {
                      setState(() {
                        selectedRideType = "One Way";
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _selectableChip(
                    text: "Round Trip",
                    isSelected: selectedRideType == "Round Trip",
                    onTap: () {
                      setState(() {
                        selectedRideType = "Round Trip";
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _selectableChip(
                    text: "Sharing",
                    isSelected: selectedRideType == "Sharing",
                    onTap: () {
                      setState(() {
                        selectedRideType = "Sharing";
                      });
                    },
                  ),
                ],
              ),


              const SizedBox(height: 16),
              const CustomText(
                "Booking For",
              fontSize: 14, fontWeight: FontWeight.w600
              ),
              const SizedBox(height: 10),

              /// Booking For Buttons
              /// Booking For Buttons
              Row(
                children: [
                  _selectableChip(
                    text: "Myself",
                    isSelected: selectedBookingFor == "Myself",
                    onTap: () {
                      setState(() {
                        selectedBookingFor = "Myself";
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _selectableChip(
                    text: "My Friend",
                    isSelected: selectedBookingFor == "My Friend",
                    onTap: () {
                      setState(() {
                        selectedBookingFor = "My Friend";
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const CustomText(
                "Friend's Mobile Number",
               fontSize: 14, fontWeight: FontWeight.w600
              ),
              const SizedBox(height: 10),

              /// Phone Field
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),

                    ),
                    child:  Center(
                      child: CustomText(
                        "+91",
                       fontSize: 16, fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                   Expanded(
                    child: CommonTextField(
                      sIcon:IconButton(
                        onPressed: (){},
                          icon: LocalAssets(imagePath: AppIconAssets.get_contacts_person,height: 20,width: 20,)),
                        hintText: "1234567890",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Submit Button
              CustomBtn(
                  isValidate: true,
                  onTap: (){}, title: "Submit"),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectableChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = AppColors.primaryColor; // or your primary color

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primary : Colors.white,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
          ),
        ),
        child: CustomText(
          text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }


}
