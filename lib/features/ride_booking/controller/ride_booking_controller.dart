import 'dart:async';
import 'dart:math' as math;

import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Drives the whole Rapido-style ride-booking flow: home → destination search
/// → confirm pickup → vehicle select → searching → tracking → cancel.
///
/// Deliberately standalone — it shares no state with [DiscoverController] and
/// the older `book_your_transport/` screens, so neither flow can regress the
/// other.
///
/// ### Stub mode
/// [_useStub] keeps the flow fully demoable before the backend ships. Every
/// network method is `if (_useStub) return _stubX()`, so flipping the single
/// flag to `false` switches the whole flow onto the real API with no other
/// edit. See docs/backend/RIDE_BOOKING_FRONTEND_INTEGRATION.md.
class RideBookingController extends GetxController {
  /// Flip to `false` once the backend is live.
  static const bool _useStub = true;

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
  Timer? _searchDebounce;

  // --------------------------------------------------------------- quoting

  final RxList<RideVehicleOption> vehicleOptions = <RideVehicleOption>[].obs;
  final Rxn<RideVehicleOption> selectedVehicle = Rxn<RideVehicleOption>();
  final isQuoting = false.obs;

  /// `CASH` | `ONLINE`. Shown on the fare bar and the trip-details sheet.
  final paymentMode = 'CASH'.obs;

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

  // ------------------------------------------------------------- lifecycle

