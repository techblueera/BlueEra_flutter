import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/chat/auth/socket/chat_socket.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Drives the whole Rapido-style ride-booking flow: home → destination search
/// → confirm pickup → vehicle select → searching → tracking → cancel.
///
/// Deliberately standalone — it shares no state with [DiscoverController] and
/// the older `book_your_transport/` screens, so neither flow can regress the
/// other.
///
/// ### Broadcast dispatch
/// Rides are created with `orderType: "broadcast"` and NO `selectedRiders`:
/// the server rings nearby riders in expanding waves (~3 → 6 → 10 km) and the
/// first to accept wins. The customer just polls status until a rider is
/// attached. Contract:
/// docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md
///
/// ### What is live vs. local
/// Ride creation, status, captain location and cancel all hit the real
/// `rider-service/fare/*` API. Four things have no backend (guide §6) and are
/// handled on-device instead: place search (Google Places via [PlaceRepo]),
/// recents and saved places (SharedPreferences), cancel reasons (a shipped
/// list), and fare-raise (disabled — see [kFareRaiseEnabled]).
class RideBookingController extends GetxController {
  /// Broadcast dispatch has no fare-bump endpoint — the "+₹10/₹20/₹30" chips
  /// must not ship until one exists, or the user pays more for nothing.
  /// Guide §6. Flip when the backend lands.
  static const bool kFareRaiseEnabled = false;

  /// How far out the server should look for riders when pricing — mirrors the
  /// old flow's `range_in_km: 20`.
  static const int kRiderSearchRangeKm = 20;

  /// Trip type. `InCity | OutStation | HourlyRental | Parcel`.
  ///
  /// The old screens pick this from a horizontal tab the user taps before
  /// searching (`DiscoverController.getOrderTypeString()`); there is no tab
  /// here, so the Explore tile is the equivalent explicit choice.
  ///
  /// Sent to BOTH the quote and the create call, deliberately from one value:
  /// quoting under one `orderFor` while ordering under another is how the price
  /// on the button stops matching the price on the order.
  static const String _defaultOrderFor = 'InCity';
  final orderFor = _defaultOrderFor.obs;

  /// Trip types the server requires a `pincode` for.
  static const Set<String> _pincodeRequiredFor = {'InCity', 'Parcel'};

  /// `vehicleType` is the ONLY vehicle vocabulary in this flow —
  /// [RideVehicleOption.code] holds the backend enum verbatim.
  ///
  /// An earlier version carried its own codes (`BIKE`, `CAB_ECONOMY`, …) mapped
  /// onto guessed backend values. Three of those guesses (`autoRider`,
  /// `carHatchback`, `carSuv`) are not in the enum at all, so those rows came
  /// back unmatched and the create call sent a `vehicleType` the server does
  /// not accept. A translation layer between two vocabularies can only ever
  /// drift — there is now just the one.
  static const Map<String, String> kVehicleTypeNames = {
    'twoWheelerRider': 'Bike',
    'autoTempo': 'Auto',
    'eRickshaw': 'E-Rickshaw',
    'carMini': 'Cab Mini',
    'carSedan': 'Cab Sedan',
    'suvCar': 'Cab SUV',
    'miniBus': 'Mini Bus',
    'pickupGoods': 'Pickup',
    'miniTruckGoods': 'Mini Truck',
    'largeTruckGoods': 'Large Truck',
    'goods3Wheeler': 'Goods 3-Wheeler',
    'goods4Wheeler': 'Goods 4-Wheeler',
  };

  /// Display name for a vehicle type, used when the response omits a label.
  static String _nameForVehicleType(String vehicleType) =>
      kVehicleTypeNames[vehicleType] ?? vehicleType;

  /// Vehicle the user picked on the Explore rail, if any — a `vehicleType`.
  /// Pre-selects that row once the quote lands instead of the first option.
  final RxnString preselectedVehicleCode = RxnString();

  /// Message from a failed quote (400 missing pincode, 500, …), so the sheet
  /// can say what went wrong instead of showing "no vehicles" for everything.
  /// Null when the request succeeded — including the legitimate no-riders case.
  final RxnString quoteError = RxnString();

  final RideBookingRepo _repo = RideBookingRepo();

  // ---------------------------------------------------------------- location

  /// Where the user currently is — the initial map centre and the default
  /// pickup before they change it.
  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;

  // ------------------------------------------------------------------- trip

  final Rxn<RidePlace> pickup = Rxn<RidePlace>();
  final Rxn<RidePlace> drop = Rxn<RidePlace>();

  /// Intermediate stops added via "Add stop" on the vehicle screen.
  final RxList<RidePlace> stops = <RidePlace>[].obs;

  // ------------------------------------------------------------------ home

  final RxList<RidePlace> recentPlaces = <RidePlace>[].obs;
  final RxList<RidePlace> savedPlaces = <RidePlace>[].obs;
  final isLoadingRecents = false.obs;

  // ---------------------------------------------------------------- search

  final RxList<RidePlace> searchResults = <RidePlace>[].obs;
  final isSearching = false.obs;

  /// The live search text.
  ///
  /// Reactive on purpose: the results list switches between recents and
  /// matches based on the query, and the search screen used to read the
  /// TextEditingController directly inside an Obx. That looked like it worked
  /// (the Obx rebuilt when `searchResults`/`isSearching` changed) but the text
  /// itself was invisible to GetX, so a keystroke that changed nothing else
  /// left the list stale.
  final searchQuery = ''.obs;

  Timer? _searchDebounce;

  // --------------------------------------------------------------- quoting

  final RxList<RideVehicleOption> vehicleOptions = <RideVehicleOption>[].obs;
  final Rxn<RideVehicleOption> selectedVehicle = Rxn<RideVehicleOption>();
  final isQuoting = false.obs;

