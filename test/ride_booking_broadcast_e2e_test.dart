/// End-to-end coverage of the Rapido-style BROADCAST ride, walked as one
/// story across both halves of the flow:
///
///   customer creates → server rings riders in waves → a rider WINS the race →
///   losers are dismissed silently → pickup OTP → trip → completion / cancel.
///
/// Contract: docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md
///
/// Every payload below is the shape the guide documents, including the two
/// that have bitten this flow before: the create response arrives WITHOUT a
/// `data` envelope, and the rider's push carries the real `ORD-…` id at the
/// root of a JSON-STRING `payload` while `metadata.Order_id` holds a different
/// (Mongo) id entirely.
///
/// Scope: the pure decision points both sides share — status mapping, captain
/// hydration, and the notification-id plumbing that decides whether a losing
/// rider's ring can be cancelled. The transport itself (`RideBookingRepo`,
/// FCM delivery) is not exercised; `RideBookingController` constructs its repo
/// internally, so its network paths are not reachable from a unit test.
library;

import 'dart:convert';

import 'package:BlueEra/core/services/ride_ring_notification.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one id that has to survive intact from the customer's create call all
/// the way to the ring the losing rider's phone has to cancel.
const String kOrderId = 'ORD-1784638670140';

/// The Mongo `_id` the same push also carries. A different id space — every
/// `fare/orders/{orderId}/*` route 404s on it.
const String kMongoId = '6a5f6cce225ffe42a97b3ff2';

const RidePlace _pickup = RidePlace(
  title: 'Home',
  subtitle: 'MP Nagar, Bhopal',
  latitude: 23.23,
  longitude: 77.43,
);

const RidePlace _drop = RidePlace(
  title: 'Office',
  subtitle: 'Arera Colony, Bhopal',
  latitude: 23.20,
  longitude: 77.46,
);