  @override
  void onInit() {
    super.onInit();
    _bootstrapLocation();
    loadRecentPlaces();
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

  Future<void> loadRecentPlaces() async {
    isLoadingRecents.value = true;
    try {
      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 250));
        recentPlaces.assignAll(_stubRecents());
        return;
      }
      final response = await _repo.getRecentPlaces();
      if (!response.isSuccess) return;
      recentPlaces.assignAll(_parsePlaces(response.data));
    } catch (_) {
      // Recents are a convenience — an empty list is an acceptable outcome.
    } finally {
      isLoadingRecents.value = false;
    }
  }

  /// Heart / un-heart a place from the home list or the trip sheet.
  Future<void> toggleSavedPlace(RidePlace place) async {
    final nowSaved = !place.isSaved;

    // Optimistic: the heart flips immediately, the request settles after.
    _replaceInList(recentPlaces, place, place.copyWith(isSaved: nowSaved));
    _replaceInList(searchResults, place, place.copyWith(isSaved: nowSaved));

    if (_useStub) return;
    try {
      if (nowSaved) {
        await _repo.savePlace(place.toJson());
      } else if (place.id != null) {
        await _repo.deleteSavedPlace(place.id!);
      }
    } catch (_) {
      // Roll back so the heart never lies about persisted state.
      _replaceInList(recentPlaces, place, place.copyWith(isSaved: !nowSaved));
      _replaceInList(searchResults, place, place.copyWith(isSaved: !nowSaved));
    }
  }

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

  Future<void> _runSearch(String query) async {
    try {
      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 300));
        searchResults.assignAll(_stubSearch(query));
        return;
      }
      final response = await _repo.searchPlaces(
        query: query,
        lat: currentLat.value == 0 ? null : currentLat.value,
        lng: currentLng.value == 0 ? null : currentLng.value,
      );
      if (!response.isSuccess) {
        searchResults.clear();
        return;
      }
      searchResults.assignAll(_parsePlaces(response.data));
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchResults.clear();
    isSearching.value = false;
  }

  // -------------------------------------------------------------- trip ends

  void setDrop(RidePlace place) {
    drop.value = place;
    if (!_useStub) _recordRecentSilently(place);
  }

  /// Fire-and-forget recents write — a failure here must never block or delay
  /// navigation into the booking flow.
  Future<void> _recordRecentSilently(RidePlace place) async {
    try {
      await _repo.recordRecentPlace(place.toJson());
    } catch (_) {
      // Intentionally ignored.
    }
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

  /// Fetch fares for every vehicle category. Pre-selects the first option so
  /// the Book button is immediately actionable, matching Rapido.
  Future<void> fetchQuotes() async {
    final from = pickup.value;
    final to = drop.value;
    if (from == null || to == null) return;
    if (!from.hasCoordinates || !to.hasCoordinates) return;

    isQuoting.value = true;
    vehicleOptions.clear();
    selectedVehicle.value = null;
    try {
      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        vehicleOptions.assignAll(_stubQuotes(from, to));
      } else {
        final response = await _repo.getFareQuote(
          pickup: from.toJson(),
          drop: to.toJson(),
          stops: stops.map((s) => s.toJson()).toList(),
        );
        if (!response.isSuccess) return;
        final data = response.data;
        final list = data is Map ? data['options'] : data;
        if (list is List) {
          vehicleOptions.assignAll(
            list.whereType<Map>().map(RideVehicleOption.fromJson),
          );
        }
      }
      if (vehicleOptions.isNotEmpty) {
        selectedVehicle.value = vehicleOptions.first;
      }
    } catch (_) {
      vehicleOptions.clear();
    } finally {
      isQuoting.value = false;
    }
  }

  void selectVehicle(RideVehicleOption option) =>
      selectedVehicle.value = option;

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
      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 700));
        activeBooking.value = RideBooking(
          rideId: 'stub-ride-1',
          status: RideStatus.searching,
          pickup: from,
          drop: to,
          vehicleCode: option.code,
          vehicleName: option.name,
          fare: option.fare,
          paymentMode: paymentMode.value,
        );
      } else {
        final response = await _repo.createBooking(
          quoteId: option.quoteId,
          vehicleCode: option.code,
          paymentMode: paymentMode.value,
        );
        if (!response.isSuccess) return false;
        final data = response.data;
        if (data is! Map) return false;
        activeBooking.value = RideBooking.fromJson(data);
      }
      _startSearching();
      return true;
    } catch (_) {
      return false;
    } finally {
      isBooking.value = false;
    }
  }

  /// Begin the searching phase: a fast local progress animation plus the
  /// slower status poll that actually decides when a captain is attached.
  void _startSearching() {
    searchProgress.value = 0;

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
      if (_useStub) {
        _stubAdvanceStatus();
        return;
      }
      final response = await _repo.getBookingStatus(booking.rideId);
      if (!response.isSuccess) return; // transient — the next tick retries
      final data = response.data;
      if (data is! Map) return;
      _applyStatus(RideBooking.fromJson(data));
    } catch (_) {
      // Swallow: keep the timer alive so a blip doesn't kill tracking.
    } finally {
      _statusRequestInFlight = false;
    }
  }

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
      if (_useStub) {
        _stubDriftCaptain();
        return;
      }
      final response = await _repo.getCaptainLocation(booking.rideId);
      if (!response.isSuccess) return;
      final data = response.data;
      if (data is! Map) return;

      final existing = booking.captain;
      if (existing == null) return;
      activeBooking.value = booking.copyWith(
        captain: RideCaptain(
          id: existing.id,
          name: existing.name,
          phone: existing.phone,
          photoUrl: existing.photoUrl,
          vehicleNumber: existing.vehicleNumber,
          vehicleModel: existing.vehicleModel,
          rating: existing.rating,
          latitude: (data['latitude'] as num?)?.toDouble() ?? existing.latitude,
          longitude:
              (data['longitude'] as num?)?.toDouble() ?? existing.longitude,
        ),
        pickupEtaMinutes: (data['pickupEtaMinutes'] as num?)?.toInt(),
        captainDistanceMeters: (data['distanceMeters'] as num?)?.toInt(),
      );
    } catch (_) {
      // Keep the last known marker; the next tick retries.
    }
  }

  /// Bump the offered fare to attract a captain. Optimistic so the chip feels
  /// instant; the next status poll reconciles the authoritative fare.
  Future<void> raiseFare(double amount) async {
    final booking = activeBooking.value;
    if (booking == null) return;
    fareBoost.value += amount;
    activeBooking.value = booking.copyWith(fare: booking.fare + amount);
    if (_useStub) return;
    try {
      await _repo.raiseFare(rideId: booking.rideId, amount: amount);
    } catch (_) {
      fareBoost.value -= amount;
      activeBooking.value = booking;
    }
  }

  // -------------------------------------------------------------- cancelling

  Future<void> loadCancelReasons() async {
    if (cancelReasons.isNotEmpty) return; // cached for the session
    try {
      if (_useStub) {
        cancelReasons.assignAll(_stubCancelReasons());
        return;
      }
      final response = await _repo.getCancelReasons();
      if (!response.isSuccess) return;
      final data = response.data;
      if (data is List) {
        cancelReasons.assignAll(
          data.whereType<Map>().map(RideCancelReason.fromJson),
        );
      }
    } catch (_) {
      // Fall back to the built-in list so cancelling is never blocked by a
      // failed reasons fetch.
      cancelReasons.assignAll(_stubCancelReasons());
    }
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
      if (!_useStub) {
        final response = await _repo.cancelBooking(
          rideId: booking.rideId,
          reasonCode: reasonCode,
          comment: comment,
        );
        if (!response.isSuccess) return false;
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
      }
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
    activeBooking.value = null;
    terminalStatus.value = null;
    searchProgress.value = 0;
    fareBoost.value = 0;
    paymentMode.value = 'CASH';
  }

  // ---------------------------------------------------------------- parsing

  List<RidePlace> _parsePlaces(dynamic data) {
    final list = data is Map ? (data['places'] ?? data['results']) : data;
    if (list is! List) return const [];
    return list.whereType<Map>().map(RidePlace.fromJson).toList();
  }

  // ------------------------------------------------------------------ stubs
  // Everything below exists only while [_useStub] is true. Delete this block
  // once the backend is live and the flag is flipped.

  List<RidePlace> _stubRecents() => const [
        RidePlace(
          title: 'Rani Kamlapati Railway Station',
          subtitle: 'Habib Ganj, Bhopal, Madhya Pradesh, India',
          latitude: 23.2333,
          longitude: 77.4344,
        ),
        RidePlace(
          title: 'Railway Colony',
          subtitle: 'Bhopal, Madhya Pradesh 462010, India',
          latitude: 23.2599,
          longitude: 77.4126,
        ),
        RidePlace(
          title: 'New Market',
          subtitle: 'STT Nagar, TT Nagar, Bhopal, Madhya Pradesh, India',
          latitude: 23.2337,
          longitude: 77.4009,
        ),
      ];

  List<RidePlace> _stubSearch(String query) {
    final pool = [
      ..._stubRecents(),
      const RidePlace(
        title: 'DB City Mall',
        subtitle: 'Arera Hills, Bhopal, Madhya Pradesh 462011, India',
        latitude: 23.2340,
        longitude: 77.4340,
      ),
      const RidePlace(
        title: 'AIIMS Bhopal',
        subtitle: 'Saket Nagar, Bhopal, Madhya Pradesh 462020, India',
        latitude: 23.2076,
        longitude: 77.4645,
      ),
      const RidePlace(
        title: 'Bhopal Junction',
        subtitle: 'Railway Station Rd, Bhopal, Madhya Pradesh, India',
        latitude: 23.2685,
        longitude: 77.4126,
      ),
    ];
    final lower = query.toLowerCase();
    final matches = pool
        .where((p) =>
            p.title.toLowerCase().contains(lower) ||
            p.subtitle.toLowerCase().contains(lower))
        .toList();
    // Always return something so the UI can be exercised with any query.
    return matches.isEmpty ? pool.take(4).toList() : matches;
  }

  List<RideVehicleOption> _stubQuotes(RidePlace from, RidePlace to) {
    final km = _haversineKm(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    double fare(double perKm, double base) =>
        (base + perKm * km).roundToDouble();
    final rideMinutes = math.max(5, (km * 3).round());
    return [
      RideVehicleOption(
        code: 'BIKE',
        name: 'Bike',
        description: 'Quick Bike rides',
        badge: 'FASTEST',
        fare: fare(6, 15),
        seats: 1,
        dropEtaMinutes: rideMinutes,
        pickupEtaMinutes: 2,
        quoteId: 'stub-quote-bike',
      ),
      RideVehicleOption(
        code: 'CAB_ECONOMY',
        name: 'Cab Economy',
        fare: fare(14, 35),
        seats: 4,
        dropEtaMinutes: rideMinutes + 3,
        pickupEtaMinutes: 5,
        quoteId: 'stub-quote-cab-eco',
      ),
      RideVehicleOption(
        code: 'AUTO',
        name: 'Auto',
        fare: fare(10, 25),
        seats: 3,
        dropEtaMinutes: rideMinutes + 2,
        pickupEtaMinutes: 4,
        quoteId: 'stub-quote-auto',
      ),
      RideVehicleOption(
        code: 'CAB_DAILY',
        name: 'Cab Daily',
        fare: fare(14, 35),
        seats: 4,
        dropEtaMinutes: rideMinutes + 3,
        pickupEtaMinutes: 6,
        quoteId: 'stub-quote-cab-daily',
      ),
      RideVehicleOption(
        code: 'CAB_PREMIUM',
        name: 'Cab Premium',
        fare: fare(18, 45),
        seats: 4,
        dropEtaMinutes: rideMinutes + 3,
        pickupEtaMinutes: 7,
        quoteId: 'stub-quote-cab-premium',
      ),
    ];
  }

  /// Stub lifecycle: searching for ~9s, then a captain is assigned.
  int _stubTicks = 0;
  void _stubAdvanceStatus() {
    final booking = activeBooking.value;
    if (booking == null) return;
    _stubTicks++;
    if (_stubTicks < 3 || booking.status.hasCaptain) return;
    _stubTicks = 0;
    _applyStatus(booking.copyWith(
      status: RideStatus.assigned,
      pickupEtaMinutes: 2,
      captainDistanceMeters: 775,
      captain: RideCaptain(
        id: 'stub-captain',
        name: 'Akash Singh',
        phone: '9876543210',
        vehicleNumber: 'MP04NW2444',
        vehicleModel: 'FZ',
        rating: 4.8,
        // Start the marker slightly off the pickup so it visibly approaches.
        latitude: booking.pickup.latitude - 0.006,
        longitude: booking.pickup.longitude - 0.006,
      ),
    ));
  }

  /// Nudge the stub captain toward the pickup each poll, so the marker moves.
  void _stubDriftCaptain() {
    final booking = activeBooking.value;
    final captain = booking?.captain;
    if (booking == null || captain == null) return;
    final lat = captain.latitude ?? booking.pickup.latitude;
    final lng = captain.longitude ?? booking.pickup.longitude;
    activeBooking.value = booking.copyWith(
      captain: RideCaptain(
        id: captain.id,
        name: captain.name,
        phone: captain.phone,
        photoUrl: captain.photoUrl,
        vehicleNumber: captain.vehicleNumber,
        vehicleModel: captain.vehicleModel,
        rating: captain.rating,
        latitude: lat + (booking.pickup.latitude - lat) * 0.18,
        longitude: lng + (booking.pickup.longitude - lng) * 0.18,
      ),
      captainDistanceMeters:
          math.max(50, ((booking.captainDistanceMeters ?? 775) * 0.8).round()),
    );
  }

  List<RideCancelReason> _stubCancelReasons() => const [
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

  /// Great-circle distance in km — used for stub fares and the trip summary.
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    double toRad(double deg) => deg * math.pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