  /// `CASH` | `ONLINE`. Shown on the fare bar and the trip-details sheet.
  final paymentMode = 'CASH'.obs;

  /// Road distance for the current pickup→drop pair. Sent to the quote as
  /// `distance_in_km` and safe for the UI to show. 0 until the route resolves.
  final tripDistanceKm = 0.0.obs;

  /// Traffic-aware travel time in minutes. Overwritten by the server's
  /// `pricingSignals.durationMin` once a quote lands.
  final tripDurationMinutes = 0.obs;

  /// `pricingSignals.supplyCount` — nearby available riders across all types.
  final supplyCount = 0.obs;

  /// `pricingSignals.weather` — `clear | rain | snow | storm`. Drives the
  /// weather multiplier server-side; surfaced so the UI can explain a surge.
  final weather = 'clear'.obs;

  /// Road geometry of the pickup→drop route, for the map polyline. Empty until
  /// resolved — the vehicle screen draws a straight placeholder until then.
  final RxList<LatLng> routePoints = <LatLng>[].obs;

  /// Endpoints the cached [routePoints] belong to, so a re-quote for an
  /// unchanged trip doesn't re-fetch the route.
  String? _routeCacheKey;

  // --------------------------------------------------------------- booking

  final Rxn<RideBooking> activeBooking = Rxn<RideBooking>();
  final isBooking = false.obs;

  /// Animated 0–1 value behind the "Searching in progress" bar. Advances on a
  /// local timer so the bar moves smoothly between the slower status polls.
  final searchProgress = 0.0.obs;

  /// Extra rupees the user has added via the "+₹20" chips while searching.
  final fareBoost = 0.0.obs;

  final RxList<RideCancelReason> cancelReasons = <RideCancelReason>[].obs;
  final isCancelling = false.obs;

  Timer? _statusTimer;
  Timer? _progressTimer;
  Timer? _captainTimer;
  bool _statusRequestInFlight = false;

  /// Set when the booking ends, so the tracking screen can pop with a reason.
  final Rxn<RideStatus> terminalStatus = Rxn<RideStatus>();

  // ----------------------------------------------------- broadcast socket
  // Real-time signals from the broadcast dispatch (guide §4). Polling stays the
  // source of truth; the socket just finishes the search bar the instant a
  // rider wins and drives the "searching wave N/M" copy. Handlers guard on the
  // active order id, so a stale registration after resetTrip is a no-op — no
  // explicit off() needed.
  final broadcastWave = 0.obs; // current wave (1-based)
  final broadcastTotalWaves = 0.obs; // total waves the server will run
  final broadcastRidersNotified = 0.obs; // riders rung so far this order
  bool _broadcastSocketBound = false;

  // ------------------------------------------------------------- lifecycle

  @override
  void onInit() {
    super.onInit();
    _bootstrapLocation();
    // Saved first, so the hearts are already correct when recents render.
    loadSavedPlaces().then((_) => loadRecentPlaces());
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _stopAllPolling();
    super.onClose();
  }

