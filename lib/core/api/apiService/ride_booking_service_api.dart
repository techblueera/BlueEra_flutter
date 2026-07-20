/// All `ride-booking-service/*` endpoint constants for the Rapido-style
/// customer ride-booking flow (`lib/features/ride_booking/`).
///
/// Deliberately separate from [RiderServiceApi]: that mixin serves the older
/// `rider-service/fare/*` parcel + transport booking screens under
/// `Discover/view/book_your_transport/`, which this flow does not touch or
/// reuse. Keeping the two namespaces apart means either flow can change
/// without regressing the other.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
/// Contract: docs/backend/RIDE_BOOKING_FRONTEND_INTEGRATION.md
mixin RideBookingServiceApi {
  static const String _root = 'ride-booking-service';

  /// GET — recent destinations for the signed-in user (Rapido home list).
  final String rideRecentPlaces = '$_root/places/recent';

  /// GET `?q=` — place autocomplete proxied through our backend so the
  /// Google key stays server-side and results can be biased to the user's
  /// city. POST — persist a chosen place into the recents list.
  final String ridePlaceSearch = '$_root/places/search';

  /// GET `?lat=&lng=` — snapped pickup points near a coordinate, for the
  /// "Select a nearby point for easier pickup" map screen.
  final String ridePickupPoints = '$_root/places/pickup-points';

  /// GET/POST/DELETE — saved (hearted) places shown on the home + trip sheet.
  final String rideSavedPlaces = '$_root/places/saved';
  String rideSavedPlaceById(String id) => '$_root/places/saved/$id';

  /// POST — fare quote for a pickup/drop pair. Returns one entry per
  /// available vehicle category (Bike / Auto / Cab Economy / …) with fare,
  /// ETA and a short-lived `quoteId` that must be echoed back on booking.
  final String rideFareQuote = '$_root/quotes';

  /// POST — create the booking from a chosen `quoteId`. Response carries the
  /// `rideId` the whole tracking phase is keyed on.
  final String rideBookings = '$_root/bookings';

  /// GET — poll the booking while it is searching/assigned. Single source of
  /// truth for the searching → assigned → tracking screen transitions.
  String rideBookingStatus(String rideId) => '$_root/bookings/$rideId/status';

  /// GET — assigned captain's live position, polled ~every 5s once assigned.
  String rideCaptainLocation(String rideId) =>
      '$_root/bookings/$rideId/captain-location';

  /// POST — raise the offered fare while still searching ("+₹10 / +₹20 …").
  String rideRaiseFare(String rideId) => '$_root/bookings/$rideId/raise-fare';

  /// GET — cancellation reasons, server-driven so ops can reword them
  /// without an app release. Includes any cancellation fee copy.
  final String rideCancelReasons = '$_root/cancel-reasons';

  /// POST — cancel the booking with a chosen reason code.
  String rideCancelBooking(String rideId) => '$_root/bookings/$rideId/cancel';
}
