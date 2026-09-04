import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/core/services/ongoing_ride_signal.dart';
import 'package:BlueEra/core/services/ongoing_ride_store.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
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

  /// What the flow books when the customer never picked a vehicle — they came
  /// in through the search field rather than a service tile.
  ///
  /// The bike, because it is the cheapest ride and the one the catalogue leads
  /// with. Something has to be selected from the first screen on: the quote and
  /// the create call both carry a `vehicleType`, and the destination search now
  /// names the vehicle it is searching for.
  static const String kDefaultVehicleType = 'twoWheelerRider';

  /// Catalogue label for a `vehicleType`, falling back to the compiled-in name
  /// while the catalogue is still loading (or for a code it doesn't carry).
  String vehicleLabelFor(String code) {
    for (final type in vehicleTypes) {
      if (type.code == code) return type.label;
    }
    return _nameForVehicleType(code);
  }

  // ------------------------------------------------------ vehicle catalogue

  /// The backend's vehicle catalogue, from `GET riders/onboarding/vehicle-enums`.
  ///
  /// The home screen's service tiles are built from this rather than from a
  /// list compiled into the app: the enum is the backend's to change, and a
  /// hardcoded copy means a vehicle added server-side is invisible here while
  /// one removed there is still bookable — and the create call would carry a
  /// `vehicleType` the server rejects.
  ///
  /// [kVehicleTypeNames] stays as the offline fallback and the source of
  /// display names when a payload omits `slug_value`.
  final RxList<RideVehicleType> vehicleTypes = <RideVehicleType>[].obs;
  final isLoadingVehicleTypes = false.obs;

  /// Everything that carries goods rather than people. Used to split the flat
  /// catalogue into the home screen's Passenger / Parcel sections — the
  /// backend returns one list and the grouping is a product decision.
  static const Set<String> kGoodsVehicleTypes = {
    'pickupGoods',
    'miniTruckGoods',
    'largeTruckGoods',
    'goods3Wheeler',
    'goods4Wheeler',
  };

  /// Fetch the catalogue once per app run. [force] re-fetches (pull to refresh).
  Future<void> fetchVehicleTypes({bool force = false}) async {
    if (isLoadingVehicleTypes.value) return;
    if (!force && vehicleTypes.isNotEmpty) return;

    isLoadingVehicleTypes.value = true;
    try {
      final response = await _repo.getVehicleEnums();
      final parsed = _parseVehicleTypes(response);
      // An empty/failed response must not blank the tiles — a customer with a
      // flaky connection still gets a bookable screen from the known enum.
      vehicleTypes.assignAll(parsed.isNotEmpty ? parsed : _fallbackVehicleTypes);
    } catch (_) {
      if (vehicleTypes.isEmpty) vehicleTypes.assignAll(_fallbackVehicleTypes);
    } finally {
      isLoadingVehicleTypes.value = false;
    }
  }

  /// `{ vehicleType: [{slug_id, slug_value}] }`, tolerating the older shape
  /// where the list held plain strings, and a body wrapped in `data`.
  List<RideVehicleType> _parseVehicleTypes(ResponseModel response) {
    if (!response.isSuccess) return const [];
    final body = response.response?.data;
    final map = body is Map ? body : null;
    if (map == null) return const [];
    final inner = map['data'] is Map ? map['data'] as Map : map;
    final raw = inner['vehicleType'];
    if (raw is! List) return const [];

    final out = <RideVehicleType>[];
    for (final entry in raw) {
      String code;
      String label;
      if (entry is Map) {
        code = (entry['slug_id'] ?? entry['id'] ?? '').toString();
        label = (entry['slug_value'] ?? entry['label'] ?? '').toString();
      } else {
        code = entry?.toString() ?? '';
        label = '';
      }
      if (code.isEmpty) continue;
      out.add(RideVehicleType(
        code: code,
        label: label.isNotEmpty ? label : _nameForVehicleType(code),
      ));
    }
    return out;
  }

  static List<RideVehicleType> get _fallbackVehicleTypes => [
        for (final entry in kVehicleTypeNames.entries)
          RideVehicleType(code: entry.key, label: entry.value),
      ];

  // ----------------------------------------------------------- live riders

  /// Riders currently out there near the customer, drawn on the home map.
  ///
  /// Presence, not supply: the flow still books by broadcast, so an empty list
  /// is not a promise that nothing is available and a full one is not a promise
  /// that anybody accepts. Nothing downstream reads it.
  final RxList<RideLiveRider> liveRiders = <RideLiveRider>[].obs;
  final isLoadingLiveRiders = false.obs;

  /// Monotonic id for the in-flight live-rider lookup. Tapping Bike then Cab
  /// fires two, and they don't come back in order — without this, the slower
  /// bike response repaints bikes over the cabs the user is now looking at.
  int _liveRiderSeq = 0;

  /// The COARSE category `riders/live-in-radius` filters by, for a booking's
  /// `vehicleType` enum.
  ///
  /// Two vocabularies: a booking carries the exact enum (`carSedan`), the map
  /// query takes the family (`car`) — the sample response filters on
  /// `vehicleType=rider` and comes back holding a `twoWheelerRider`. Anything
  /// unmapped falls back to the bike category, which is the one every city has
  /// riders in.
  static const Map<String, String> _liveRiderCategories = {
    'twoWheelerRider': 'rider',
    'eRickshaw': 'auto',
    'autoTempo': 'auto',
    'goods3Wheeler': 'auto',
    'carMini': 'car',
    'carSedan': 'car',
    'suvCar': 'car',
    'miniBus': 'car',
    'goods4Wheeler': 'truck',
    'pickupGoods': 'truck',
    'miniTruckGoods': 'truck',
    'largeTruckGoods': 'truck',
  };

  static String liveRiderCategoryFor(String? vehicleType) =>
      _liveRiderCategories[vehicleType] ?? 'rider';

  /// How far out to look for live riders, per trip type.
  ///
  /// A city ride or a parcel is served from the neighbourhood — widening the
  /// circle there just draws vehicles that would never take the job. An out-
  /// station trip is a different market: the customer is leaving town, drivers
  /// who do those runs are spread thinner, and a 5 km circle would routinely
  /// come back empty on a service that is perfectly available.
  static const Map<String, int> _liveRiderRadiusKm = {
    'InCity': 5,
    'Parcel': 5,
    'OutStation': 10,
  };

  static int liveRiderRadiusFor(String orderFor) =>
      _liveRiderRadiusKm[orderFor] ?? 5;

  /// Load the riders live around the customer for [vehicleType].
  ///
  /// Silent on failure — this decorates the map, and a red banner over a map
  /// the user can still book from would be noise. A failed or empty lookup
  /// clears the markers rather than leaving the last vehicle family sitting
  /// there under a different heading.
  /// [radiusKm] defaults to the radius for the trip type currently set — see
  /// [liveRiderRadiusFor]. Pass one only to override that.
  ///
  /// [atLat]/[atLng] override the point to look around. Only the confirm-pickup
  /// screen passes them: there the pin is being DRAGGED and nothing is committed
  /// yet, so `pickup` still holds wherever the customer started and the vehicles
  /// on screen would be the ones around the old point.
  Future<void> fetchLiveRiders({
    String? vehicleType,
    int? radiusKm,
    int limit = 20,
    double? atLat,
    double? atLng,
  }) async {
    // Around the PICKUP, not the device: once the customer has moved the pin
    // (or come back to change it), the vehicles that matter are the ones near
    // where they will be collected. Falls back to the device fix on the home
    // screen, before a pickup has been confirmed.
    final place = pickup.value;
    final hasPickup = place != null && place.hasCoordinates;
    final explicit = atLat != null && atLng != null;
    final lat = explicit ? atLat : (hasPickup ? place.latitude : currentLat.value);
    final lng = explicit ? atLng : (hasPickup ? place.longitude : currentLng.value);
    // No fix yet — the caller retries once the device position lands.
    if (lat == 0 && lng == 0) return;

    final seq = ++_liveRiderSeq;
    isLoadingLiveRiders.value = true;
    try {
      final response = await _repo.getLiveRidersInRadius(
        lat: lat,
        lng: lng,
        vehicleType: liveRiderCategoryFor(
          vehicleType ?? preselectedVehicleCode.value,
        ),
        radiusKm: radiusKm ?? liveRiderRadiusFor(orderFor.value),
        limit: limit,
      );
      if (seq != _liveRiderSeq) return; // a newer tap owns the map now
      liveRiders.assignAll(_parseLiveRiders(response));
    } catch (_) {
      if (seq == _liveRiderSeq) liveRiders.clear();
    } finally {
      if (seq == _liveRiderSeq) isLoadingLiveRiders.value = false;
    }
  }

  List<RideLiveRider> _parseLiveRiders(ResponseModel response) {
    if (!response.isSuccess) return const [];
    final body = _payload(response);
    final map = body is Map ? body : null;
    final raw = map?['riders'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw.whereType<Map>())
        if (RideLiveRider.fromJson(entry) case final rider
            when rider.hasCoordinates)
          rider,
    ];
  }

  /// The catalogue entries for [codes], in the order given — the section
  /// decides the order it wants to show, the catalogue decides what exists.
  /// Unknown codes are dropped, so a type the backend has retired disappears
  /// from the screen without a release.
  ///
  /// Two sources, unioned, and the fare catalog wins on EXISTENCE:
  ///
  ///  * [vehicleOptions] — the `fare/riders/dynamic` answer for the current
  ///    trip. `allVehicleTypes=true` makes it list every type the server will
  ///    price, so if a fare came back for a code, that code is bookable, full
  ///    stop. This is the fresher answer and it is per-trip.
  ///  * [vehicleTypes] — `riders/onboarding/vehicle-enums`. Still the source of
  ///    DISPLAY NAMES (`slug_value`), and still the only catalogue there is for
  ///    a section quoting a different `orderFor` than the one in flight, or
  ///    before any trip exists.
  ///
  /// The union is what matters: a priced type missing from the enum used to
  /// vanish from the grid — the enum call failing, or lagging a server-side
  /// addition, silently cost the user a vehicle the backend was happy to quote.
  /// Such a type is now shown, named from [kVehicleTypeNames].
  List<RideVehicleType> vehicleTypesFor(List<String> codes) {
    final byCode = {for (final v in vehicleTypes) v.code: v};
    final priced = {for (final option in vehicleOptions) option.code};
    return [
      for (final code in codes)
        if (byCode[code] case final known?)
          known
        else if (priced.contains(code))
          RideVehicleType(code: code, label: _nameForVehicleType(code)),
    ];
  }

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
  /// pickup before they change it. `0,0` means "no fix yet", not the Gulf of
  /// Guinea: every reader gates on it.
  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;

  /// A device fix is being resolved right now. Lets a screen say "Locating…"
  /// instead of presenting a fallback centre as though it were the answer.
  final isLocating = false.obs;

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

  /// Mirrors every [activeBooking] change into [OngoingRideStore].
  Worker? _persistWorker;

  @override
  void onInit() {
    super.onInit();
    _bootstrapLocation();
    // Saved first, so the hearts are already correct when recents render.
    loadSavedPlaces().then((_) => loadRecentPlaces());
    // One writer for the whole lifecycle. Every path that moves the booking —
    // create, status poll, socket winner, fare raise, cancel, reset — goes
    // through `activeBooking`, so persisting from here is the only way the
    // snapshot can't silently fall behind one of them.
    _persistWorker = ever<RideBooking?>(activeBooking, _persistBooking);
  }

  @override
  void onClose() {
    _persistWorker?.dispose();
    _searchDebounce?.cancel();
    _stopAllPolling();
    super.onClose();
  }

  // ------------------------------------------------- ongoing-ride snapshot

  /// Write (or drop) the ongoing-ride snapshot behind the Discover card.
  ///
  /// A finished ride is cleared rather than stored: the card is for a ride in
  /// flight, and a completed/cancelled snapshot would resurrect a dead ride on
  /// the next launch. The completed *receipt* row on the chip is deliberately
  /// session-only for the same reason — it is a prompt to rate what just
  /// happened, not something to greet the user with days later.
  void _persistBooking(RideBooking? booking) {
    // Wake any ongoing-ride card that was built before this controller existed
    // — on a cold start the Discover chip has no ride controller to watch, so
    // this signal is how a restored or freshly-booked ride reaches it.
    bumpOngoingRideRevision();

    if (booking == null || !booking.status.isActive) {
      OngoingRideStore.clear();
      return;
    }
    OngoingRideStore.save({
      OngoingRideStore.flowKey: OngoingRideStore.flowRideBooking,
      ...booking.toStoreJson(),
    });
  }

  /// Rebuild an in-flight ride from the snapshot after an app relaunch, and
  /// resume the polls that keep the card live.
  ///
  /// Returns false when there is nothing to restore — a ride already tracked
  /// this session, no snapshot, or a snapshot from the legacy transport flow
  /// (which [OngoingRideRestorer] handles instead). The restored booking is
  /// optimistic: `startStatusPolling` confirms it against the server within a
  /// tick or two and `_applyStatus` clears it if the ride has since ended.
  Future<bool> restoreOngoingRide() async {
    if (activeBooking.value != null) return false;

    final snap = await OngoingRideStore.read();
    if (snap == null) return false;
    if (snap[OngoingRideStore.flowKey] != OngoingRideStore.flowRideBooking) {
      return false;
    }

    final booking = RideBooking.fromStoreJson(snap);
    if (booking == null || !booking.status.isActive) {
      await OngoingRideStore.clear();
      return false;
    }

    activeBooking.value = booking;
    // Both polls are needed: status decides when the ride ends, the captain
    // poll is what makes the restored card's distance/ETA move again.
    startStatusPolling();
    if (booking.status.hasCaptain) _startCaptainPolling();
    return true;
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
    if (isLocating.value) return;
    isLocating.value = true;
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
    } finally {
      isLocating.value = false;
    }
  }

  /// Resolve the device position if we still don't have one.
  ///
  /// [_bootstrapLocation] runs ONCE, from `onInit`. This controller outlives
  /// every screen in the flow, so a fix that failed then — permission not yet
  /// granted, location services off, a timeout on a cold GPS — never got a
  /// second chance, and [currentLat]/[currentLng] stayed at 0 for the rest of
  /// the session. Screens that must open on the user call this on entry.
  ///
  /// Cheap when a fix is already in hand: it returns without touching the
  /// device. Concurrent calls collapse onto the one in flight.
  Future<void> ensureCurrentLocation() async {
    // BOTH, not either. `||` meant a half-written fix (latitude assigned,
    // longitude still 0 — they are set on consecutive lines, so a listener can
    // observe the gap) counted as "we already have a location", and this never
    // retried. The caller was then stuck on a coordinate that does not exist.
    if (currentLat.value != 0 && currentLng.value != 0) return;
    await _bootstrapLocation();
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

  /// Two recents closer together than this are the same destination as far as
  /// a customer is concerned, so the newer one replaces the older rather than
  /// stacking beside it.
  ///
  /// Exact-coordinate de-duping was enough while every recent came from the
  /// search (the same place searched twice returns the same coordinate to the
  /// decimal). A map pin never lands on the same pixel twice, so without a
  /// radius the list fills with the same street over and over.
  static const double _recentDedupeMetres = 80;

  /// The coordinate-pair subtitle [RideReverseGeocodeService] falls back to when
  /// the geocoder gives it nothing — e.g. `26.26841, 73.00594`. Recognising it
  /// is how an unnamed point is kept OUT of Recent: a row a customer cannot
  /// read is a row they cannot choose.
  static final RegExp _coordinateSubtitle =
      RegExp(r'^-?\d+\.\d+,\s*-?\d+\.\d+$');

  /// Whether [place] is worth showing in a list of past destinations.
  bool _isRecentWorthy(RidePlace place) {
    if (!place.hasCoordinates) return false;
    if (place.title.trim().isEmpty) return false;
    // A failed reverse geocode — "Selected drop point" over a lat/lng pair.
    // Honest on the map strip, useless as a history row.
    if (_coordinateSubtitle.hasMatch(place.subtitle.trim())) return false;
    return true;
  }

  /// Push [place] to the front of the on-device recents, de-duped within
  /// [_recentDedupeMetres] and capped at [_maxRecentPlaces].
  Future<void> _rememberRecentPlace(RidePlace place) async {
    if (!_isRecentWorthy(place)) return;
    try {
      final next = <RidePlace>[
        place,
        ...recentPlaces.where((p) =>
            calculateDistanceKm(
              p.latitude,
              p.longitude,
              place.latitude,
              place.longitude,
            ) *
                1000 >=
            _recentDedupeMetres),
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

  /// Shortest query worth paying Google for.
  ///
  /// Was 2. A two-character query returns results nobody taps — it is not a
  /// search yet, it is the user still typing — so every one of them was a
  /// billed request that could not succeed.
  ///
  /// Public because the search screen decides between "recents" and "results"
  /// on the same threshold; if the two disagree, a 2-character query shows an
  /// empty results list instead of recents.
  static const int minSearchChars = 3;

  /// Quiet period after the last keystroke before we search.
  ///
  /// Raised from 350ms: each burst that survives the debounce is a billed
  /// request, and at 350ms an average typist produces several per address. The
  /// extra quarter-second is barely perceptible and removes most of them.
  static const Duration _kSearchDebounce = Duration(milliseconds: 600);

  /// Debounced autocomplete, so a fast typist costs one request instead of one
  /// per character.
  void onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    searchQuery.value = trimmed;
    if (trimmed.length < minSearchChars) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    _searchDebounce = Timer(_kSearchDebounce, () => _runSearch(trimmed));
  }

  /// Google Places autocomplete, via the app's existing [PlaceRepo].
  ///
  /// Broadcast dispatch has no places service of its own (guide §6) — it only
  /// needs pickup/drop lat-lng, and the source is our choice. This reuses the
  /// same path the older booking screens already use.
  ///
  /// Autocomplete returns place_ids WITHOUT coordinates, and this used to
  /// resolve every one of them (in parallel, `Future.wait`) so the list could be
  /// published with lat/lng attached. That bought up to 5 billed Place Details
  /// per keystroke burst for a list the rider takes one row from — the single
  /// most expensive pattern in the app. Rows are now published coordinate-less
  /// and resolved on tap by [resolveSearchResult].
  /// See docs/GOOGLE_MAPS_COST_GUIDE.md §3.1.
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
      searchResults.assignAll(
        PlacePrediction.fromList(predictionsJson)
            .map(_toUnresolvedPlace)
            .whereType<RidePlace>(),
      );
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Fill in the coordinates for the row the rider actually picked.
  ///
  /// Returns the same [place] when it already has coordinates (a recent/
  /// favourite, or a row resolved earlier this session — [PlaceRepo.resolvePlace]
  /// caches by `place_id`), a resolved copy when the lookup succeeds, and null
  /// when it fails. A place we cannot locate cannot be a pickup or drop, so
  /// callers must handle null rather than booking against 0,0.
  Future<RidePlace?> resolveSearchResult(RidePlace place) async {
    if (place.hasCoordinates) return place;
    final resolved = await PlaceRepo().resolvePlace(place.id);
    if (resolved == null) return null;
    return place.copyWith(
      latitude: resolved.lat,
      longitude: resolved.lng,
    );
  }

  /// Turn one autocomplete prediction into a [RidePlace] with NO coordinates
  /// yet — see [resolveSearchResult].
  RidePlace? _toUnresolvedPlace(PlacePrediction prediction) {
    final placeId = prediction.placeId ?? '';
    if (placeId.isEmpty) return null;
    // Google's `description` is "Name, Area, City, State, Country" — split
    // on the first comma so the UI's two-line title/subtitle stays honest
    // instead of repeating the whole string twice.
    final description = prediction.description ?? '';
    final comma = description.indexOf(',');
    return RidePlace(
      id: placeId,
      title: comma > 0 ? description.substring(0, comma) : description,
      subtitle: comma > 0 ? description.substring(comma + 1).trim() : '',
      // Filled in on tap — see [resolveSearchResult].
      latitude: 0,
      longitude: 0,
    );
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  // -------------------------------------------------------------- trip ends

  /// Set the destination.
  ///
  /// [remember] controls whether it goes straight into Recent. It is true for a
  /// place the user NAMED — picked out of the search, or tapped in Recent /
  /// Saved — because choosing it by name is already an act of recognition, and
  /// the row it produces is one they'll recognise again.
  ///
  /// The map pin passes false. A pin is dragged around while hunting, and every
  /// stop is a candidate, not a decision — writing each one straight to Recent
  /// fills the list with near-identical rows off the same street that the user
  /// never travelled to. A pinned drop earns its place in Recent by being
  /// BOOKED; see the call in [bookRide].
  void setDrop(RidePlace place, {bool remember = true}) {
    drop.value = place;
    if (remember) _rememberRecentPlace(place);
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
  ///
  /// A null [vehicleType] means "no tile was tapped" (the search field), which
  /// settles on [kDefaultVehicleType] rather than staying unset: from here on
  /// the flow always has a vehicle to name and to pre-select.
  void setTripType({String? vehicleType, String orderFor = _defaultOrderFor}) {
    preselectedVehicleCode.value = vehicleType ?? kDefaultVehicleType;
    this.orderFor.value = orderFor;
  }

  /// The pickup→drop pair, as a key. Every fare on screen is priced for THIS
  /// route; change either end and all of them are wrong.
  String get _tripRouteKey {
    final from = pickup.value;
    final to = drop.value;
    return '${from?.latitude},${from?.longitude}'
        '>${to?.latitude},${to?.longitude}';
  }

  /// What makes a quote unique: the two ends and the trip type. Same signature
  /// = the same question for the server, so the answer can be shared.
  String get _quoteSignature => 'quote|$_tripRouteKey|${orderFor.value}';


  /// Skips a refetch when the catalog on screen is already this trip's, and
  /// recent. Short TTL because these are *dynamic* fares — surge and supply
  /// move — but long enough to cover a back-and-re-enter on the picker.
  final FetchCache _quoteCache = FetchCache(ttl: const Duration(minutes: 2));

  /// The quote currently on the wire, and what it is asking for. Confirming a
  /// pickup fires a quote and then immediately opens the picker, which asks for
  /// the same one; joining the in-flight future is what keeps that a SINGLE
  /// request instead of two identical ones racing to overwrite each other.
  Future<void>? _quotesInFlight;
  String? _quotesInFlightSignature;

  /// Quote only if the answer isn't already in hand.
  ///
  /// For screens that need the catalog on entry but may well have been handed
  /// it by whoever navigated to them. [fetchQuotes] stays the forced version —
  /// retry buttons and trip-type changes must always hit the server.
  Future<void> fetchQuotesIfNeeded() {
    if (_quoteCache.isFresh(_quoteSignature,
        hasData: vehicleOptions.isNotEmpty)) {
      // The catalog is reusable, the SELECTION may not be: whoever fetched it
      // resolved the preselection against whatever was chosen then, and the
      // caller has usually just set its own.
      _applyPreselection();
      return Future<void>.value();
    }
    return fetchQuotes();
  }

  /// Fetch fares for every vehicle category.
  ///
  /// Pre-selects the Explore choice when the quote contains it, else the first
  /// option, so the Book button is immediately actionable.
  ///
  /// Concurrent calls for the same trip share one request — see
  /// [_quotesInFlight].
  Future<void> fetchQuotes() {
    final signature = _quoteSignature;
    final inFlight = _quotesInFlight;
    if (inFlight != null && _quotesInFlightSignature == signature) {
      return inFlight;
    }
    late final Future<void> run;
    run = _fetchQuotes(signature).whenComplete(() {
      // Only if it is still OURS — a differently-keyed quote may have started
      // and taken the slot over while this one was on the wire.
      if (identical(_quotesInFlight, run)) {
        _quotesInFlight = null;
        _quotesInFlightSignature = null;
      }
    });
    _quotesInFlight = run;
    _quotesInFlightSignature = signature;
    return run;
  }

  Future<void> _fetchQuotes(String signature) async {
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
        // CATALOG mode: every vehicle type in one answer, with per-type
        // availability — goods and out-station classes included, whatever
        // `orderFor` was sent. That is what lets ONE call price the whole
        // sheet; see [RideBookingRepo.getDynamicFare].
        allVehicleTypes: true,
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
      // Catalog mode never answers with a bare `{}`, so an empty list here is
      // a shape we didn't expect rather than "no riders in this city" — the
      // rows carry their own `ridersAvailable` for that now.
      if (vehicleOptions.isEmpty) return;

      // Only a catalog we actually populated is worth reusing.
      _quoteCache.mark(signature);
      _applyPreselection();
    } catch (_) {
      vehicleOptions.clear();
      quoteError.value = 'Could not fetch fares right now.';
    } finally {
      isQuoting.value = false;
    }
  }

  /// Light up the row for [preselectedVehicleCode], else the first one, so the
  /// Book button is immediately actionable.
  ///
  /// Reads that code rather than leaving an existing selection alone because it
  /// is the authoritative record of the customer's choice — [selectVehicle]
  /// writes it on every tap — so re-deriving from it both honours a pick made
  /// earlier and picks up a default set moments ago.
  void _applyPreselection() {
    if (vehicleOptions.isEmpty) return;
    final preferred = preselectedVehicleCode.value;
    selectedVehicle.value = vehicleOptions.firstWhere(
      (o) => o.code == preferred,
      orElse: () => vehicleOptions.first,
    );
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
  /// The live shape is a **map keyed by vehicle type**, not a list, and in
  /// catalog mode (`allVehicleTypes=true`, which is how this flow always calls
  /// it) the priced list is `fares` — every type — while `riders` holds only
  /// the ones somebody is driving right now:
  ///
  /// ```jsonc
  /// {
  ///   "pricingSignals": { "tripDistanceKm": 2, "durationMin": 4, … },
  ///   "fares": {
  ///     "twoWheelerRider": { "fare": 40, "fareBreakdown": {…},
  ///                          "ridersAvailable": true, "riderCount": 1,
  ///                          "nearestRiderKm": 2.6 },
  ///     "autoTempo":       { "fare": 40, …, "ridersAvailable": false,
  ///                          "riderCount": 0, "nearestRiderKm": null },
  ///     // …every other type
  ///   },
  ///   "riders": {
  ///     "twoWheelerRider": {
  ///       "users": [ { riderId, name, distance: "2.77 km", … } ],
  ///       "fare": 40,
  ///       "fareBreakdown": { baseFare, distanceCharge, multipliers, … }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// A type nobody is online for is KEPT, carrying `ridersAvailable: false` —
  /// the tile renders its fare and a "None nearby" line. Dropping it would take
  /// the vehicle off the grid entirely, which reads as "we don't do that" when
  /// the truth is "not right now". Only a ₹0 fare (pricing could not compute)
  /// removes a row, since it isn't bookable at all.
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

    // CATALOG mode (`allVehicleTypes=true`) answers with `fares`: EVERY vehicle
    // type, each carrying its own `ridersAvailable` / `riderCount` /
    // `nearestRiderKm`. `riders` sits beside it and holds only the types
    // somebody is currently driving — reading THAT as the row source is why the
    // grid priced the bike and left a dash on all eleven other tiles.
    final raw = data is Map
        ? (data['fares'] ??
            data['riders'] ??
            data['vehicles'] ??
            data['options'] ??
            data['data'])
        : data;

    // Supply, keyed by vehicle type. In catalog mode the availability numbers
    // are already on the fare row; this block is what the older `riders`-only
    // shape carried them in, and it is the only place the formatted
    // rider→pickup distance string lives either way.
    final supply = (data is Map && data['riders'] is Map)
        ? data['riders'] as Map
        : const {};

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

      // The matching supply entry, when there is one. Absent for every type
      // nobody is driving — which in catalog mode is most of them, and is not a
      // reason to drop the row.
      final onlineGroup = supply[vehicleType] is Map
          ? supply[vehicleType] as Map
          : null;

      // Availability comes off the fare row in catalog mode; for the older
      // shape it is however many riders were listed. A row with nobody on it
      // is kept and marked unavailable rather than dropped — the tile says
      // "None nearby", which is a truer answer than the vehicle vanishing.
      final users = group['users'] ?? onlineGroup?['users'];
      final riderCount = _toNum(group['riderCount'])?.toInt() ??
          (users is List ? users.length : null);
      final ridersAvailable = group['ridersAvailable'] is bool
          ? group['ridersAvailable'] as bool
          : (riderCount == null ? null : riderCount > 0);
      final nearestRiderKm = _toNum(group['nearestRiderKm'])?.toDouble() ??
          _toNum(onlineGroup?['nearestRiderKm'])?.toDouble();

      // Distance the SERVER priced this row over, straight off its own
      // breakdown — the trip-level `pricingSignals.tripDistanceKm` is the
      // fallback for a payload that omits the breakdown.
      final breakdown = group['fareBreakdown'];
      final distanceKm = _toNum(
            breakdown is Map ? breakdown['distanceKm'] : null,
          )?.toDouble() ??
          (tripDistanceKm.value > 0 ? tripDistanceKm.value : null);

      options.add(RideVehicleOption(
        // The backend enum IS the code — no translation layer.
        code: vehicleType,
        name: (group['label'] ?? group['name'] ?? _nameForVehicleType(vehicleType))
            .toString(),
        // Nothing else useful to say under the name, and how far the nearest
        // rider is answers the question the user actually has.
        description: group['description']?.toString() ??
            _nearestRiderText(nearestRiderKm, onlineGroup),
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
        distanceKm: distanceKm,
        // Not a server token — see the doc comment above.
        quoteId: vehicleType,
        ridersAvailable: ridersAvailable,
        riderCount: riderCount,
        nearestRiderKm: nearestRiderKm,
        // Per-trip-type prices, so the grid can show the SAME vehicle at its
        // real price under each service it is listed beneath.
        serviceFares: RideVehicleOption.parseServiceFares(group['serviceFares']),
      ));
    }
    return options;
  }

  /// "2.6 km away" for the nearest rider of a type, or null when there isn't
  /// one. Prefers catalog mode's numeric `nearestRiderKm`; falls back to the
  /// formatted string the `riders` block carries per rider.
  static String? _nearestRiderText(double? nearestKm, Map? onlineGroup) {
    if (nearestKm != null && nearestKm > 0) {
      return '${nearestKm.toStringAsFixed(1)} km away';
    }
    final formatted =
        onlineGroup == null ? null : _nearestRiderDistance(onlineGroup);
    return formatted == null ? null : '$formatted away';
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

      // The destination is now somewhere the customer actually went, so it has
      // earned a place in Recent. This is the ONLY thing that gets a map-pinned
      // drop into the list — [setDrop] deliberately doesn't, so a pin dragged
      // around while hunting leaves nothing behind. Idempotent for a drop that
      // came from the search and is already at the front: _rememberRecentPlace
      // de-dupes by proximity, so it just refreshes its position.
      _rememberRecentPlace(to);

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
      // Broadcast accepted and the order has an id — this is a real ride
      // request, not an abandoned quote. `fare` is a num so it lands as a GA4
      // metric rather than a string dimension.
      AnalyticsService.I.log(
        'ride_requested',
        AnalyticsService.params({
          'order_id': rideId,
          'vehicle_type': option.code,
          'payment_mode': paymentMode.value,
          'fare': option.fare,
        }),
      );
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
        // Only set on a cancelled order. Carried through so the terminal
        // message can say WHO cancelled — a captain-cancelled ride otherwise
        // reads to the customer like their own booking silently failed.
        cancelledBy: data['cancelledBy']?.toString(),
        cancellationReason: data['cancellationReason']?.toString(),
        cancelledAt: DateTime.tryParse(data['cancelledAt']?.toString() ?? ''),
      );

      // metadata.assignedRider names the winning rider; hydrate the captain
      // card from whatever detail rides along with it.
      if (metadata is Map) {
        final rider = metadata['assignedRider'];
        if (rider is Map) {
          // Merge, never replace: this poll runs every 3s and may carry less
          // than the socket winner payload already gave us.
          final incoming = RideCaptain.fromJson(rider);
          updated = updated.copyWith(
            captain: booking.captain?.merge(incoming) ?? incoming,
          );
        } else if (rider != null && updated.captain == null) {
          // Bare id — show the card with what we have; the location poll
          // fills in position, and the socket payload fills names.
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
      // `riderInfo` carries the full rider shape (name, photo, contact and a
      // nested vehicleInformation) — parse it with the model rather than
      // hand-picking a few keys, which is how the plate and model used to go
      // missing on the card.
      final incoming = RideCaptain.fromJson({'riderId': riderId, ...info});
      captain = captain?.merge(incoming) ?? incoming;
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

  /// Stop chasing the captain marker while another screen owns live tracking.
  ///
  /// `TrackRiderLiveLocationPage` polls the SAME
  /// `fare/orders/{orderId}/rider-location` endpoint on its own timer, so
  /// leaving ours running would double the request rate against one endpoint
  /// for two maps, only one of which is visible. Status polling continues —
  /// that is what detects completion.
  void pauseCaptainPolling() {
    _captainTimer?.cancel();
    _captainTimer = null;
  }

  /// Resume after that screen closes, if the ride is still live.
  void resumeCaptainPolling() {
    final booking = activeBooking.value;
    if (booking == null || !booking.status.hasCaptain) return;
    if (!booking.status.isActive) return;
    _startCaptainPolling();
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

      // `fromJson` already unpacks flat / nested / GeoJSON coordinates and the
      // nested vehicleInformation; `merge` keeps the name, plate and photo the
      // socket winner gave us when this thinner location payload omits them.
      final incoming = RideCaptain.fromJson(rider);
      final existing = booking.captain;

      activeBooking.value = booking.copyWith(
        captain: existing?.merge(incoming) ?? incoming,
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
      // Stamp who cancelled locally — the response body isn't parsed here, and
      // without this a self-cancel is indistinguishable from a captain's.
      activeBooking.value = booking.copyWith(
        status: RideStatus.cancelled,
        cancelledBy: 'customer',
        cancellationReason: reasonCode,
      );
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
    _quoteCache.invalidate();
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
