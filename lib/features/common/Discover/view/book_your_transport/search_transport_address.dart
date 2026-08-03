import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/map_pick_address_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/passenger_booking_main.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/search_address_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/route_polyline_service.dart';
import 'package:BlueEra/core/map/osrm_routing.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
// SearchAddressScreen has not been migrated yet and still takes the Google
// coordinate type. Prefixed; goes when that screen follows.
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../controller/discover_controller.dart';

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

  BlueMapController? mapController;
  /// Road route between pickup and drop, once fetched.
  List<LatLng> _routeCoords = const [];

  List<BlueMapPolyline> get _polylines => [
        if (_routeCoords.length >= 2)
          BlueMapPolyline(
            id: 'route',
            points: _routeCoords,
            width: 6,
            color: AppColors.primaryColor,
          ),
      ];

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

  /// `place_id` currently being resolved by a row tap, or null. Drives the row
  /// spinner and blocks a second tap while a lookup is in flight.
  String? _resolvingPlaceId;
  List<Map<String, dynamic>> _recentSearches = [];

  // ─── Pick-on-map state ──────────────────────────────────────────────────
  bool _isPickingOnMap = false;
  LatLng? _pickedLatLng;
  String? _pickedAddress;
  bool _isResolvingPickedAddress = false;
  bool _isPinDragging = false; // pin lifts while the user pans the map
  String? _favoriteSavingTag; // 'home' | 'office' | 'hostel' while saving

  LatLng get _currentLatLng {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat != 0.0 && lng != 0.0) return LatLng(lat, lng);
    return const LatLng(26.7836, 80.9013);
  }

  bool get _isSearching => _activeField != _ActiveField.none;

  // Listens for any change to the from/to lat or lng on the shared
  // controller and re-syncs the map (markers + camera + route).
  Worker? _fromLatWorker;
  Worker? _fromLngWorker;
  Worker? _toLatWorker;
  Worker? _toLngWorker;
  Timer? _syncDebounce;

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
      _attachLocationWorkers();
    });
  }

  void _attachLocationWorkers() {
    void scheduleSync() {
      // Coalesce burst updates (lat + lng + address are written back to
      // back when a search prediction is selected) into a single map
      // re-render, so the camera lands on the final position instead of
      // an interim half-updated one.
      _syncDebounce?.cancel();
      _syncDebounce = Timer(const Duration(milliseconds: 60), () {
        if (!mounted || _isPickingOnMap) return;
        _updateMarkersAndRoute();
      });
    }

    _fromLatWorker = ever(
        discoverController.selectedFromLat ?? RxDouble(0.0),
        (_) => scheduleSync());
    _fromLngWorker = ever(
        discoverController.selectedFromLong ?? RxDouble(0.0),
        (_) => scheduleSync());
    _toLatWorker = ever(discoverController.selectedToLat ?? RxDouble(0.0),
        (_) => scheduleSync());
    _toLngWorker = ever(discoverController.selectedToLong ?? RxDouble(0.0),
        (_) => scheduleSync());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _syncDebounce?.cancel();
    _fromLatWorker?.dispose();
    _fromLngWorker?.dispose();
    _toLatWorker?.dispose();
    _toLngWorker?.dispose();
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

      discoverController.markers
        ..clear()
        ..add(
          BlueMapMarker(
            id: 'from',
            position: pickup,
            icon: Icons.location_on,
            color: Colors.blue,
            anchor: BlueMarkerAnchor.bottom,
          ),
        );

      await mapController?.moveTo(pickup, zoom: 15);
      if (mounted) setState(() {});
    } catch (e) {
      log("Error setting initial location: $e");
    }
  }

  Future<void> _onMapCreated(BlueMapController controller) async {
    mapController = controller;
    if (!mounted) return;
    final target = fromLatLng ?? toLatLng ?? _currentLatLng;
    await mapController?.moveTo(target, zoom: 15);
  }

  void _addMarkers(LatLng pickup, LatLng drop) {
    // Ids are stable, so re-selecting a place replaces its pin rather than
    // stacking a second one on top.
    discoverController.markers
      ..removeWhere((m) => m.id == 'pickup' || m.id == 'drop')
      ..add(
        BlueMapMarker(
          id: 'pickup',
          position: pickup,
          icon: Icons.location_on,
          color: Colors.blue,
          anchor: BlueMarkerAnchor.bottom,
        ),
      )
      ..add(
        BlueMapMarker(
          id: 'drop',
          position: drop,
          icon: Icons.location_on,
          color: Colors.red,
          anchor: BlueMarkerAnchor.bottom,
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
    final PolylineResult? result = await RoutePolylineService.fetch(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
    );

    if (!mounted) return;

    if (result != null && result.points.isNotEmpty) {
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
        _routeCoords = routeCoords;
      });

      _fitBounds(start, end);
    }
  }

  void _fitBounds(LatLng start, LatLng end) {
    mapController?.fitPoints([start, end], padding: 80);
  }

  void _updateMarkersAndRoute() {
    discoverController.markers.clear();

    final hasFrom = discoverController.selectedFromLat?.value != 0.0 &&
        discoverController.selectedFromLong?.value != 0.0;
    final hasTo = discoverController.selectedToLat?.value != 0.0 &&
        discoverController.selectedToLong?.value != 0.0;

    if (hasFrom) {
      fromLatLng = LatLng(
        discoverController.selectedFromLat!.value,
        discoverController.selectedFromLong!.value,
      );
      discoverController.markers.add(
        BlueMapMarker(
          id: "from",
          position: fromLatLng!,
          icon: Icons.location_on,
          color: Colors.blue,
          anchor: BlueMarkerAnchor.bottom,
        ),
      );
    } else {
      fromLatLng = null;
    }

    if (hasTo) {
      toLatLng = LatLng(
        discoverController.selectedToLat!.value,
        discoverController.selectedToLong!.value,
      );
      discoverController.markers.add(
        BlueMapMarker(
          id: "to",
          position: toLatLng!,
          icon: Icons.location_on,
          color: Colors.red,
          anchor: BlueMarkerAnchor.bottom,
        ),
      );
    } else {
      toLatLng = null;
    }

    // Mirror the change on the map: if both ends are set, draw + fit the
    // route; otherwise animate the camera to whichever single pin exists
    // so any address change (search pick / map tap / favourite, etc.)
    // visibly moves the map.
    if (hasFrom && hasTo) {
      _getRoutePolyline(fromLatLng!, toLatLng!);
    } else {
      _polylines.clear();
      _distanceText = null;
      discoverController.roadDistanceKm.value = 0.0;
      final target = fromLatLng ?? toLatLng;
      if (target != null) {
        mapController?.moveTo(target, zoom: 15);
      }
    }
    if (mounted) setState(() {});
  }

  // ─── Inline search ──────────────────────────────────────────────────────

  Future<void> _openSearchForPickup() async {
    _activeField = _ActiveField.pickup;
    await _pushSearchAddressScreen(isPickup: true);
  }

  Future<void> _openSearchForDrop() async {
    _activeField = _ActiveField.drop;
    await _pushSearchAddressScreen(isPickup: false);
  }

  Future<void> _pushSearchAddressScreen({required bool isPickup}) async {
    final start = isPickup
        ? (fromLatLng ?? _currentLatLng)
        : (toLatLng ?? fromLatLng ?? _currentLatLng);
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => SearchAddressScreen(
          isPickup: isPickup,
          initialMapCenter: gmaps.LatLng(start.latitude, start.longitude),
        ),
      ),
    );
    if (!mounted) {
      _activeField = _ActiveField.none;
      return;
    }
    if (result == null) {
      // Back/cancel — clear active field so the bottom UI restores.
      setState(() => _activeField = _ActiveField.none);
      return;
    }
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = (result['address'] as String?) ?? '';
    if (lat == null || lng == null) {
      setState(() => _activeField = _ActiveField.none);
      return;
    }
    await _applySelectedLocation(lat, lng, address);
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
        // Predictions render immediately and NOTHING is resolved here. The
        // lat/lng + distance hydration that used to run over every prediction
        // cost one billed Place Details per row, per keystroke burst; the tap
        // handler now resolves the single row the user picks. Nearby results
        // still come first — the autocomplete request is location-biased, which
        // is free. See docs/GOOGLE_MAPS_COST_GUIDE.md §3.1.
        setState(() {
          _predictions = results;
          _isLoadingPredictions = false;
        });
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

    // Cancel the worker debounce — we already know the final position
    // and want the map to land on it deterministically, without waiting
    // for the next worker tick.
    _syncDebounce?.cancel();

    _closeSearch();
    _updateMarkersAndRoute();

    // Force the camera to the freshly picked point. _updateMarkersAndRoute
    // also tries to animate, but only when a single end is set; when both
    // are set it fits to a route polyline that's still being fetched. This
    // guarantees the map visibly moves to the just-selected address even
    // in the both-set case, then the route fit will follow once it loads.
    final newPoint = LatLng(lat, lng);
    mapController?.moveTo(newPoint, zoom: 15);
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
    _enterPickOnMapModeAt(start, field: _activeField);
  }

  /// Push the dedicated Rapido-style map picker. The active field
  /// (pickup/drop) is locked in for the trip there + back, so we apply
  /// the result to the right side on return.
  Future<void> _enterPickOnMapModeAt(LatLng start,
      {required _ActiveField field}) async {
    final resolvedField =
        field == _ActiveField.none ? _ActiveField.pickup : field;
    setState(() {
      _activeField = resolvedField;
    });
    _searchFocusNode.unfocus();

    final isPickup = resolvedField == _ActiveField.pickup;
    final otherEnd = isPickup ? toLatLng : fromLatLng;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickAddressScreen(
          initialLatLng: LatLng(start.latitude, start.longitude),
          isPickup: isPickup,
          otherEndLatLng: otherEnd == null
              ? null
              : LatLng(otherEnd.latitude, otherEnd.longitude),
        ),
      ),
    );

    if (!mounted || result == null) return;
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = (result['address'] as String?) ?? '';
    if (lat == null || lng == null) return;
    await _applySelectedLocation(lat, lng, address);
  }

  /// While picking on the map, keep the *other* already-selected marker
  /// visible so the user has a reference point. The active field's pin is
  /// represented by the floating center indicator, not a marker.
  List<BlueMapMarker> _referenceMarkersWhilePicking() {
    final markers = <BlueMapMarker>[];
    if (_activeField == _ActiveField.pickup) {
      if (toLatLng != null) {
        markers.add(BlueMapMarker(
          id: 'to',
          position: toLatLng!,
          icon: Icons.location_on,
          color: Colors.red,
          anchor: BlueMarkerAnchor.bottom,
        ));
      }
    } else if (_activeField == _ActiveField.drop) {
      if (fromLatLng != null) {
        markers.add(BlueMapMarker(
          id: 'from',
          position: fromLatLng!,
          icon: Icons.location_on,
          color: Colors.blue,
          anchor: BlueMarkerAnchor.bottom,
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
      _isPinDragging = false;
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

  Future<void> _saveFavoriteFromPickedPin(String tag) async {
    if (_pickedLatLng == null || _isResolvingPickedAddress) return;
    final address = _pickedAddress ?? '';
    if (address.isEmpty) {
      commonSnackBar(message: 'Address is still loading, try again.');
      return;
    }
    setState(() => _favoriteSavingTag = tag);
    try {
      final res = await FavoriteLocationRepo().addFavoriteLocation(
        address: address,
        latitude: _pickedLatLng!.latitude,
        longitude: _pickedLatLng!.longitude,
        tag: tag,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        commonSnackBar(message: 'Saved to ${_favoriteLabelFor(tag)}');
      } else {
        commonSnackBar(
          message: res.message ?? 'Could not save favourite',
        );
      }
    } catch (e) {
      if (!mounted) return;
      commonSnackBar(message: 'Could not save favourite');
      log('addFavoriteLocation error: $e');
    } finally {
      if (mounted) setState(() => _favoriteSavingTag = null);
    }
  }

  String _favoriteLabelFor(String tag) {
    switch (tag) {
      case 'home':
        return 'Home';
      case 'office':
        return 'Office';
      case 'hostel':
        return 'Hostel';
      default:
        return tag;
    }
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
        body: SafeArea(
          child: Stack(
            children: [
            /// Full-screen map
            Positioned.fill(
              child: BlueMap(
                initialCenter: _currentLatLng,
                initialZoom: 15,
                myLocationEnabled: true,
                onMapCreated: _onMapCreated,
                // A fresh list instance each build, so any change in the
                // underlying collections is picked up by BlueMap's diff.
                markers: _isPickingOnMap
                    ? _referenceMarkersWhilePicking()
                    : List<BlueMapMarker>.from(discoverController.markers),
                polylines: _isPickingOnMap
                    ? const []
                    : List<BlueMapPolyline>.from(_polylines),
                onCameraMoved: _isPickingOnMap
                    ? (centre) {
                        _pickedLatLng = centre;
                        // Lift the pin + clear stale address as soon as
                        // the user starts panning, so the header reads
                        // "Fetching address..." in real time.
                        if (!_isPinDragging) {
                          setState(() {
                            _isPinDragging = true;
                            _isResolvingPickedAddress = true;
                            _pickedAddress = null;
                          });
                        }
                      }
                    : null,
                onCameraIdle: _isPickingOnMap
                    ? (centre) {
                        if (_isPinDragging) {
                          setState(() => _isPinDragging = false);
                        }
                        _resolvePickedAddress(centre);
                      }
                    : null,
                // Any tap on the map enters pick-on-map mode at that
                // point — same Submit-button confirm flow as the Choose
                // on Map button. Auto-decides which field to fill: drop
                // first if pickup is already set, otherwise pickup.
                onTap: _isPickingOnMap || _isSearching
                    ? null
                    : (LatLng latLng) {
                        final hasFrom =
                            (discoverController.selectedFromLat?.value ??
                                        0.0) !=
                                    0.0 &&
                                (discoverController.selectedFromLong?.value ??
                                        0.0) !=
                                    0.0;
                        final hasTo =
                            (discoverController.selectedToLat?.value ?? 0.0) !=
                                    0.0 &&
                                (discoverController.selectedToLong?.value ??
                                        0.0) !=
                                    0.0;
                        final target = (hasFrom && !hasTo)
                            ? _ActiveField.drop
                            : _ActiveField.pickup;
                        _enterPickOnMapModeAt(latLng, field: target);
                      },
              ),
            ),

            /// Animated centre pin (Rapido / Uber-style: lifts while
            /// dragging, drops back when idle, with a fixed ground-shadow
            /// at the actual map point so the user always sees where the
            /// pin will land).
            if (_isPickingOnMap)
              IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ground shadow — stays fixed at the map target.
                        Positioned(
                          bottom: 28,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            width: _isPinDragging ? 16 : 10,
                            height: _isPinDragging ? 6 : 4,
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: _isPinDragging ? 0.18 : 0.30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Pin — lifts up while panning.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          bottom: _isPinDragging ? 48 : 32,
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
                      ],
                    ),
                  ),
                ),
              ),

            /// Top section: address card OR inline search panel OR
            /// live picked-address header (in pick-on-map mode).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _isPickingOnMap
                  ? _buildPickedAddressHeader()
                  : (_isSearching
                      ? _buildInlineSearchPanel()
                      : _buildAddressCard()),
            ),

            /// My-location button (hidden only while the inline search
            /// panel is active; stays visible in pick-on-map mode).
            if (!_isSearching || _isPickingOnMap)
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
                    mapController?.moveTo(target, zoom: 15);
                  },
                  child: const Icon(Icons.my_location,
                      color: AppColors.primaryColor, size: 20),
                ),
              ),

            /// Bottom: pick-on-map confirm bar OR ride booking bottom
            /// sheet. Pick-on-map keeps `_activeField` set to pickup/drop
            /// (so we know which field to fill on submit), which makes
            /// `_isSearching` true — but we still need the Submit button
            /// visible, so allow this branch in pick-on-map mode too.
            if (!_isSearching || _isPickingOnMap)
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
                        _routeCoords = const [];
                        _distanceText = null;
                        discoverController.roadDistanceKm.value = 0.0;
                        if (toLatLng != null) {
                          discoverController.markers.add(
                            BlueMapMarker(
                              id: "to",
                              position: toLatLng!,
                              icon: Icons.location_on,
                              color: Colors.red,
                              anchor: BlueMarkerAnchor.bottom,
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
                        _routeCoords = const [];
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
                    icon: const Icon(Icons.arrow_back_ios_new,
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

  /// Resolve the tapped row's coordinates, then apply it. The one Place Details
  /// call this screen makes — cached per `place_id` for the session by
  /// [PlaceRepo.resolvePlace].
  Future<void> _selectPrediction(PlacePrediction item) async {
    if (_resolvingPlaceId != null) return; // ignore a second tap mid-lookup
    setState(() => _resolvingPlaceId = item.placeId);
    final resolved = await PlaceRepo().resolvePlace(item.placeId);
    if (!mounted) return;
    setState(() => _resolvingPlaceId = null);
    if (resolved == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    item.lat = resolved.lat;
    item.lng = resolved.lng;
    _applySelectedLocation(resolved.lat, resolved.lng, item.description ?? '');
  }

  Widget _buildPredictionTile(PlacePrediction item) {
    final resolving =
        _resolvingPlaceId != null && _resolvingPlaceId == item.placeId;
    return InkWell(
      onTap: resolving ? null : () => _selectPrediction(item),
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
              child: resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    )
                  : const Icon(Icons.location_on_outlined,
                      color: AppColors.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              // The "x km away" subtitle is gone with the per-row Place Details
              // lookup that produced it — see [_fetchPredictions].
              child: CustomText(
                item.description ?? '',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  // ─── Pick-on-map: live header showing picked address ────────────────────

  Widget _buildPickedAddressHeader() {
    final isPickup = _activeField == _ActiveField.pickup;
    return Material(
      color: AppColors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPickup ? AppColors.primaryColor : AppColors.red00)
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color:
                      isPickup ? AppColors.primaryColor : AppColors.red00,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      isPickup ? 'Set pickup location 123' : 'Set drop location',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grayText,
                    ),
                    const SizedBox(height: 2),
                    _isResolvingPickedAddress
                        ? Row(
                            children: const [
                              SizedBox(
                                width: 12,
                                height: 12,
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
                            fontWeight: FontWeight.w600,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pick-on-map: Add to favourites chip row ────────────────────────────

  Widget _buildAddToFavouritesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.bookmark_outline,
                  size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              CustomText(
                'Add to favourites',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _buildFavouriteChip(
                  tag: 'home', label: 'Home', icon: Icons.home_outlined),
              const SizedBox(width: 8),
              _buildFavouriteChip(
                  tag: 'office',
                  label: 'Office',
                  icon: Icons.business_center_outlined),
              const SizedBox(width: 8),
              _buildFavouriteChip(
                  tag: 'hostel',
                  label: 'Hostel',
                  icon: Icons.apartment_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavouriteChip({
    required String tag,
    required String label,
    required IconData icon,
  }) {
    final isSaving = _favoriteSavingTag == tag;
    final disabled = _favoriteSavingTag != null ||
        _isResolvingPickedAddress ||
        _pickedLatLng == null;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: disabled ? null : () => _saveFavoriteFromPickedPin(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grayText.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              )
            else
              Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
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
            _buildAddToFavouritesRow(),
            const SizedBox(height: 14),
            CustomBtn(
              isValidate:
                  !_isResolvingPickedAddress && _pickedLatLng != null,
              onTap: _confirmPickedLocation,
              title: isPickup ? 'Confirm Pickup' : 'Confirm Drop',
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
                  Get.off(() => PassengerBookingMain(
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