void main() {
  // ─────────────────────────────────────────────────────────── customer side

  group('customer · quote', () {
    test('dynamic-fare row prices a vehicle by its backend vehicleType', () {
      // `GET fare/riders/dynamic` names the category `vehicleType`, not `code`,
      // and serialises the fare as a string on some rows.
      final option = RideVehicleOption.fromJson({
        'vehicleType': 'twoWheelerRider',
        'fare': '85',
        'pickupEtaMinutes': 4,
      });

      // The code IS the backend enum — this flow has no second vocabulary to
      // translate through, which is what used to send an unaccepted
      // `vehicleType` on create.
      expect(option.code, 'twoWheelerRider');
      expect(option.fare, 85);
      expect(option.pickupEtaMinutes, 4);
    });
  });

  group('customer · create', () {
    test('201 with no data envelope still yields a booking', () {
      // `rider-service/fare/*` returns the order at the TOP level. Anything
      // reading only `response.data` parses this success as a failure.
      final created = {
        'orderId': kOrderId,
        'status': 'pending',
        'pickupOTP': '4821',
      };

      final booking = _bookingFromCreateResponse(created);

      expect(booking.rideId, kOrderId);
      // `pending` = waves still ringing, nobody has won.
      expect(booking.status, RideStatus.searching);
      expect(booking.status.isActive, isTrue);
      expect(booking.status.hasCaptain, isFalse);
      // Taken from create so the tracking card is never briefly missing it.
      expect(booking.startOtp, '4821');
    });
  });

  group('customer · status poll drives the lifecycle', () {
    test('pending → payment-pending → in-progress → completed', () {
      var booking = _bookingFromCreateResponse(
          {'orderId': kOrderId, 'status': 'pending'});
      expect(booking.status, RideStatus.searching);

      // A rider won the race. `payment-pending` is the FIRST status that means
      // "captain attached" — treating it as anything else strands the customer
      // on the searching screen while a rider is already en route.
      booking = _applyStatusPayload(booking, {
        'status': 'payment-pending',
        'pickupOTP': '4821',
        'metadata': {
          'assignedRider': {
            'riderId': 'RID-77',
            'name': 'Ramesh Kumar',
            'vehicleInformation': {
              'registrationNo': 'MP04AB1234',
              'vehicleName': 'Splendor',
              'vehicleType': 'twoWheelerRider',
            },
          },
        },
      });
      expect(booking.status, RideStatus.assigned);
      expect(booking.status.hasCaptain, isTrue);
      expect(booking.captain?.name, 'Ramesh Kumar');
      // Nested vehicleInformation — hand-picking flat keys is how the plate
      // and model used to go missing on the card.
      expect(booking.captain?.vehicleNumber, 'MP04AB1234');
      expect(booking.captain?.vehicleModel, 'Splendor');

      // OTP verified at pickup — the rider started the ride.
      booking = _applyStatusPayload(booking, {'status': 'in-progress'});
      expect(booking.status, RideStatus.onTrip);
      expect(booking.status.isActive, isTrue);

      booking = _applyStatusPayload(booking, {'status': 'completed'});
      expect(booking.status, RideStatus.completed);
      // Terminal → the controller stops every poll on exactly this signal.
      expect(booking.status.isActive, isFalse);
    });

    test('picked-up counts as on-trip, not as "no captain yet"', () {
      // Documented by RIDER_LOCATION_POLLING_GUIDE but absent from the
      // broadcast table; unmapped it fell to `searching` mid-ride.
      expect(RideStatus.fromString('picked-up'), RideStatus.onTrip);
      expect(RideStatus.fromString('PICKED_UP'), RideStatus.onTrip);
    });

    test('every documented broadcast status maps to its screen', () {
      // §3 of the guide, verbatim.
      expect(RideStatus.fromString('pending'), RideStatus.searching);
      expect(RideStatus.fromString('payment-pending'), RideStatus.assigned);
      expect(RideStatus.fromString('confirmed'), RideStatus.assigned);
      expect(RideStatus.fromString('in-progress'), RideStatus.onTrip);
      expect(RideStatus.fromString('completed'), RideStatus.completed);
      // No rider took it in ~60s.
      expect(RideStatus.fromString('rejected'), RideStatus.noRidersFound);
      expect(RideStatus.fromString('cancelled'), RideStatus.cancelled);

      // Hyphen/underscore/case are all the same status on the wire.
      expect(RideStatus.fromString('PAYMENT_PENDING'), RideStatus.assigned);

      // An unknown string must NOT end the ride — a false terminal strands the
      // user with a live captain and no tracking.
      expect(RideStatus.fromString('some-new-state'), RideStatus.searching);
      expect(RideStatus.fromString(null), RideStatus.searching);
    });
  });

  group('customer · socket winner arrives before the poll', () {
    test('ride:queue:accepted fills the card without erasing poll data', () {
      // Poll got there first with a bare rider id and nothing else.
      var booking = _bookingFromCreateResponse(
          {'orderId': kOrderId, 'status': 'pending'}).copyWith(
        status: RideStatus.assigned,
        captain: const RideCaptain(id: 'RID-77', name: ''),
      );

      // Socket winner payload — richer, but carries no position.
      final winner = {
        'orderId': kOrderId,
        'riderId': 'RID-77',
        'riderInfo': {
          'name': 'Ramesh Kumar',
          'contact_no': '9876543210',
          'rating': 4.8,
        },
        'pickupOTP': '4821',
      };

      final incoming = RideCaptain.fromJson({
        'riderId': winner['riderId'],
        ...(winner['riderInfo']! as Map),
      });
      booking = booking.copyWith(
        captain: booking.captain!.merge(incoming),
        startOtp: winner['pickupOTP']!.toString(),
      );

      expect(booking.captain?.id, 'RID-77');
      expect(booking.captain?.name, 'Ramesh Kumar');
      expect(booking.captain?.phone, '9876543210');
      expect(booking.startOtp, '4821');
    });

    test('a later thinner payload never blanks the captain card', () {
      // The user service degrades to "N/A" when briefly unavailable. Merging
      // that over a real name would flicker the card to a rider called "N/A".
      const known = RideCaptain(
        id: 'RID-77',
        name: 'Ramesh Kumar',
        vehicleNumber: 'MP04AB1234',
      );
      final locationPoll = RideCaptain.fromJson({
        'userId': 'RID-77',
        'name': 'N/A',
        'location': {'coordinates': [77.44, 23.22]}, // GeoJSON [lng, lat]
      });

      final merged = known.merge(locationPoll);

      expect(merged.name, 'Ramesh Kumar');
      expect(merged.vehicleNumber, 'MP04AB1234');
      // …while the position the poll DID carry is taken.
      expect(merged.latitude, 23.22);
      expect(merged.longitude, 77.44);
    });
  });

  group('customer · terminal states', () {
    test('exhausted broadcast is offered as rebook, not as an error', () {
      final booking = _applyStatusPayload(
        _bookingFromCreateResponse({'orderId': kOrderId, 'status': 'pending'}),
        {'status': 'rejected'},
      );
      expect(booking.status, RideStatus.noRidersFound);
      expect(booking.status.isActive, isFalse);
    });

    test('a captain-cancelled ride says so', () {
      final booking = _applyStatusPayload(
        _bookingFromCreateResponse({'orderId': kOrderId, 'status': 'pending'}),
        {
          'status': 'cancelled',
          'cancelledBy': 'rider',
          'cancellationReason': 'TAKING_LONGER',
        },
      );

      expect(booking.status, RideStatus.cancelled);
      // Without this the customer is told their own booking failed.
      expect(booking.isCancelledByCaptain, isTrue);
      expect(booking.isCancelledByCustomer, isFalse);
      expect(booking.cancellationReasonLabel, 'Taking longer');
    });
  });

  // ────────────────────────────────────────────────────────────── rider side

  group('rider · the request must RING', () {
    test('broadcast_ride_request rings on the incoming-call path', () {
      // It reuses `fare_ride_incoming_call`'s channel, ringtone and
      // full-screen intent wholesale (guide §7.1) — one consistent experience.
      expect(kRingingRideOperations, contains('broadcast_ride_request'));
      expect(kRingingRideOperations, contains('fare_ride_incoming_call'));

      // The dismissal push is silent by definition — if it ever rang, a losing
      // rider would be alerted about a ride they cannot take.
      expect(kRingingRideOperations,
          isNot(contains(kBroadcastRideClosedOperation)));
    });
  });

  group('rider · order id resolution', () {
    /// The live broadcast push: `payload` is a JSON STRING and the real id sits
    /// at its ROOT, not in `metadata`.
    Map<String, dynamic> broadcastPush() => {
          'operation': 'broadcast_ride_request',
          'payload': jsonEncode({
            'orderId': kOrderId,
            'fare': 85,
            'metadata': {
              'Order_id': kMongoId,
              'Pickup address': 'MP Nagar, Bhopal',
            },
          }),
        };

    test('reads the id from the root of the string payload', () {
      expect(orderIdFromRidePayload(broadcastPush()), kOrderId);
    });

    test('never falls back to metadata.Order_id', () {
      // Same push with the real id stripped: the Mongo `_id` is still there,
      // and taking it would turn a missing id into a confidently wrong one
      // that 404s every `fare/orders/{orderId}/*` call.
      final push = {
        'operation': 'broadcast_ride_request',
        'payload': jsonEncode({
          'metadata': {'Order_id': kMongoId},
        }),
      };

      expect(orderIdFromRidePayload(push), isNull);
    });

    test('falls back to the id embedded in the server action buttons', () {
      final push = {
        'operation': 'broadcast_ride_request',
        'actions': jsonEncode([
          {'id': 'decline_fare_ride_$kOrderId', 'title': 'Decline'},
          {'id': 'view_fare_ride_details_$kOrderId', 'title': 'View'},
        ]),
      };

      expect(orderIdFromRidePayload(push), kOrderId);
    });

    test('decodes payload whether it arrives as String or Map', () {
      final asString = {'payload': jsonEncode({'orderId': kOrderId})};
      final asMap = {'payload': {'orderId': kOrderId}};

      expect(decodeRidePayload(asString)?['orderId'], kOrderId);
      expect(decodeRidePayload(asMap)?['orderId'], kOrderId);
      // Malformed JSON degrades to null rather than throwing in the bg isolate.
      expect(decodeRidePayload({'payload': '{not json'}), isNull);
    });
  });

  group('rider · losing the race must silence the ring', () {
    test('the dismiss push targets the exact notification the ring posted',
        () {
      // This is the whole reason the id is derived from the orderId instead of
      // the clock: the two run in DIFFERENT isolates, and the silent
      // `broadcast_ride_closed` push carries nothing but the orderId.
      final posted = ringNotificationIdFor(kOrderId);
      final toCancel = ringNotificationIdFor(
        orderIdFromRidePayload({
          'operation': kBroadcastRideClosedOperation,
          'payload': jsonEncode({'orderId': kOrderId}),
        }),
      );

      expect(toCancel, posted);
    });

    test('two concurrent requests do not collide on one notification', () {
      expect(
        ringNotificationIdFor(kOrderId),
        isNot(ringNotificationIdFor('ORD-1784638670141')),
      );
    });

    test('an id-less push still posts something cancellable', () {
      final fallback = ringNotificationIdFor(null);
      expect(fallback, isNonZero);
      expect(ringNotificationIdFor(''), fallback);
    });
  });

  group('rider · notification action buttons', () {
    test('our own Decline/View ids round-trip back to the order', () {
      // The action is handled in the background isolate, where nothing holds
      // "which ride is ringing" — so the id has to carry the order itself.
      final decline = rideDeclineActionId(kOrderId);
      final view = rideViewActionId(kOrderId);

      expect(isRideDeclineAction(decline), isTrue);
      expect(isRideViewAction(view), isTrue);
      expect(orderIdFromRideActionId(decline, kRideDeclineActionPrefixes),
          kOrderId);
      expect(orderIdFromRideActionId(view, kRideViewActionPrefixes), kOrderId);
    });

    test("the server's own spelling works identically", () {
      const serverDecline = 'decline_fare_ride_$kOrderId';
      const serverView = 'view_fare_ride_details_$kOrderId';

      expect(isRideDeclineAction(serverDecline), isTrue);
      expect(isRideViewAction(serverView), isTrue);
      expect(orderIdFromRideActionId(serverDecline, kRideDeclineActionPrefixes),
          kOrderId);
      expect(
          orderIdFromRideActionId(serverView, kRideViewActionPrefixes),
          kOrderId);
    });

    test('a Decline button is never mistaken for a View button', () {
      expect(isRideViewAction(rideDeclineActionId(kOrderId)), isFalse);
      expect(isRideDeclineAction(rideViewActionId(kOrderId)), isFalse);
    });
  });

  // ───────────────────────────────────────────────── both sides, one order id

  group('customer ↔ rider share one order id', () {
    test("the created order is the order the rider's push names", () {
      // Customer creates…
      final booking = _bookingFromCreateResponse({
        'orderId': kOrderId,
        'status': 'pending',
      });

      // …the server rings riders with that same order…
      final ringOrderId = orderIdFromRidePayload({
        'operation': 'broadcast_ride_request',
        'payload': jsonEncode({
          'orderId': kOrderId,
          'metadata': {'Order_id': kMongoId},
        }),
      });

      // …and both halves agree, which is what makes accept/reject, the OTP and
      // the dismissal all address the same ride.
      expect(ringOrderId, booking.rideId);
      expect(ringOrderId, isNot(kMongoId));
    });
  });
}

