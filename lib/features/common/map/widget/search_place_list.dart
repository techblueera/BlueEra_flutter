import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
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

  /// `place_id` currently being resolved by a row tap, or null. Drives the row
  /// spinner and blocks a second tap while a lookup is in flight.
  String? _resolvingPlaceId;
  LatLng? targetLocation;

  /// The searched place. Built from the widget's coordinates rather than
  /// assembled asynchronously once the map exists, so the pin is present on the
  /// first frame instead of appearing a beat later.
  List<BlueMapMarker> get _markers => [
        BlueMapMarker(
          id: 'target',
          position: LatLng(widget.lat, widget.lng),
          child: LocalAssets(
            imagePath: AppImageAssets.markerBlue,
            width: 30,
            height: 30,
          ),
          anchor: BlueMarkerAnchor.bottom,
        ),
      ];

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
        // Predictions render straight away; nothing is resolved here. This used
        // to call Place Details for EVERY prediction to fill in lat/lng and a
        // distance label — one billed lookup per row, per search — when the user
        // only ever opens one of them. [_selectPrediction] resolves that one.
        // See docs/GOOGLE_MAPS_COST_GUIDE.md §3.1.
        setState(() {
          isLoading = false;
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

  /// Resolve the tapped prediction, then hand it on.
  ///
  /// Resolving matters more here than elsewhere: this screen's tap used to fall
  /// back to `widget.lat/lng` — the map centre — when a prediction had no
  /// coordinates, so a failed lookup silently selected the WRONG place instead
  /// of reporting anything. It now resolves first and refuses to navigate
  /// without real coordinates.
  Future<void> _selectPrediction(PlacePrediction item) async {
    if (_resolvingPlaceId != null) return; // ignore a second tap mid-lookup
    setState(() => _resolvingPlaceId = item.placeId);
    final resolved = await PlaceRepo().resolvePlace(item.placeId);
    if (!mounted) return;
    setState(() => _resolvingPlaceId = null);
    if (resolved == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    item.lat = resolved.lat;
    item.lng = resolved.lng;
    navigateToAddPlaceScreen(
      resolved.lat,
      resolved.lng,
      item.description ?? widget.currentAddress,
    );
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
                child: BlueMap(
                  initialCenter: LatLng(widget.lat, widget.lng),
                  initialZoom: 14,
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
                    final resolving = _resolvingPlaceId != null &&
                        _resolvingPlaceId == item.placeId;
                    return InkWell(
                      onTap: resolving ? null : () => _selectPrediction(item),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size20,
                            vertical: SizeConfig.size15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: SizeConfig.size34,
                              height: SizeConfig.size34,
                              child: resolving
                                  ? const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryColor),
                                        ),
                                      ),
                                    )
                                  : LocalAssets(
                                      imagePath: AppIconAssets
                                          .locationOutlineIconGreyIcon,
                                      imgColor: AppColors.black,
                                      boxFix: BoxFit.cover,
                                    ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            // The distance subtitle is gone with the per-row
                            // Place Details lookup that produced it — it read
                            // "0.0 Km" until those ~5 calls came back anyway.
                            Expanded(
                              child: CustomText(
                                item.description,
                                fontSize: SizeConfig.large,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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