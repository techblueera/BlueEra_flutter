import 'dart:developer';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/snackbar_helper.dart';

class SearchPlaceList extends StatefulWidget {
  final String query;
  final double lat;
  final double lng;
  final String currentAddress;
  final String fromScreen;
  final Function(double?, double?, String?)? onPlaceSelected;
  final Function()? onRefresh;

  const SearchPlaceList({
    super.key,
    required this.query,
    required this.lat,
    required this.lng,
    required this.currentAddress,
    required this.fromScreen,
    this.onPlaceSelected, this.onRefresh,
  });

  @override
  State<SearchPlaceList> createState() => _SearchPlaceListState();
}

class _SearchPlaceListState extends State<SearchPlaceList> {
  bool isLoading = false;
  bool isGettingCurrentLocation = false; // New state for current location loading
  String? errorMessage;
  List<PlacePrediction> predictions = [];
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  LatLng? targetLocation;

  @override
  void didUpdateWidget(covariant SearchPlaceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {

      _fetchPredictions();
    }
  }


  @override
  void initState() {
    super.initState();
    _handleCurrentLocationTap();
    targetLocation=LatLng(widget.lat, widget.lng);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)),
        AppImageAssets.markerBlue,
      );

      final Marker customMarker = Marker(
        markerId: const MarkerId("custom_marker_id"),
        position: LatLng(widget.lat, widget.lng),
        icon: customIcon,
      );

      setState(() {
        _markers.add(customMarker);
      });

      // Smoothly animate camera to marker
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(widget.lat, widget.lng), 14.0),
      );

    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }

  Future<void> _fetchPredictions() async {
    if (widget.query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final responseModel =
      await PlaceRepo().autoCompleteSearch(query: widget.query);

      if (responseModel.statusCode == 200) {
        final data = responseModel.response?.data;
        final predictionsJson = data['predictions'] as List;
        final results = PlacePrediction.fromList(predictionsJson);
        setState(() {
          isLoading = false;
          predictions = results;
        });

        for (final prediction in results) {
          final detailsResponse = await PlaceRepo()
              .getCompletePlaceDetails(placeId: prediction.placeId ?? '');
          final detailsData = detailsResponse.response?.data;
          logs("detailsResponse====== $detailsData");

          final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
          final location = placeDetails.result?.geometry?.location;

          final distance = Geolocator.distanceBetween(
            widget.lat,
            widget.lng,
            location?.lat ?? 0.0,
            location?.lng ?? 0.0,
          ) /
              1000;

          prediction.lat = location?.lat ?? 0.0;
          prediction.lng = location?.lng ?? 0.0;
          prediction.distanceInKm = "${distance.toStringAsFixed(2)} km";
        }

        setState(() {
          predictions = results;
        });
      } else {
        setState(() {
          errorMessage =
              responseModel.data['error_message'] ?? 'Something went wrong';
          isLoading = false;
        });
      }
    } catch (e) {
      if(!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _handleCurrentLocationTap() async {

    setState(() {
      isGettingCurrentLocation = true;
    });
    if(widget.onRefresh!=null){
      widget.onRefresh;
    }
    Future.delayed(Duration(seconds: 1),(){
      setState(() {
        isGettingCurrentLocation = false;
      });
    });
    try {
    } catch (e) {
      // Handle location error
      if (mounted) {
        commonSnackBar(
            message: "Failed to get location: ${e.toString()}");

      }
    } finally {
      // if (mounted) {
      //   setState(() {
      //     isGettingCurrentLocation = false;
      //   });
      // }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          InkWell(
            onTap: ()=>  navigateToAddPlaceScreen(
                widget.lat,
                widget.lng,
                widget.currentAddress
            ),
            child: Container(
              color: AppColors.whiteF3,
              child: Padding(
                padding: EdgeInsets.only(
                    left: SizeConfig.size20,
                    right: SizeConfig.size20,
                    top: SizeConfig.size15,
                    bottom: SizeConfig.size15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Show loader or location icon based on state
                    isGettingCurrentLocation
                        ? SizedBox(
                      width: SizeConfig.size24,
                      height: SizeConfig.size24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    )
                        : LocalAssets(imagePath: AppIconAssets.currentLocationIcon),
                    SizedBox(width: SizeConfig.size15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            isGettingCurrentLocation
                                ? "Getting current location..."
                                : "Use Current Location",
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                            color: isGettingCurrentLocation
                                ? AppColors.grey44
                                : AppColors.primaryColor,
                          ),
                          SizedBox(height: SizeConfig.size6),
                          if (!isGettingCurrentLocation)
                            CustomText(
                              widget.currentAddress,
                              color: AppColors.grey44,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: (){
              _handleCurrentLocationTap();
            } ,
            child: Container(
              color: AppColors.whiteF3,
              child: Padding(
                padding: EdgeInsets.only(
                    left: SizeConfig.size20,
                    right: SizeConfig.size20,
                    top: SizeConfig.size15,
                    bottom: SizeConfig.size15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: SizeConfig.size15),
                    Expanded(
                      child: CustomText(
                        "Refresh Location",
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              ),
            )
          else if (errorMessage != null)
            Expanded(child: Center(child: Text(errorMessage!)))
          else if (predictions.isEmpty)
              ((!isGettingCurrentLocation)?
              Container(
                height: 240,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.lat, widget.lng),
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  markers: _markers,
                )
              )

                  :Expanded(
                  child: Center(
                      child: CustomText("No results found",
                          color: AppColors.grey44,
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.large))))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: predictions.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final item = predictions[index];
                    return InkWell(
                      onTap: () {
                        log("lat --> lng--> description--> ${item.lat} ${item.lng} ${item.description}");
                        navigateToAddPlaceScreen(
                          item.lat ?? widget.lat,
                          item.lng ?? widget.lng,
                          item.description ?? widget.currentAddress,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size20,
                            vertical: SizeConfig.size15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LocalAssets(
                              imagePath:
                              AppIconAssets.locationOutlineIconGreyIcon,
                              imgColor: AppColors.black,
                              width: SizeConfig.size34,
                              height: SizeConfig.size34,
                              boxFix: BoxFit.cover,
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    item.description,
                                    fontSize: SizeConfig.large,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: SizeConfig.size5),
                                  CustomText(
                                    item.distanceInKm != null
                                        ? item.distanceInKm
                                        : '0.0 Km',
                                    color: AppColors.grey9A,
                                    fontSize: SizeConfig.medium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return CommonHorizontalDivider(
                      color: AppColors.blackA5,
                    );
                  },
                ),
              )
        ],
      ),
    );
  }

  void navigateToAddPlaceScreen(double lat, double lng, String currentAddress) {
    widget.onPlaceSelected?.call(lat, lng, currentAddress);

    switch (widget.fromScreen) {
      case RouteConstant.CustomizeMapScreen:
        break;
      case RouteConstant.addPlaceStepOne:
        unFocus();
        Navigator.pushNamed(
          context,
          RouteHelper.getAddPlaceStepOneScreenRoute(),
        );
        break;
      default:
        Navigator.pop(context);
        break;
    }
  }
}