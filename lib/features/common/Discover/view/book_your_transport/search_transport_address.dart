import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';

import '../../../auth/controller/auth_controller.dart';
import '../../../map/view/searchLocationScreen.dart';
import '../../controller/discover_controller.dart';
import 'book_transport_main.dart';

class SearchTransportAddress extends StatefulWidget {
  final Function() onPlaceSelected;
  final String? vehicleType;

  const SearchTransportAddress({
    Key? key,
    required this.onPlaceSelected,
    this.vehicleType,
  }) : super(key: key);

  @override
  State<SearchTransportAddress> createState() => _SearchTransportAddressState();
}

class _SearchTransportAddressState extends State<SearchTransportAddress> {
  final authController = getOrPut(() => AuthController());
  GoogleMapController? mapController;

  final discoverController = getOrPut(() => DiscoverController());
  Set<Polyline> _polylines = {};

  LatLng? fromLatLng;
  LatLng? toLatLng;

  LatLng get _currentLatLng {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat != 0.0 && lng != 0.0) return LatLng(lat, lng);
    return const LatLng(26.7836, 80.9013);
  }

  @override
  void initState() {
    super.initState();
    _setVehicleType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCurrentLocation();
      authController.isSearchOpen.value = true;
    });
  }

  void _setVehicleType() {
    if (widget.vehicleType != null) {
      if (widget.vehicleType == "TWO_WHEELER") {
        discoverController.selectedHorizontalTab.value = 0;
        discoverController.selectedVehicleOptionIndex.value = 0;
      } else if (widget.vehicleType == "PASSENGER") {
        discoverController.selectedHorizontalTab.value = 0;
        discoverController.selectedVehicleOptionIndex.value = 1;
      } else if (widget.vehicleType == "GOODS") {
        discoverController.selectedHorizontalTab.value = 3;
      } else if (widget.vehicleType == "OUR_STATION") {
        discoverController.selectedHorizontalTab.value = 1;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _setInitialCurrentLocation() async {
    try {
      String address = await LocationService.getAddressUsingLatLng(
        latitude: LocationService.lat,
        longitude: LocationService.lng,
      );

      if (!mounted) return;

      discoverController.selectedFromLat?.value = LocationService.lat;
      discoverController.selectedFromLong?.value = LocationService.lng;
      discoverController.selectedFromAddress?.value = address;

      final fromLatLng = LatLng(LocationService.lat, LocationService.lng);

      discoverController.markers.clear();
      discoverController.markers.add(
        Marker(
          markerId: const MarkerId("from"),
          position: fromLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(fromLatLng, 15),
        );
      }
    } catch (e) {
      log("Error setting initial location: $e");
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    if (!mounted) return;

    try {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng, 15.0),
      );
    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }

  void _addMarkers(LatLng pickup, LatLng drop) {
    discoverController.markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    discoverController.markers.add(
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
    if (discoverController.selectedFromLat?.value != 0.0 &&
        discoverController.selectedFromLong?.value != 0.0 &&
        discoverController.selectedToLat?.value != 0.0 &&
        discoverController.selectedToLong?.value != 0.0) {
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

    if (!mounted) return;

    if (result.points.isNotEmpty) {
      List<LatLng> routeCoords = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: routeCoords,
            width: 8,
            color: Colors.blue,
            geodesic: true,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      });

      // Fit camera to show both markers
      _fitBounds(start, end);
    }
  }

  void _fitBounds(LatLng start, LatLng end) {
    if (mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        start.latitude < end.latitude ? start.latitude : end.latitude,
        start.longitude < end.longitude ? start.longitude : end.longitude,
      ),
      northeast: LatLng(
        start.latitude > end.latitude ? start.latitude : end.latitude,
        start.longitude > end.longitude ? start.longitude : end.longitude,
      ),
    );
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _updateMarkersAndRoute() {
    discoverController.markers.clear();

    // From Marker (Blue)
    if (discoverController.selectedFromLat?.value != 0.0 &&
        discoverController.selectedFromLong?.value != 0.0) {
      fromLatLng = LatLng(
        discoverController.selectedFromLat!.value,
        discoverController.selectedFromLong!.value,
      );

      discoverController.markers.add(
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

      discoverController.markers.add(
        Marker(
          markerId: const MarkerId("to"),
          position: toLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      _getRoutePolyline(fromLatLng!, toLatLng!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _openSearchForPickup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationScreen(
          onPlaceSelected: (lat, long, address) {
            discoverController.selectedFromLat?.value = lat ?? 0;
            discoverController.selectedFromLong?.value = long ?? 0;
            discoverController.selectedFromAddress?.value = address ?? "";
            discoverController.getBookingRidersApi();
            onLocationsSelected(
              LatLng(
                discoverController.selectedFromLat?.value ?? 0.0,
                discoverController.selectedFromLong?.value ?? 0.0,
              ),
              LatLng(
                discoverController.selectedToLat?.value ?? 0,
                discoverController.selectedToLong?.value ?? 0,
              ),
            );
            _updateMarkersAndRoute();
          },
          fromScreen: '',
        ),
      ),
    );
  }

  void _openSearchForDrop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationScreen(
          onPlaceSelected: (lat, long, address) {
            discoverController.selectedToLat?.value = lat ?? 0;
            discoverController.selectedToLong?.value = long ?? 0;
            discoverController.selectedToAddress?.value = address ?? "";
            discoverController.getBookingRidersApi();
            onLocationsSelected(
              LatLng(
                discoverController.selectedFromLat?.value ?? 0.0,
                discoverController.selectedFromLong?.value ?? 0.0,
              ),
              LatLng(
                discoverController.selectedToLat?.value ?? 0,
                discoverController.selectedToLong?.value ?? 0,
              ),
            );
            _updateMarkersAndRoute();
          },
          fromScreen: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
         ),
      body: Stack(
        children: [
          /// Full-screen map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              markers: discoverController.markers,
              polylines: _polylines,
              onTap: (LatLng latLng) async {
                // Case 1: From already selected -> set To
                if (discoverController.selectedFromLat?.value != 0.0 &&
                    discoverController.selectedFromLong?.value != 0.0 &&
                    (discoverController.selectedToLat?.value == 0.0 ||
                        discoverController.selectedToLong?.value == 0.0)) {
                  discoverController.selectedToLat?.value = latLng.latitude;
                  discoverController.selectedToLong?.value = latLng.longitude;
                  toLatLng = latLng;
                }
                // Case 2: From not selected -> set From
                else if (discoverController.selectedFromLat?.value == 0.0 ||
                    discoverController.selectedFromLong?.value == 0.0) {
                  discoverController.selectedFromLat?.value = latLng.latitude;
                  discoverController.selectedFromLong?.value = latLng.longitude;
                  fromLatLng = latLng;
                  discoverController.markers.clear();
                  _polylines.clear();
                }
                // Case 3: Both selected -> reset (Uber behaviour)
                else {
                  discoverController.selectedFromLat?.value = latLng.latitude;
                  discoverController.selectedFromLong?.value = latLng.longitude;
                  discoverController.selectedToLat?.value = 0.0;
                  discoverController.selectedToLong?.value = 0.0;
                  fromLatLng = latLng;
                  toLatLng = null;
                  discoverController.markers.clear();
                  _polylines.clear();
                }

                String address = await LocationService.getAddressUsingLatLng(
                  latitude: latLng.latitude,
                  longitude: latLng.longitude,
                );

                if (toLatLng == latLng) {
                  discoverController.selectedToAddress?.value = address;
                } else {
                  discoverController.selectedFromAddress?.value = address;
                }

                _updateMarkersAndRoute();
              },
            ),
          ),

          /// My location button
          Positioned(
            right: 16,
            bottom: _bottomSheetHeight + 16,
            child: FloatingActionButton.small(
              heroTag: "search_my_location",
              backgroundColor: AppColors.white,
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLatLng, 15.0),
                );
              },
              child: Icon(Icons.my_location,
                  color: AppColors.primaryColor, size: 20),
            ),
          ),

          /// Address input card at top (Uber style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// Location icons column
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 30,
                            color: AppColors.grayText.withOpacity(0.3),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.red00,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      /// Address fields
                      Expanded(
                        child: Column(
                          children: [
                            /// Pickup field
                            InkWell(
                              onTap: _openSearchForPickup,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.greyE4,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() => CustomText(
                                            (discoverController
                                                            .selectedFromAddress
                                                            ?.value ==
                                                        '' ||
                                                    discoverController
                                                            .selectedFromAddress
                                                            ?.value ==
                                                        null)
                                                ? "${LocationService.userCurrentAddress.value.formattedAddress}"
                                                : discoverController
                                                    .selectedFromAddress?.value,
                                            fontSize: 13,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w500,
                                          )),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        discoverController
                                            .selectedFromLat?.value = 0.0;
                                        discoverController
                                            .selectedFromLong?.value = 0.0;
                                        discoverController
                                            .selectedFromAddress?.value = "";
                                        fromLatLng = null;
                                        discoverController.markers.clear();
                                        _polylines.clear();
                                        if (toLatLng != null) {
                                          discoverController.markers.add(
                                            Marker(
                                              markerId: const MarkerId("to"),
                                              position: toLatLng!,
                                              icon: BitmapDescriptor
                                                  .defaultMarkerWithHue(
                                                BitmapDescriptor.hueRed,
                                              ),
                                            ),
                                          );
                                        }
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.close,
                                          size: 18, color: AppColors.grayText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Drop field
                            InkWell(
                              onTap: _openSearchForDrop,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.greyE4,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() => CustomText(
                                            (discoverController
                                                            .selectedToAddress
                                                            ?.value ==
                                                        '' ||
                                                    discoverController
                                                            .selectedToAddress
                                                            ?.value ==
                                                        null)
                                                ? AppStrings.whereAreYouGoing.tr
                                                : discoverController
                                                    .selectedToAddress?.value,
                                            fontSize: 13,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w500,
                                            color: (discoverController
                                                            .selectedToAddress
                                                            ?.value ==
                                                        '' ||
                                                    discoverController
                                                            .selectedToAddress
                                                            ?.value ==
                                                        null)
                                                ? AppColors.grayText
                                                : null,
                                          )),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        discoverController
                                            .selectedToLat?.value = 0.0;
                                        discoverController
                                            .selectedToLong?.value = 0.0;
                                        discoverController
                                            .selectedToAddress?.value = "";
                                        toLatLng = null;
                                        _polylines.clear();
                                        _updateMarkersAndRoute();
                                      },
                                      child: const Icon(Icons.close,
                                          size: 18, color: AppColors.grayText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _rideBookingBottomSheet(),
          ),
        ],
      ),
    );
  }

  double get _bottomSheetHeight {
    if (discoverController.selectedHorizontalTab.value == 1 ||
        discoverController.selectedHorizontalTab.value == 3) {
      return 350;
    }
    return 100;
  }

  Widget _rideBookingBottomSheet() {
    return SafeArea(
      top: false,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.whiteE5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (discoverController.selectedHorizontalTab.value == 1)
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(AppStrings.rideType,
                          fontSize: 14, fontWeight: FontWeight.w600),
                      const SizedBox(height: 10),

                      /// Ride Type Buttons
                      Row(
                        children: [
                          _selectableChip(
                            text: AppStrings.oneWay.tr,
                            isSelected:
                                discoverController.selectedRideType.value ==
                                    AppConstants.oneWay,
                            onTap: () {
                              discoverController.selectedRideType.value =
                                  AppConstants.oneWay;
                            },
                          ),
                          const SizedBox(width: 10),
                          _selectableChip(
                            text: AppStrings.roundTrip.tr,
                            isSelected:
                                discoverController.selectedRideType.value ==
                                    AppConstants.roundTrip,
                            onTap: () {
                              discoverController.selectedRideType.value =
                                  AppConstants.roundTrip;
                            },
                          ),
                          const SizedBox(width: 10),
                          _selectableChip(
                            text: AppStrings.sharingLabel.tr,
                            isSelected:
                                discoverController.selectedRideType.value ==
                                    AppConstants.sharing,
                            onTap: () {
                              discoverController.selectedRideType.value =
                                  AppConstants.sharing;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const CustomText(AppStrings.bookingFor,
                          fontSize: 14, fontWeight: FontWeight.w600),
                      const SizedBox(height: 10),

                      /// Booking For Buttons
                      Row(
                        children: [
                          _selectableChip(
                            text: AppStrings.mySelfLabel.tr,
                            isSelected:
                                discoverController.selectedBookingFor.value ==
                                    AppConstants.mySelf,
                            onTap: () {
                              discoverController.selectedBookingFor.value =
                                  AppConstants.mySelf;
                            },
                          ),
                          const SizedBox(width: 10),
                          _selectableChip(
                            text: AppStrings.myFriend.tr,
                            isSelected:
                                discoverController.selectedBookingFor.value ==
                                    AppConstants.myFriend,
                            onTap: () {
                              discoverController.selectedBookingFor.value =
                                  AppConstants.myFriend;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      if (discoverController.selectedBookingFor.value !=
                          AppConstants.mySelf)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(AppStrings.friendsMobileNumber,
                                fontSize: 14, fontWeight: FontWeight.w600),
                            const SizedBox(height: 10),

                            /// Phone Field
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: CustomText("+91",
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CommonTextField(
                                    textEditController: discoverController
                                        .myFriendPhoneController,
                                    sIcon: IconButton(
                                        onPressed: () {},
                                        icon: LocalAssets(
                                          imagePath: AppIconAssets
                                              .get_contacts_person,
                                          height: 20,
                                          width: 20,
                                        )),
                                    hintText: AppStrings.phoneNumberHint.tr,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  );
                }),
              if (discoverController.selectedHorizontalTab.value == 3)
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                          textEditController:
                              discoverController.receiversNameController,
                          title: AppStrings.receiversName.tr,
                          hintText: AppStrings.receiversNameHint.tr),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(AppStrings.receiversMobileNumber,
                              fontSize: 14, fontWeight: FontWeight.w400),
                          const SizedBox(height: 10),

                          /// Phone Field
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: Center(
                                  child: CustomText("+91",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CommonTextField(
                                  textEditController: discoverController
                                      .receiversNumberController,
                                  sIcon: IconButton(
                                      onPressed: () {},
                                      icon: LocalAssets(
                                        imagePath:
                                            AppIconAssets.get_contacts_person,
                                        height: 20,
                                        width: 20,
                                      )),
                                  hintText: AppStrings.phoneNumberHint.tr,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(AppStrings.parcelDetails,
                              fontSize: 16, fontWeight: FontWeight.w600),
                          InkWell(
                            onTap: () {
                              discoverController.clearParcelField();
                              Get.dialog(Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const CustomText(AppStrings.parcelDetails,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                          InkWell(
                                              onTap: () {
                                                Get.back();
                                              },
                                              child: Icon(
                                                Icons.cancel_outlined,
                                                color: AppColors.red,
                                              )),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 16,
                                      ),
                                      const CustomText(AppStrings.parcelCategory,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Obx(() {
                                        return CommonDropdown(
                                          items: [
                                            AppStrings.documentParcel.tr,
                                            AppStrings.productParcel.tr,
                                            AppStrings.othersParcel.tr
                                          ],
                                          selectedValue: discoverController
                                              .selectedParcelCategory.value,
                                          hintText: AppStrings.chooseParcelCategory.tr,
                                          onChanged: (value) {
                                            discoverController
                                                .selectedParcelCategory
                                                .value = value ?? '';
                                          },
                                          displayValue: (value) => value,
                                        );
                                      }),
                                      const SizedBox(height: 16),
                                      CommonTextField(
                                        textEditController: discoverController
                                            .parcelWeightController,
                                        title: AppStrings.weightInKgOptional.tr,
                                        hintText: AppStrings.weightHint.tr,
                                        validator: (value) {
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      CommonTextField(
                                        maxLine: 3,
                                        textEditController: discoverController
                                            .parcelDescriptionController,
                                        title: AppStrings.description.tr,
                                        hintText:
                                            AppStrings.parcelDescriptionHint.tr,
                                        validator: (value) {
                                          return null;
                                        },
                                      ),
                                      SizedBox(
                                        height: 26,
                                      ),
                                      CustomBtn(
                                          isValidate: true,
                                          onTap: () {
                                            discoverController
                                                .addParcelDetails();
                                            Get.back();
                                          },
                                          title: AppStrings.save.tr),
                                    ],
                                  ),
                                ),
                              ));
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: AppColors.primaryColor,
                                ),
                                const CustomText(
                                  AppStrings.addLabel,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ...discoverController.parcelDetailsList
                          .map((e) => Container(
                                margin:
                                    EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.whiteE5)),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          CustomText(
                                            e.category,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 8,
                                              ),
                                              InkWell(
                                                  onTap: () {
                                                    discoverController
                                                        .removeParcelDetails(
                                                            e);
                                                  },
                                                  child: Icon(
                                                    Icons.delete,
                                                    color: AppColors.red,
                                                    size: 22,
                                                  ))
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      CustomText(e.weightKg,
                                          fontSize: 12,
                                          color: AppColors
                                              .secondaryTextColor),
                                      SizedBox(
                                        height: 6,
                                      ),
                                      CustomText(
                                        e.description,
                                        fontSize: 12,
                                        color: AppColors
                                            .secondaryTextColor,
                                      ),
                                    ]),
                              ))
                          .toList()
                    ],
                  );
                }),

              const SizedBox(height: 16),

              /// Submit Button
              CustomBtn(
                  isValidate:
                      (discoverController.selectedFromLat?.value != 0.0 &&
                          discoverController.selectedToLat?.value != 0.0),
                  onTap: () {
                    discoverController.getBookingRidersApi();
                    Get.off(() => BookTransportMain(
                          vehicleType: widget.vehicleType,
                        ));
                  },
                  title: AppStrings.confirmLocation.tr),
              const SizedBox(height: 8),
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
    final primary = AppColors.primaryColor;

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