// ─────────────────────────────────────────────────────────────────── helpers
//
// These mirror what RideBookingController does with each response. The
// controller builds its own repo, so its methods can't be driven from a unit
// test — the payload handling they perform is reproduced here against the same
// models.

/// What `bookRide()` keeps from the create response: the id and the OTP, with
/// pickup/drop/fare carried over from what the user already chose.
RideBooking _bookingFromCreateResponse(Map<String, dynamic> response) {
  final order = response['order'] is Map ? response['order'] as Map : response;
  final otp = order['pickupOTP']?.toString();
  return RideBooking(
    rideId: (order['orderId'] ?? order['_id'] ?? order['id'] ?? '').toString(),
    status: RideStatus.fromString(order['status']?.toString()),
    pickup: _pickup,
    drop: _drop,
    vehicleCode: 'twoWheelerRider',
    vehicleName: 'Bike',
    fare: 85,
    paymentMode: 'CASH',
    startOtp: (otp != null && otp.isNotEmpty) ? otp : null,
  );
}

/// What `_pollStatus()` merges onto the booking it already holds — the status
/// payload carries no pickup/drop/fare, so it can only ever be an overlay.
RideBooking _applyStatusPayload(RideBooking booking, Map<String, dynamic> data) {
  final otp = (data['pickupOTP'] ?? data['pickupOtp'])?.toString();
  var updated = booking.copyWith(
    status: RideStatus.fromString(data['status']?.toString()),
    startOtp: (otp != null && otp.isNotEmpty) ? otp : null,
    cancelledBy: data['cancelledBy']?.toString(),
    cancellationReason: data['cancellationReason']?.toString(),
  );

  final metadata = data['metadata'];
  if (metadata is Map) {
    final rider = metadata['assignedRider'];
    if (rider is Map) {
      final incoming = RideCaptain.fromJson(rider);
      updated = updated.copyWith(
        captain: booking.captain?.merge(incoming) ?? incoming,
      );
    } else if (rider != null && updated.captain == null) {
      updated = updated.copyWith(
        captain: RideCaptain(id: rider.toString(), name: ''),
      );
    }
  }
  return updated;
}
