import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../controller/discover_controller.dart';
import 'book_transport_main.dart';

enum _ActiveField { none, pickup, drop }

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
  static const String _recentSearchesKey = 'recent_transport_searches';

  final authController = getOrPut(() => AuthController());
  final discoverController = getOrPut(() => DiscoverController());

  GoogleMapController? mapController;
  Set<Polyline> _polylines = {};

  LatLng? fromLatLng;
  LatLng? toLatLng;
  String? _distanceText;

  // ─── Inline search state ────────────────────────────────────────────────
  _ActiveField _activeField = _ActiveField.none;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isLoadingPredictions = false;
  List<PlacePrediction> _predictions = [];
  List<Map<String, dynamic>> _recentSearches = [];

  // ─── Pick-on-map state ──────────────────────────────────────────────────
  bool _isPickingOnMap = false;
  LatLng? _pickedLatLng;
  String? _pickedAddress;
  bool _isResolvingPickedAddress = false;

  LatLng get _currentLatLng {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat != 0.0 && lng != 0.0) return LatLng(lat, lng);
    return const LatLng(26.7836, 80.9013);
  }

  bool get _isSearching => _activeField != _ActiveField.none;

  @override
  void initState() {
    super.initState();
    _setVehicleType();
    _loadRecentSearches();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocations();
      authController.isSearchOpen.value = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// If both from & to are already selected, show route immediately.
  /// Otherwise, set current location as "from".
  Future<void> _initializeLocations() async {
    final hasFrom = (discoverController.selectedFromLat?.value ?? 0) != 0.0 &&
        (discoverController.selectedFromLong?.value ?? 0) != 0.0;
    final hasTo = (discoverController.selectedToLat?.value ?? 0) != 0.0 &&
        (discoverController.selectedToLong?.value ?? 0) != 0.0;

    if (hasFrom && hasTo) {
      fromLatLng = LatLng(
        discoverController.selectedFromLat!.value,
        discoverController.selectedFromLong!.value,
      );
      toLatLng = LatLng(
        discoverController.selectedToLat!.value,
        discoverController.selectedToLong!.value,
      );
      _updateMarkersAndRoute();
    } else {
      await _setInitialCurrentLocation();
    }
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

      final pickup = LatLng(LocationService.lat, LocationService.lng);
      fromLatLng = pickup;

      discoverController.markers.clear();
      discoverController.markers.add(
        Marker(
          markerId: const MarkerId("from"),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(pickup, 15),
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      log("Error setting initial location: $e");
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    if (!mounted) return;
    try {
      final target = fromLatLng ?? toLatLng ?? _currentLatLng;
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.0),
      );
    } catch (e) {
      debugPrint("Error animating camera: $e");
    }
  }

  void _addMarkers(LatLng pickup, LatLng drop) {
    discoverController.markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    discoverController.markers.add(
      Marker(
        markerId: const MarkerId("drop"),
        position: drop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

      double totalKm = 0;
      for (int i = 0; i < routeCoords.length - 1; i++) {
        totalKm += calculateDistanceKm(
          routeCoords[i].latitude,
          routeCoords[i].longitude,
          routeCoords[i + 1].latitude,
          routeCoords[i + 1].longitude,
        );
      }

      discoverController.roadDistanceKm.value = totalKm;

      setState(() {
        _distanceText = totalKm < 1
            ? '${(totalKm * 1000).round()} m'
            : '${totalKm.toStringAsFixed(1)} km';
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: routeCoords,
            width: 6,
            color: AppColors.primaryColor,
            geodesic: true,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      });

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
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _updateMarkersAndRoute() {
    discoverController.markers.clear();

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
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

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
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      if (fromLatLng != null) {
        _getRoutePolyline(fromLatLng!, toLatLng!);
      }
    }
    if (mounted) setState(() {});
  }

  // ─── Inline search ──────────────────────────────────────────────────────

  void _openSearchForPickup() {
    setState(() {
      _activeField = _ActiveField.pickup;
      _searchController.text = '';
      _searchQuery = '';
      _predictions = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _openSearchForDrop() {
    setState(() {
      _activeField = _ActiveField.drop;
      _searchController.text = '';
      _searchQuery = '';
      _predictions = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _activeField = _ActiveField.none;
      _searchController.clear();
      _searchQuery = '';
      _predictions = [];
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = query.trim();
      setState(() => _searchQuery = trimmed);
      if (trimmed.isEmpty) {
        setState(() => _predictions = []);
      } else {
        _fetchPredictions(trimmed);
      }
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() => _isLoadingPredictions = true);
    try {
      final responseModel = await PlaceRepo().autoCompleteSearch(query: query);
      if (!mounted) return;
      if (responseModel.statusCode == 200) {
        final data = responseModel.response?.data;
        final predictionsJson = (data['predictions'] as List?) ?? [];
        final results = PlacePrediction.fromList(predictionsJson);
        setState(() {
          _predictions = results;
          _isLoadingPredictions = false;
        });

        // Hydrate lat/lng + distance for each prediction
        for (final prediction in results) {
          try {
            final detailsResponse = await PlaceRepo()
                .getCompletePlaceDetails(placeId: prediction.placeId ?? '');
            final detailsData = detailsResponse.response?.data;
            final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
            final location = placeDetails.result?.geometry?.location;

            final distance = Geolocator.distanceBetween(
                  LocationService.lat,
                  LocationService.lng,
                  location?.lat ?? 0.0,
                  location?.lng ?? 0.0,
                ) /
                1000;

            prediction.lat = location?.lat ?? 0.0;
            prediction.lng = location?.lng ?? 0.0;
            prediction.distanceInKm = "${distance.toStringAsFixed(2)} km";
          } catch (e) {
            log("Place details error: $e");
          }
        }
        if (mounted) setState(() {});
      } else {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    } catch (e) {
      log("Autocomplete error: $e");
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    }
  }

  // ─── Recent searches ────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentSearchesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches =
          stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveRecentSearch(double lat, double lng, String address) async {
    if (address.isEmpty) return;
    final entry = {'lat': lat, 'lng': lng, 'address': address};
    _recentSearches.removeWhere((e) => e['address'] == address);
    _recentSearches.insert(0, entry);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) setState(() => _recentSearches.clear());
  }

  // ─── Apply selected location to active field ────────────────────────────

  Future<void> _applySelectedLocation(
      double lat, double lng, String address) async {
    await _saveRecentSearch(lat, lng, address);

    if (_activeField == _ActiveField.pickup) {
      discoverController.selectedFromLat?.value = lat;
      discoverController.selectedFromLong?.value = lng;
      discoverController.selectedFromAddress?.value = address;
    } else if (_activeField == _ActiveField.drop) {
      discoverController.selectedToLat?.value = lat;
      discoverController.selectedToLong?.value = lng;
      discoverController.selectedToAddress?.value = address;
    }

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

    _closeSearch();
    _updateMarkersAndRoute();
  }

  void _useCurrentLocation() {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    final address =
        LocationService.userCurrentAddress.value.formattedAddress;
    if (lat == 0.0 && lng == 0.0) return;
    _applySelectedLocation(lat, lng, address);
  }

  // ─── Pick on map mode ───────────────────────────────────────────────────

  void _enterPickOnMapMode() {
    final start = _activeField == _ActiveField.pickup
        ? (fromLatLng ?? _currentLatLng)
        : (toLatLng ?? fromLatLng ?? _currentLatLng);
    setState(() {
      _isPickingOnMap = true;
      _pickedLatLng = start;
      _pickedAddress = null;
    });
    _searchFocusNode.unfocus();
    _resolvePickedAddress(start);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(start, 16));
    });
  }

  /// While picking on the map, keep the *other* already-selected marker
  /// visible so the user has a reference point. The active field's pin is
  /// represented by the floating center indicator, not a marker.
  Set<Marker> _referenceMarkersWhilePicking() {
    final markers = <Marker>{};
    if (_activeField == _ActiveField.pickup) {
      if (toLatLng != null) {
        markers.add(Marker(
          markerId: const MarkerId("to"),
          position: toLatLng!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    } else if (_activeField == _ActiveField.drop) {
      if (fromLatLng != null) {
        markers.add(Marker(
          markerId: const MarkerId("from"),
          position: fromLatLng!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    }
    return markers;
  }

  void _exitPickOnMapMode() {
    setState(() {
      _isPickingOnMap = false;
      _pickedLatLng = null;
      _pickedAddress = null;
    });
  }

  Future<void> _resolvePickedAddress(LatLng latLng) async {
    setState(() {
      _isResolvingPickedAddress = true;
      _pickedAddress = null;
    });
    try {
      final address = await LocationService.getAddressUsingLatLng(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _pickedAddress = address;
        _isResolvingPickedAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickedAddress = '';
        _isResolvingPickedAddress = false;
      });
    }
  }

  void _confirmPickedLocation() {
    if (_pickedLatLng == null) return;
    final lat = _pickedLatLng!.latitude;
    final lng = _pickedLatLng!.longitude;
    final address = _pickedAddress ?? '';
    _exitPickOnMapMode();
    _applySelectedLocation(lat, lng, address);
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPickingOnMap && !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isPickingOnMap) {
          _exitPickOnMapMode();
        } else if (_isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: const CommonBackAppBar(),
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
                markers: _isPickingOnMap
                    ? _referenceMarkersWhilePicking()
                    : discoverController.markers,
                polylines: _isPickingOnMap ? const {} : _polylines,
                onCameraMove: _isPickingOnMap
                    ? (pos) {
                        _pickedLatLng = pos.target;
                      }
                    : null,
                onCameraIdle: _isPickingOnMap
                    ? () {
                        if (_pickedLatLng != null) {
                          _resolvePickedAddress(_pickedLatLng!);
                        }
                      }
                    : null,
                onTap: _isPickingOnMap || _isSearching
                    ? null
                    : (LatLng latLng) async {
                        // Case 1: From already selected -> set To
                        if (discoverController.selectedFromLat?.value != 0.0 &&
                            discoverController.selectedFromLong?.value != 0.0 &&
                            (discoverController.selectedToLat?.value == 0.0 ||
                                discoverController.selectedToLong?.value ==
                                    0.0)) {
                          discoverController.selectedToLat?.value =
                              latLng.latitude;
                          discoverController.selectedToLong?.value =
                              latLng.longitude;
                          toLatLng = latLng;
                        }
                        // Case 2: From not selected -> set From
                        else if (discoverController.selectedFromLat?.value ==
                                0.0 ||
                            discoverController.selectedFromLong?.value == 0.0) {
                          discoverController.selectedFromLat?.value =
                              latLng.latitude;
                          discoverController.selectedFromLong?.value =
                              latLng.longitude;
                          fromLatLng = latLng;
                          discoverController.markers.clear();
                          _polylines.clear();
                          _distanceText = null;
                          discoverController.roadDistanceKm.value = 0.0;
                        }
                        // Case 3: Both selected -> reset (Uber behaviour)
                        else {
                          discoverController.selectedFromLat?.value =
                              latLng.latitude;
                          discoverController.selectedFromLong?.value =
                              latLng.longitude;
                          discoverController.selectedToLat?.value = 0.0;
                          discoverController.selectedToLong?.value = 0.0;
                          fromLatLng = latLng;
                          toLatLng = null;
                          discoverController.markers.clear();
                          _polylines.clear();
                          _distanceText = null;
                          discoverController.roadDistanceKm.value = 0.0;
                        }

                        String address =
                            await LocationService.getAddressUsingLatLng(
                          latitude: latLng.latitude,
                          longitude: latLng.longitude,
                        );

                        if (toLatLng == latLng) {
                          discoverController.selectedToAddress?.value = address;
                        } else {
                          discoverController.selectedFromAddress?.value =
                              address;
                        }

                        _updateMarkersAndRoute();
                      },
              ),
            ),

            /// Center pin overlay (pick-on-map)
            if (_isPickingOnMap)
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_on,
                      color: _activeField == _ActiveField.drop
                          ? AppColors.red00
                          : AppColors.primaryColor,
                      size: 48,
                      shadows: const [
                        Shadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ),

            /// Top section: address card OR inline search panel
            if (!_isPickingOnMap)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _isSearching
                    ? _buildInlineSearchPanel()
                    : _buildAddressCard(),
              ),

            /// My-location button (hidden in search/pick mode top-right interaction)
            if (!_isSearching)
              Positioned(
                right: 16,
                bottom: (_isPickingOnMap ? 140 : _bottomSheetHeight) + 16,
                child: FloatingActionButton.small(
                  heroTag: "search_my_location",
                  backgroundColor: AppColors.white,
                  onPressed: () {
                    final target = _isPickingOnMap
                        ? _currentLatLng
                        : (fromLatLng ?? _currentLatLng);
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(target, 15.0),
                    );
                  },
                  child: const Icon(Icons.my_location,
                      color: AppColors.primaryColor, size: 20),
                ),
              ),

            /// Bottom: pick-on-map confirm bar OR ride booking bottom sheet
            if (!_isSearching)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _isPickingOnMap
                    ? _buildPickOnMapConfirmBar()
                    : _rideBookingBottomSheet(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Top: address card (default) ────────────────────────────────────────

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Indicator column
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 32,
                    color: AppColors.grayText.withValues(alpha: 0.3),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: AppColors.red00, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              /// Pickup + drop fields
              Expanded(
                child: Column(
                  children: [
                    _buildAddressField(
                      isPickup: true,
                      placeholder: 'Pickup location',
                      onTap: _openSearchForPickup,
                      onClear: () {
                        discoverController.selectedFromLat?.value = 0.0;
                        discoverController.selectedFromLong?.value = 0.0;
                        discoverController.selectedFromAddress?.value = "";
                        fromLatLng = null;
                        discoverController.markers.clear();
                        _polylines.clear();
                        _distanceText = null;
                        discoverController.roadDistanceKm.value = 0.0;
                        if (toLatLng != null) {
                          discoverController.markers.add(
                            Marker(
                              markerId: const MarkerId("to"),
                              position: toLatLng!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed),
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),
                    if (_distanceText != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.route,
                                size: 14, color: AppColors.primaryColor),
                            const SizedBox(width: 6),
                            CustomText(
                              _distanceText!,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    _buildAddressField(
                      isPickup: false,
                      placeholder: AppStrings.whereAreYouGoing.tr,
                      onTap: _openSearchForDrop,
                      onClear: () {
                        discoverController.selectedToLat?.value = 0.0;
                        discoverController.selectedToLong?.value = 0.0;
                        discoverController.selectedToAddress?.value = "";
                        toLatLng = null;
                        _polylines.clear();
                        _distanceText = null;
                        discoverController.roadDistanceKm.value = 0.0;
                        _updateMarkersAndRoute();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required bool isPickup,
    required String placeholder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.greyE4,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                final value = isPickup
                    ? discoverController.selectedFromAddress?.value
                    : discoverController.selectedToAddress?.value;
                final isEmpty = value == null || value.isEmpty;
                final currentAddress = LocationService
                    .userCurrentAddress.value.formattedAddress;
                final fallback = isPickup
                    ? (currentAddress.isNotEmpty ? currentAddress : placeholder)
                    : placeholder;
                return CustomText(
                  isEmpty ? fallback : value,
                  fontSize: 13,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w500,
                  color: isEmpty && !isPickup ? AppColors.grayText : null,
                );
              }),
            ),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close,
                  size: 18, color: AppColors.grayText),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top: inline search panel ───────────────────────────────────────────

  Widget _buildInlineSearchPanel() {
    final isPickup = _activeField == _ActiveField.pickup;
    return Material(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header bar with back + search field
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.black),
                    onPressed: _closeSearch,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isPickup
                                    ? AppColors.primaryColor
                                    : AppColors.red00,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              isPickup ? 'Pickup' : 'Drop',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grayText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.greyE4.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: isPickup
                                  ? 'Search pickup location'
                                  : 'Search drop location',
                              hintStyle: const TextStyle(
                                color: AppColors.grayText,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.grayText, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18,
                                          color: AppColors.grayText),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _predictions = [];
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Suggestions list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: Container(
                color: AppColors.white,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      /// Use Current Location
                      _buildActionTile(
                        icon: Icons.my_location,
                        iconBgColor:
                            AppColors.primaryColor.withValues(alpha: 0.12),
                        iconColor: AppColors.primaryColor,
                        title: "Use Current Location",
                        titleColor: AppColors.primaryColor,
                        subtitle: LocationService
                            .userCurrentAddress.value.formattedAddress,
                        onTap: _useCurrentLocation,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            Divider(height: 1, color: Colors.grey.shade200),
                      ),

                      /// Choose on Map
                      _buildActionTile(
                        icon: Icons.map_outlined,
                        iconBgColor:
                            AppColors.primaryColor.withValues(alpha: 0.12),
                        iconColor: AppColors.primaryColor,
                        title: "Choose on Map",
                        subtitle:
                            "Move the map to pin the exact spot",
                        onTap: _enterPickOnMapMode,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            Divider(height: 1, color: Colors.grey.shade200),
                      ),

                      /// Loading or results
                      if (_isLoadingPredictions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (_searchQuery.isNotEmpty &&
                          _predictions.isNotEmpty)
                        ..._predictions.map(_buildPredictionTile)
                      else if (_searchQuery.isNotEmpty &&
                          _predictions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 16),
                          child: Center(
                            child: CustomText(
                              "No results found",
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        )
                      else if (_recentSearches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule,
                                      size: 16, color: AppColors.grayText),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    "Recent Searches",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grayText,
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: _clearRecentSearches,
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: CustomText(
                                    "Clear All",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.red00,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._recentSearches.map(_buildRecentTile),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionTile(PlacePrediction item) {
    return InkWell(
      onTap: () {
        final lat = item.lat ?? 0.0;
        final lng = item.lng ?? 0.0;
        final address = item.description ?? '';
        if (lat == 0.0 && lng == 0.0) return;
        _applySelectedLocation(lat, lng, address);
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: AppColors.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.description ?? '',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((item.distanceInKm ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    CustomText(
                      item.distanceInKm ?? '',
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.north_west,
                color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTile(Map<String, dynamic> search) {
    return InkWell(
      onTap: () {
        final lat = (search['lat'] as num).toDouble();
        final lng = (search['lng'] as num).toDouble();
        final address = search['address'] as String;
        _applySelectedLocation(lat, lng, address);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: AppColors.grayText, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomText(
                search['address'] as String,
                fontSize: 14,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.north_west, color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    CustomText(
                      subtitle,
                      fontSize: 12,
                      color: AppColors.grayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Pick-on-map confirm bar ────────────────────────────────────────────

  Widget _buildPickOnMapConfirmBar() {
    final isPickup = _activeField == _ActiveField.pickup;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isPickup
                        ? AppColors.primaryColor
                        : AppColors.red00,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                CustomText(
                  isPickup ? 'Set pickup location' : 'Set drop location',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: _isResolvingPickedAddress
                      ? Row(
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor),
                              ),
                            ),
                            SizedBox(width: 8),
                            CustomText(
                              'Fetching address...',
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ],
                        )
                      : CustomText(
                          (_pickedAddress?.isNotEmpty ?? false)
                              ? _pickedAddress!
                              : 'Move map to pin the location',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exitPickOnMapMode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const CustomText(
                      'Cancel',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomBtn(
                    isValidate: !_isResolvingPickedAddress &&
                        _pickedLatLng != null,
                    onTap: _confirmPickedLocation,
                    title: isPickup
                        ? 'Confirm Pickup'
                        : 'Confirm Drop',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom sheet (preserved) ───────────────────────────────────────────

  double get _bottomSheetHeight {
    if (discoverController.selectedHorizontalTab.value == 1 ||
        discoverController.selectedHorizontalTab.value == 3) {
      return 350;
    }
    return 100;
  }

  Widget _rideBookingBottomSheet() {
    return Container(
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
                                child: const Center(
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
                                      imagePath:
                                          AppIconAssets.get_contacts_person,
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
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
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
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
                                  ),
                                ),
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
                                        const CustomText(
                                            AppStrings.parcelDetails,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                        InkWell(
                                          onTap: () {
                                            Get.back();
                                          },
                                          child: const Icon(
                                            Icons.cancel_outlined,
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const CustomText(
                                        AppStrings.parcelCategory,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                    const SizedBox(height: 10),
                                    Obx(() {
                                      return CommonDropdown(
                                        items: [
                                          AppStrings.documentParcel.tr,
                                          AppStrings.productParcel.tr,
                                          AppStrings.othersParcel.tr,
                                        ],
                                        selectedValue: discoverController
                                            .selectedParcelCategory.value,
                                        hintText: AppStrings
                                            .chooseParcelCategory.tr,
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
                                      title:
                                          AppStrings.weightInKgOptional.tr,
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
                                      hintText: AppStrings
                                          .parcelDescriptionHint.tr,
                                      validator: (value) {
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 26),
                                    CustomBtn(
                                      isValidate: true,
                                      onTap: () {
                                        discoverController.addParcelDetails();
                                        Get.back();
                                      },
                                      title: AppStrings.save.tr,
                                    ),
                                  ],
                                ),
                              ),
                            ));
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: AppColors.primaryColor,
                              ),
                              CustomText(
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
                    const SizedBox(height: 10),
                    ...discoverController.parcelDetailsList.map(
                      (e) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.whiteE5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  e.category,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        discoverController
                                            .removeParcelDetails(e);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: AppColors.red,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              e.weightKg,
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                            ),
                            const SizedBox(height: 6),
                            CustomText(
                              e.description,
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),

            const SizedBox(height: 8),

            /// Submit
            SafeArea(
              child: CustomBtn(
                isValidate:
                    (discoverController.selectedFromLat?.value != 0.0 &&
                        discoverController.selectedToLat?.value != 0.0),
                onTap: () {
                  discoverController.getBookingRidersApi();
                  Get.off(() => BookTransportMain(
                        vehicleType: widget.vehicleType,
                      ));
                },
                title: AppStrings.confirmLocation.tr,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