  void _stopAllPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _captainTimer?.cancel();
    _captainTimer = null;
  }

  // -------------------------------------------------------------- location

  /// Resolve the device position and seed [pickup] with it. Failure is silent:
  /// the user can still type a pickup manually, so a denied permission must
  /// not block the screen.
  Future<void> _bootstrapLocation() async {
    try {
      final Position? position = await getCurrentLocation();
      if (position == null) return;
      currentLat.value = position.latitude;
      currentLng.value = position.longitude;
      pickup.value ??= RidePlace(
        title: 'Current location',
        subtitle: '',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Non-fatal — manual pickup entry still works.
    }
  }

  // ------------------------------------------------------------------ home

  /// Recent destinations, stored on-device.
  ///
  /// There is no recents endpoint (guide §6), so this is a local list keyed to
  /// SharedPreferences — same approach the older transport screens take.
  static const String _recentPlacesKey = 'ride_booking_recent_places';
  static const int _maxRecentPlaces = 8;

  Future<void> loadRecentPlaces() async {
    isLoadingRecents.value = true;
    try {
      final raw = await SharedPreferenceUtils.getSecureValue(_recentPlacesKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      recentPlaces.assignAll(
        decoded.whereType<Map>().map(RidePlace.fromJson),
      );
      // Recents are persisted without their hearted state — re-derive it from
      // the saved list so the icons are right on first paint.
      _applySavedFlags();
    } catch (_) {
      // Corrupt/absent cache is not worth surfacing — an empty recents list is
      // a perfectly good starting state.
    } finally {
      isLoadingRecents.value = false;
    }
  }

  /// Push [place] to the front of the on-device recents, de-duped by
  /// coordinates and capped at [_maxRecentPlaces].
  Future<void> _rememberRecentPlace(RidePlace place) async {
    try {
      final next = <RidePlace>[
        place,
        ...recentPlaces.where((p) =>
            p.latitude != place.latitude || p.longitude != place.longitude),
      ].take(_maxRecentPlaces).toList();
      recentPlaces.assignAll(next);
      await SharedPreferenceUtils.setSecureValue(
        _recentPlacesKey,
        jsonEncode(next.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort — never block navigation on a cache write.
    }
  }

  /// Saved (hearted) places, stored on-device.
  ///
  /// No saved-places endpoint either (guide §6), so these live in
  /// SharedPreferences next to the recents. They do not sync across devices —
  /// swap this for the real endpoint when a places service ships.
  static const String _savedPlacesKey = 'ride_booking_saved_places';

  Future<void> loadSavedPlaces() async {
    try {
      final raw = await SharedPreferenceUtils.getSecureValue(_savedPlacesKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      savedPlaces.assignAll(
        decoded.whereType<Map>().map(
              (m) => RidePlace.fromJson(m).copyWith(isSaved: true),
            ),
      );
      _applySavedFlags();
    } catch (_) {
      // An empty saved list is a fine starting state.
    }
  }

  /// Heart / un-heart a place from the home list or the trip sheet.
  Future<void> toggleSavedPlace(RidePlace place) async {
    final nowSaved = !place.isSaved;

    if (nowSaved) {
      savedPlaces.add(place.copyWith(isSaved: true));
    } else {
      savedPlaces.removeWhere((p) => _samePlace(p, place));
    }

    _replaceInList(recentPlaces, place, place.copyWith(isSaved: nowSaved));
    _replaceInList(searchResults, place, place.copyWith(isSaved: nowSaved));

    try {
      await SharedPreferenceUtils.setSecureValue(
        _savedPlacesKey,
        jsonEncode(savedPlaces.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // Roll back so the heart never lies about persisted state.
      if (nowSaved) {
        savedPlaces.removeWhere((p) => _samePlace(p, place));
      } else {
        savedPlaces.add(place.copyWith(isSaved: true));
      }
      _replaceInList(recentPlaces, place, place.copyWith(isSaved: !nowSaved));
      _replaceInList(searchResults, place, place.copyWith(isSaved: !nowSaved));
    }
  }

  /// Re-apply the hearted flag onto the visible lists after they reload —
  /// saved state lives in its own list, so freshly-fetched rows arrive unset.
  void _applySavedFlags() {
    for (var i = 0; i < recentPlaces.length; i++) {
      final isSaved = savedPlaces.any((s) => _samePlace(s, recentPlaces[i]));
      if (recentPlaces[i].isSaved != isSaved) {
        recentPlaces[i] = recentPlaces[i].copyWith(isSaved: isSaved);
      }
    }
  }

  /// Places are identified by coordinates — the same spot reached via search
  /// and via recents can carry different ids.
  static bool _samePlace(RidePlace a, RidePlace b) =>
      a.latitude == b.latitude && a.longitude == b.longitude;

  void _replaceInList(
      RxList<RidePlace> list, RidePlace target, RidePlace updated) {
    final index = list.indexWhere((p) =>
        p.latitude == target.latitude && p.longitude == target.longitude);
    if (index != -1) list[index] = updated;
  }

  // ---------------------------------------------------------------- search

  /// Debounced autocomplete — 350ms after the last keystroke, so a fast typist
  /// costs one request instead of one per character.
  void onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    searchQuery.value = trimmed;
    if (trimmed.length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(trimmed),
    );
  }

  /// Google Places autocomplete, via the app's existing [PlaceRepo].
  ///
  /// Broadcast dispatch has no places service of its own (guide §6) — it only
  /// needs pickup/drop lat-lng, and the source is our choice. This reuses the
  /// same path the older booking screens already use.
  ///
  /// Autocomplete returns place_ids without coordinates, so each result needs
  /// a details lookup. Those run in parallel and the list is published once,
  /// rather than one setState per resolved row.
  Future<void> _runSearch(String query) async {
    try {
      final response = await PlaceRepo().autoCompleteSearch(query: query);
      if (response.statusCode != 200) {
        searchResults.clear();
        return;
      }
      final body = response.response?.data;
      final predictionsJson = (body is Map ? body['predictions'] : null);
      if (predictionsJson is! List) {
        searchResults.clear();
        return;
      }
      final predictions = PlacePrediction.fromList(predictionsJson);

      final resolved = await Future.wait(
        predictions.map(_resolvePrediction),
        eagerError: false,
      );
      // Drop anything whose coordinates didn't resolve — a place we can't
      // locate can't be a pickup or drop.
      searchResults.assignAll(resolved.whereType<RidePlace>());
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Turn one autocomplete prediction into a [RidePlace] with coordinates.
  /// Returns null when the details lookup fails.
  Future<RidePlace?> _resolvePrediction(PlacePrediction prediction) async {
    final placeId = prediction.placeId ?? '';
    if (placeId.isEmpty) return null;
    try {
      final details = await PlaceRepo().getCompletePlaceDetails(
        placeId: placeId,
      );
      final location = PlaceDetailsResponse.fromJson(details.response?.data)
          .result
          ?.geometry
          ?.location;
      final lat = location?.lat;
      final lng = location?.lng;
      if (lat == null || lng == null) return null;

      // Google's `description` is "Name, Area, City, State, Country" — split
      // on the first comma so the UI's two-line title/subtitle stays honest
      // instead of repeating the whole string twice.
      final description = prediction.description ?? '';
      final comma = description.indexOf(',');
      return RidePlace(
        id: placeId,
        title: comma > 0 ? description.substring(0, comma) : description,
        subtitle: comma > 0 ? description.substring(comma + 1).trim() : '',
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  // -------------------------------------------------------------- trip ends

  void setDrop(RidePlace place) {
    drop.value = place;
    _rememberRecentPlace(place);
  }

  void setPickup(RidePlace place) => pickup.value = place;

  void addStop(RidePlace place) => stops.add(place);

  void removeStop(int index) {
    if (index >= 0 && index < stops.length) stops.removeAt(index);
  }

  /// Swap the two ends — used by the trip-details sheet's edit affordances.
  void swapEnds() {
    final from = pickup.value;
    pickup.value = drop.value;
    drop.value = from;
  }

  // --------------------------------------------------------------- quoting

  /// Record what the user chose on the Explore rail.
  ///
  /// The two are independent: a tile carries a `vehicleType` to pre-select AND
  /// an `orderFor` for the trip. "Parcel on Bike" is `twoWheelerRider` +
  /// `Parcel`; "Bike" is the same vehicle with `InCity`. Call before navigating
  /// into the flow — [fetchQuotes] picks both up.
  void setTripType({String? vehicleType, String orderFor = _defaultOrderFor}) {
    preselectedVehicleCode.value = vehicleType;
    this.orderFor.value = orderFor;
  }

  /// Fetch fares for every vehicle category.
  ///
  /// Pre-selects the Explore choice when the quote contains it, else the first
  /// option, so the Book button is immediately actionable.
  Future<void> fetchQuotes() async {
    final from = pickup.value;
    final to = drop.value;
    if (from == null || to == null) return;
    if (!from.hasCoordinates || !to.hasCoordinates) return;

    final trip = orderFor.value;

    isQuoting.value = true;
    vehicleOptions.clear();
    selectedVehicle.value = null;
    quoteError.value = null;
    try {
      // Trip context the fare depends on. Both are best-effort — a failed
      // geocode or a Directions hiccup must degrade to a coordinates-only
      // quote, not an empty vehicle list, so they resolve in parallel and
      // either may come back null.
      final context = await Future.wait([
        _resolveRoute(from, to),
        _pincodeFor(from),
      ]);
      final distanceKm = context[0] as double?;
      // Required for InCity and Parcel — the server 400s without it. The
      // reverse geocode is the only source we have, so when it fails the
      // request is knowingly sent short rather than silently dropped; the 400
      // message then surfaces through [quoteError].
      final pincode =
          _pincodeRequiredFor.contains(trip) ? context[1] as String? : null;
      tripDistanceKm.value = distanceKm ?? 0;

      final response = await _repo.getDynamicFare(
        pickupLat: from.latitude,
        pickupLng: from.longitude,
        dropLat: to.latitude,
        dropLng: to.longitude,
        orderFor: trip,
        rangeInKm: kRiderSearchRangeKm,
        pincode: pincode,
        distanceInKm: distanceKm,
      );
      if (!response.isSuccess) {
        // 400 (missing param/pincode) or 500 — distinct from "no riders", and
        // the user should not be told the city is empty when we sent a bad
        // request.
        quoteError.value =
            response.message?.toString() ?? 'Could not fetch fares right now.';
        return;
      }
      vehicleOptions.assignAll(_parseDynamicFare(_payload(response)));
      if (vehicleOptions.isEmpty) return; // shape B `{}` — genuinely no riders

      final preferred = preselectedVehicleCode.value;
      selectedVehicle.value = vehicleOptions.firstWhere(
        (o) => o.code == preferred,
        orElse: () => vehicleOptions.first,
      );
    } catch (_) {
      vehicleOptions.clear();
      quoteError.value = 'Could not fetch fares right now.';
    } finally {
      isQuoting.value = false;
    }
  }

  /// Resolve the driving route between the two ends and publish it.
  ///
  /// Serves two consumers off ONE network call: `distance_in_km` on the fare
  /// quote, and the polyline the vehicle screen draws. Straight-line distance
  /// is not a substitute for either — it under-reads real road distance badly
  /// enough to land the quote in the wrong fare slab, and it draws a line
  /// through buildings.
  ///
  /// Prefers the **Routes API with `TRAFFIC_AWARE`**, so the geometry is the
  /// route a driver would actually take right now, and `distanceMeters` /
  /// `duration` come back measured by Google rather than summed off the
  /// polyline. Falls back to the legacy Directions call the old flow uses when
  /// Routes is unavailable — it is a separately-enabled API on the Cloud
  /// project, so this must not become a hard dependency.
  ///
  /// Returns the road distance in km, or null when neither API answers; the
  /// quote then goes out without `distance_in_km` and the server derives it.
  Future<double?> _resolveRoute(RidePlace from, RidePlace to) async {
    // Selecting Parcel re-quotes, and the route for an unchanged pickup/drop
    // pair is the same route — don't pay for it twice.
    final key = '${from.latitude},${from.longitude}'
        '>${to.latitude},${to.longitude}';
    if (key == _routeCacheKey && routePoints.isNotEmpty) {
      return tripDistanceKm.value > 0 ? tripDistanceKm.value : null;
    }

    final origin = PointLatLng(from.latitude, from.longitude);
    final destination = PointLatLng(to.latitude, to.longitude);
    final polylinePoints = PolylinePoints(apiKey: googleMapKey);

    try {
      final response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: origin,
          destination: destination,
          travelMode: TravelMode.driving,
          // The whole point of this call: pick the road geometry by current
          // traffic, not by raw distance.
          routingPreference: RoutingPreference.trafficAware,
          // Detail matters here — OVERVIEW simplifies enough that the line
          // visibly cuts corners at junctions on a city-scale zoom.
          polylineQuality: PolylineQuality.highQuality,
        ),
      );
      final route =
          response.routes.isNotEmpty ? response.routes.first : null;
      final points = route?.polylinePoints;
      if (route != null && points != null && points.length >= 2) {
        _publishRoute(key, points);
        // Traffic-aware ETA — `duration` includes traffic, `staticDuration`
        // does not. Surfaced so the vehicle rows can show a real drop time.
        tripDurationMinutes.value = route.durationMinutes?.round() ?? 0;
        final km = route.distanceKm ?? _sumKm(points);
        return km > 0 ? km : null;
      }
    } catch (_) {
      // Routes API not enabled on the key, quota, or offline — fall through.
    }

    try {
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: origin,
          destination: destination,
          mode: TravelMode.driving,
        ),
      );
      final points = result.points;
      if (points.length < 2) return null;
      _publishRoute(key, points);
      // Legacy Directions gives no traffic duration.
      tripDurationMinutes.value = 0;
      final km = _sumKm(points);
      return km > 0 ? km : null;
    } catch (_) {
      return null;
    }
  }

  void _publishRoute(String key, List<PointLatLng> points) {
    _routeCacheKey = key;
    routePoints.assignAll(
      points.map((p) => LatLng(p.latitude, p.longitude)),
    );
  }

  /// Road distance summed along the polyline — only needed on the legacy path,
  /// where the response carries no measured distance.
  static double _sumKm(List<PointLatLng> points) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += calculateDistanceKm(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Postal code of the pickup, used by the server's serviceability check.
  /// Null on failure — the quote still goes out without it.
  Future<String?> _pincodeFor(RidePlace place) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        place.latitude,
        place.longitude,
      );
      final code = placemarks.isNotEmpty ? placemarks.first.postalCode : null;
      return (code != null && code.isNotEmpty) ? code : null;
    } catch (_) {
      return null;
    }
  }

  /// Read the dynamic-fare response into vehicle options.
  ///
  /// The live shape is a **map keyed by vehicle type**, not a list:
  ///
  /// ```jsonc
  /// {
  ///   "pricingSignals": { "tripDistanceKm": 2, "durationMin": 4, … },
  ///   "riders": {
  ///     "twoWheelerRider": {
  ///       "users": [ { riderId, name, distance: "2.77 km", … } ],
  ///       "fare": 50,
  ///       "fareBreakdown": { baseFare, distanceCharge, multipliers, … }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// A vehicle type with an empty `users` list is a type nobody is online for —
  /// it is dropped, because the fare is real but nothing can serve it.
  ///
  /// Also accepts a plain list of `{vehicleType, fare}` objects: the guide
  /// never pinned the envelope down, and the list form is what the stub was
  /// written against.
  ///
  /// There is no `quoteId` in this API (guide §1) — [RideVehicleOption.quoteId]
  /// is synthesised from the vehicle type purely so the UI can identify the
  /// selected row. Booking sends `{vehicleType, fare}`, not a quote token.
  List<RideVehicleOption> _parseDynamicFare(dynamic data) {
    // Trip-level signals sit beside the riders, not inside them. Shape B is a
    // bare `{}` with neither key, so absence is expected, not an error.
    if (data is Map) {
      final signals = data['pricingSignals'];
      if (signals is Map) {
        // The server measured the same trip — prefer its numbers over the ones
        // derived from the Directions polyline.
        final km = _toNum(signals['tripDistanceKm'])?.toDouble();
        if (km != null && km > 0) tripDistanceKm.value = km;
        final min = _toNum(signals['durationMin'])?.toInt();
        if (min != null && min > 0) tripDurationMinutes.value = min;
        supplyCount.value = _toNum(signals['supplyCount'])?.toInt() ?? 0;
        weather.value = signals['weather']?.toString() ?? 'clear';
      } else {
        // Don't leave the previous trip's ETA and supply on screen.
        tripDurationMinutes.value = 0;
        supplyCount.value = 0;
        weather.value = 'clear';
      }
    }

    final raw = data is Map
        ? (data['riders'] ?? data['vehicles'] ?? data['options'] ?? data['data'])
        : data;

    // Normalise both envelopes to (vehicleType, payload) pairs.
    final Iterable<MapEntry<String, Map>> entries;
    if (raw is Map) {
      entries = raw.entries
          .where((e) => e.value is Map)
          .map((e) => MapEntry(e.key.toString(), e.value as Map));
    } else if (raw is List) {
      entries = raw.whereType<Map>().map((m) => MapEntry(
            (m['vehicleType'] ?? m['type'] ?? '').toString(),
            m,
          ));
    } else {
      return const [];
    }

    final options = <RideVehicleOption>[];
    for (final entry in entries) {
      final vehicleType = entry.key;
      if (vehicleType.isEmpty) continue;
      final group = entry.value;

      // `fare` is 0 when pricing could not compute — `fareBreakdown.reason` is
      // then `no-fare-policy` / `no-matching-rate`. A ₹0 row is not bookable,
      // so it is dropped rather than offered.
      final fare =
          _toNum(group['fare'] ?? group['dynamicFare'] ?? group['price']);
      if (fare == null || fare <= 0) continue;

      // Only types with ≥1 rider are supposed to appear at all, but an empty
      // `users` list would be a bookable-looking row nobody can accept.
      final users = group['users'];
      final riderCount = users is List ? users.length : null;
      if (riderCount == 0) continue;

      options.add(RideVehicleOption(
        // The backend enum IS the code — no translation layer.
        code: vehicleType,
        name: (group['label'] ?? group['name'] ?? _nameForVehicleType(vehicleType))
            .toString(),
        // Nothing else useful to say under the name, and how far the nearest
        // rider is answers the question the user actually has.
        description: group['description']?.toString() ??
            () {
              final away = _nearestRiderDistance(group);
              return away == null ? null : '$away away';
            }(),
        fare: fare.toDouble(),
        seats: _toNum(group['seats'])?.toInt(),
        // `riders[type].users[].distance` is rider→pickup as a STRING
        // ("3.10 km"), not a duration, so it cannot fill a pickup ETA. Left
        // null rather than inventing minutes from a distance.
        pickupEtaMinutes:
            _toNum(group['etaMinutes'] ?? group['pickupEtaMinutes'])?.toInt(),
        // No per-vehicle drop ETA in the response; `pricingSignals.durationMin`
        // is the driving ETA for the trip and applies to every type, so the row
        // can render a real drop time instead of nothing.
        dropEtaMinutes: _toNum(group['dropEtaMinutes'])?.toInt() ??
            (tripDurationMinutes.value > 0
                ? tripDurationMinutes.value
                : null),
        // Not a server token — see the doc comment above.
        quoteId: vehicleType,
      ));
    }
    return options;
  }

  /// Nearest rider distance for a vehicle type, e.g. `"3.10 km"`. The API sends
  /// this as a formatted STRING per rider, not a number — kept verbatim rather
  /// than parsed, since it is only ever displayed.
  static String? _nearestRiderDistance(Map group) {
    final users = group['users'];
    if (users is! List || users.isEmpty) return null;
    final first = users.first;
    if (first is! Map) return null;
    final distance = first['distance']?.toString();
    return (distance != null && distance.isNotEmpty) ? distance : null;
  }

  static num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  /// Body of a response, whether or not it is wrapped in a `data` envelope.
  ///
  /// `ResponseModel.data` is hard-coded to `body['data']`, which suits the
  /// services that wrap their payloads. `rider-service/fare/*` does not — the
  /// create call returns the order object at the top level:
  ///
  /// ```jsonc
  /// { "orderId": "ORD-1784621292731", "status": "pending", … }
  /// ```
  ///
  /// so `.data` is null and a perfectly successful 201 parses as a failure.
  /// Every read of a response in this flow goes through here.
  static dynamic _payload(ResponseModel response) =>
      response.data ?? response.response?.data;

  /// Pick a vehicle row.
  ///
  /// A plain selection — no re-quote. `orderFor` is a property of the TRIP
  /// (parcel run vs. city ride), chosen on the Explore rail, not of the
  /// vehicle: the same `twoWheelerRider` serves both, and every type in the
  /// response was already priced under the current `orderFor`.
  void selectVehicle(RideVehicleOption option) {
    selectedVehicle.value = option;
    preselectedVehicleCode.value = option.code;
  }

  void setPaymentMode(String mode) => paymentMode.value = mode;

  // --------------------------------------------------------------- booking

  /// Create the booking and start the searching poll.
  ///
  /// Returns `true` when the booking was accepted by the server, so the caller
  /// can navigate; the searching screen then owns the rest of the lifecycle.
  Future<bool> bookRide() async {
    final option = selectedVehicle.value;
    final from = pickup.value;
    final to = drop.value;
    if (option == null || from == null || to == null) return false;

    isBooking.value = true;
    terminalStatus.value = null;
    fareBoost.value = 0;
    try {
      final response = await _repo.createBroadcastOrder(
        pickupLocation: _locationBody(from),
        dropLocation: _locationBody(to),
        fare: option.fare,
        // CASH → postpaid, ONLINE → prepaid (guide §2).
        modeOfPayment: paymentMode.value == 'CASH' ? 'postpaid' : 'prepaid',
        // Same value the quote used — see [orderFor].
        orderFor: orderFor.value,
        // `code` is already the backend enum.
        vehicleType: option.code,
      );
      if (!response.isSuccess) return false;

      final data = _payload(response);
      if (data is! Map) return false;
      final order = data['order'] is Map ? data['order'] as Map : data;
      final rideId =
          (order['orderId'] ?? order['_id'] ?? order['id'] ?? '').toString();
      if (rideId.isEmpty) return false;

      // Build the local booking from what we already know rather than from the
      // create response — the order payload is the backend's own shape, and
      // the screens only need pickup/drop/fare/vehicle until the first status
      // poll lands (which is authoritative from then on).
      //
      // The OTP is the exception: `pickupOTP` is already in the create response
      // and the status poll only re-sends it later, so taking it here means the
      // tracking card is never briefly missing it.
      final otp = order['pickupOTP']?.toString();
      activeBooking.value = RideBooking(
        rideId: rideId,
        status: RideStatus.fromString(order['status']?.toString()),
        pickup: from,
        drop: to,
        vehicleCode: option.code,
        vehicleName: option.name,
        fare: option.fare,
        paymentMode: paymentMode.value,
        startOtp: (otp != null && otp.isNotEmpty) ? otp : null,
      );
      _startSearching();
      return true;
    } catch (_) {
      return false;
    } finally {
      isBooking.value = false;
    }
  }

  /// `{address, latitude, longitude}` — the shape `fare/orders` expects for
  /// both ends of the trip.
  Map<String, dynamic> _locationBody(RidePlace place) => {
        'address': place.fullAddress,
        'latitude': place.latitude,
        'longitude': place.longitude,
      };

  /// Begin the searching phase: a fast local progress animation plus the
  /// slower status poll that actually decides when a captain is attached.
  void _startSearching() {
    searchProgress.value = 0;
    broadcastWave.value = 0;
    broadcastTotalWaves.value = 0;
    broadcastRidersNotified.value = 0;

    // Real-time race updates (instant winner / exhaustion / wave progress).
    _subscribeBroadcastSocket();

    // Creep toward 90% over ~45s. It never completes on its own — only a real
    // assignment finishes the bar, so the UI can't imply success falsely.
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (searchProgress.value < 0.9) {
        searchProgress.value = math.min(0.9, searchProgress.value + 0.01);
      }
    });

    startStatusPolling();
  }

  /// Poll the booking status every [interval]. Safe to call repeatedly.
  void startStatusPolling({
    Duration interval = const Duration(seconds: 3),
  }) {
    final rideId = activeBooking.value?.rideId;
    if (rideId == null || rideId.isEmpty) return;
    _statusTimer?.cancel();
    _pollStatus();
    _statusTimer = Timer.periodic(interval, (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    final booking = activeBooking.value;
    if (booking == null || _statusRequestInFlight) return;
    _statusRequestInFlight = true;
    try {
      final response = await _repo.getBookingStatus(booking.rideId);
      if (!response.isSuccess) return; // transient — the next tick retries
      final data = _payload(response);
      if (data is! Map) return;

      // `{ status, pickupOTP?, metadata }` (guide §3). Merge onto the booking
      // we already hold rather than reconstructing it — the status payload
      // carries no pickup/drop/fare.
      final status = RideStatus.fromString(data['status']?.toString());
      final metadata = data['metadata'];
      final otp = (data['pickupOTP'] ?? data['pickupOtp'])?.toString();

      var updated = booking.copyWith(
        status: status,
        startOtp: (otp != null && otp.isNotEmpty) ? otp : null,
      );

      // metadata.assignedRider names the winning rider; hydrate the captain
      // card from whatever detail rides along with it.
      if (metadata is Map) {
        final rider = metadata['assignedRider'];
        if (rider is Map) {
          updated = updated.copyWith(captain: RideCaptain.fromJson(rider));
        } else if (rider != null && updated.captain == null) {
          // Bare id — show the card with what we have; the location poll
          // fills in position, and the socket payload (if wired) fills names.
          updated = updated.copyWith(
            captain: RideCaptain(id: rider.toString(), name: ''),
          );
        }
      }

      _applyStatus(updated);
    } catch (_) {
      // Swallow: keep the timer alive so a blip doesn't kill tracking.
    } finally {
      _statusRequestInFlight = false;
    }
  }

  // ----------------------------------------------------- broadcast socket

  /// Register the broadcast race listeners once. Idempotent — [ChatSocketService]
  /// de-dupes by event name and replays on reconnect. Handlers ignore any event
  /// whose orderId isn't our current booking, so they self-cancel after reset.
  void _subscribeBroadcastSocket() {
    if (_broadcastSocketBound) return;
    _broadcastSocketBound = true;
    final socket = ChatSocketService();

    // Wave fan-out progress → "Searching · wave 1/3 · 5 riders".
    socket.listenEvent('ride:broadcast:searching', (data) {
      final m = _asMap(data);
      if (!_isForActiveOrder(m)) return;
      broadcastWave.value = _asInt(m['wave']) ?? broadcastWave.value;
      broadcastTotalWaves.value =
          _asInt(m['totalWaves']) ?? broadcastTotalWaves.value;
      broadcastRidersNotified.value =
          _asInt(m['ridersNotified']) ?? broadcastRidersNotified.value;
    });

    // Full winner payload — finish the bar and hydrate the captain immediately,
    // without waiting for the next 3s status poll.
    socket.listenEvent('ride:queue:accepted', (data) {
      final m = _asMap(data);
      if (!_isForActiveOrder(m)) return;
      _applyBroadcastWinner(m);
    });

    // Lighter "someone won" signal — nudge the status poll to hydrate the
    // captain right away.
    socket.listenEvent('ride:broadcast:accepted', (data) {
      final m = _asMap(data);
      if (!_isForActiveOrder(m)) return;
      final b = activeBooking.value;
      if (b != null && !b.status.hasCaptain) {
        startStatusPolling(interval: const Duration(seconds: 2));
      }
    });

    // No rider took it — end the search instantly instead of waiting for the
    // status poll to report `rejected`.
    socket.listenEvent('ride:broadcast:exhausted', (data) {
      final m = _asMap(data);
      if (!_isForActiveOrder(m)) return;
      final b = activeBooking.value;
      if (b != null && b.status.isActive) {
        _applyStatus(b.copyWith(status: RideStatus.noRidersFound));
      }
    });
  }

  /// Apply the `ride:queue:accepted` winner payload: flip to assigned and build
  /// the captain card from `riderInfo`, keeping whatever the status poll may
  /// already have hydrated.
  void _applyBroadcastWinner(Map data) {
    final booking = activeBooking.value;
    if (booking == null) return;
    final info = _asMap(data['riderInfo']);
    final otp = (data['pickupOTP'] ?? data['pickupOtp'])?.toString();

    RideCaptain? captain = booking.captain;
    final riderId = (info['id'] ?? info['riderId'] ?? data['riderId'])?.toString();
    if (riderId != null && riderId.isNotEmpty) {
      captain = RideCaptain(
        id: riderId,
        name: (info['name'] ?? captain?.name ?? '').toString(),
        phone: (info['contact'] ?? info['phone'] ?? captain?.phone)?.toString(),
        photoUrl:
            (info['profileImage'] ?? info['photoUrl'] ?? captain?.photoUrl)
                ?.toString(),
        vehicleNumber: captain?.vehicleNumber,
        vehicleModel: captain?.vehicleModel,
        rating: captain?.rating,
        latitude: captain?.latitude,
        longitude: captain?.longitude,
      );
    }

    _applyStatus(booking.copyWith(
      status: booking.status.hasCaptain ? booking.status : RideStatus.assigned,
      captain: captain,
      startOtp: (otp != null && otp.isNotEmpty) ? otp : null,
    ));
  }

  bool _isForActiveOrder(Map data) {
    final id = (data['orderId'] ?? data['rideId'] ?? data['id'])?.toString();
    final active = activeBooking.value?.rideId;
    return id != null && active != null && id == active;
  }

  Map _asMap(dynamic v) => v is Map ? v : const {};
  int? _asInt(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  void _applyStatus(RideBooking updated) {
    activeBooking.value = updated;

    if (updated.status.hasCaptain) {
      // Captain attached — finish the bar and switch to captain polling.
      searchProgress.value = 1;
      _progressTimer?.cancel();
      _progressTimer = null;
      _startCaptainPolling();
    }

    if (!updated.status.isActive) {
      terminalStatus.value = updated.status;
      _stopAllPolling();
    }
  }

  /// Captain position refreshes faster than booking status — 5s keeps the
  /// map marker smooth without hammering the status endpoint.
  void _startCaptainPolling({
    Duration interval = const Duration(seconds: 5),
  }) {
    if (_captainTimer != null) return; // already running
    _captainTimer = Timer.periodic(interval, (_) => _pollCaptainLocation());
  }

  Future<void> _pollCaptainLocation() async {
    final booking = activeBooking.value;
    if (booking == null || !booking.status.hasCaptain) return;
    try {
      final response = await _repo.getCaptainLocation(booking.rideId);
      if (!response.isSuccess) return;
      final payload = _payload(response);
      if (payload is! Map) return;

      // `{ rideActive, rider: { location, ... } }` (guide §1). A false
      // rideActive means the ride ended between status polls — let the status
      // poll own the terminal transition, just stop chasing the marker.
      if (payload['rideActive'] == false) {
        _captainTimer?.cancel();
        _captainTimer = null;
        return;
      }

      final rider = payload['rider'];
      if (rider is! Map) return; // transient GPS gap — keep the last marker

      // Coordinates arrive either flat or nested under `location`, which may
      // itself be GeoJSON `[lng, lat]`.
      double? lat = _toNum(rider['latitude'])?.toDouble();
      double? lng = _toNum(rider['longitude'])?.toDouble();
      final location = rider['location'];
      if (location is Map) {
        lat ??= _toNum(location['latitude'])?.toDouble();
        lng ??= _toNum(location['longitude'])?.toDouble();
        final coords = location['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng ??= _toNum(coords[0])?.toDouble();
          lat ??= _toNum(coords[1])?.toDouble();
        }
      }

      final existing = booking.captain;
      activeBooking.value = booking.copyWith(
        captain: RideCaptain(
          id: (rider['riderId'] ?? rider['id'] ?? existing?.id ?? '').toString(),
          name: (rider['name'] ?? existing?.name ?? '').toString(),
          phone: rider['phone']?.toString() ?? existing?.phone,
          photoUrl: rider['photoUrl']?.toString() ??
              rider['profileImage']?.toString() ??
              existing?.photoUrl,
          vehicleNumber:
              rider['vehicleNumber']?.toString() ?? existing?.vehicleNumber,
          vehicleModel:
              rider['vehicleModel']?.toString() ?? existing?.vehicleModel,
          rating: _toNum(rider['rating'])?.toDouble() ?? existing?.rating,
          latitude: lat ?? existing?.latitude,
          longitude: lng ?? existing?.longitude,
        ),
        pickupEtaMinutes: _toNum(payload['etaMinutes'] ??
                payload['pickupEtaMinutes'] ??
                rider['etaMinutes'])
            ?.toInt(),
        captainDistanceMeters: _toNum(payload['distanceMeters'])?.toInt() ??
            // Server may send km; the UI wants metres.
            (_toNum(payload['distanceToPickupKm']) != null
                ? (_toNum(payload['distanceToPickupKm'])! * 1000).round()
                : null),
      );
    } catch (_) {
      // Keep the last known marker; the next tick retries.
    }
  }

  /// Bump the offered fare to attract a captain.
  ///
  /// NOT IMPLEMENTED server-side for broadcast dispatch (guide §6), so this is
  /// inert and the chips are hidden behind [kFareRaiseEnabled]. Raising the
  /// fare locally would charge the customer more for nothing — the backend
  /// would never see it and riders would never be re-rung at the new price.
  Future<void> raiseFare(double amount) async {
    if (!kFareRaiseEnabled) return;
    final booking = activeBooking.value;
    if (booking == null) return;
    fareBoost.value += amount;
    activeBooking.value = booking.copyWith(fare: booking.fare + amount);
  }

  // -------------------------------------------------------------- cancelling

  /// Cancellation reasons.
  ///
  /// There is no reasons endpoint (guide §6) — the built-in list is the
  /// source. Kept async so a server-driven list can drop in later without
  /// touching the sheet.
  Future<void> loadCancelReasons() async {
    if (cancelReasons.isNotEmpty) return; // cached for the session
    cancelReasons.assignAll(_defaultCancelReasons());
  }

  /// Cancel the booking. Returns `true` on success so the caller can pop back
  /// to the home screen.
  Future<bool> cancelRide({
    required String reasonCode,
    String? comment,
  }) async {
    final booking = activeBooking.value;
    if (booking == null) return false;
    isCancelling.value = true;
    try {
      final response = await _repo.cancelBooking(
        orderId: booking.rideId,
        reasonCode: reasonCode,
        comment: comment,
      );
      if (!response.isSuccess) return false;
      _stopAllPolling();
      activeBooking.value = booking.copyWith(status: RideStatus.cancelled);
      terminalStatus.value = RideStatus.cancelled;
      return true;
    } catch (_) {
      return false;
    } finally {
      isCancelling.value = false;
    }
  }

  /// Wipe trip state so the home screen starts clean after a completed or
  /// cancelled ride. Pickup and the user's location are kept — they are still
  /// valid for the next booking.
  void resetTrip() {
    _stopAllPolling();
    drop.value = null;
    stops.clear();
    vehicleOptions.clear();
    selectedVehicle.value = null;
    preselectedVehicleCode.value = null;
    orderFor.value = _defaultOrderFor;
    quoteError.value = null;
    tripDistanceKm.value = 0;
    tripDurationMinutes.value = 0;
    supplyCount.value = 0;
    weather.value = 'clear';
    routePoints.clear();
    _routeCacheKey = null;
    activeBooking.value = null;
    terminalStatus.value = null;
    searchProgress.value = 0;
    broadcastWave.value = 0;
    broadcastTotalWaves.value = 0;
    broadcastRidersNotified.value = 0;
    fareBoost.value = 0;
    paymentMode.value = 'CASH';
  }

  /// The shipped cancellation reasons. Broadcast dispatch has no reasons
  /// endpoint (guide §6), so this list IS the source — not a fallback.
  List<RideCancelReason> _defaultCancelReasons() => const [
        RideCancelReason(
          code: 'TAKING_LONGER',
          label: 'Taking longer than expected',
        ),
        RideCancelReason(
          code: 'BETTER_PRICE',
          label: 'Found better price elsewhere',
        ),
        RideCancelReason(code: 'CHANGE_OF_PLANS', label: 'Change of plans'),
        RideCancelReason(
          code: 'CAPTAIN_NOT_MOVING',
          label: 'Captain not moving towards pickup',
        ),
        RideCancelReason(code: 'OTHERS', label: 'Others'),
      ];
}
