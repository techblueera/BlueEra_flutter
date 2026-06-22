/// Domain models for the vehicle **booking** ("place order") flow
/// (`vehicle-service/vehicles/bookings/...` endpoints).
///
/// Mirrors `docs/backend/VEHICLE_SERVICE_API_DOCUMENTATION.md`. The
/// booking model is connect-style (one request = one listing): no cart,
/// no quantity, no payment. Every model exposes `fromJson`; the request
/// body is assembled by the controller from primitive args.
library;

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────

/// Why the buyer is reaching out. Sent as `intent` on place-order and
/// echoed back on every booking object.
enum VehicleBookingIntent { buy, testDrive, exchange, info }

extension VehicleBookingIntentWire on VehicleBookingIntent {
  /// Wire value the API expects (`BUY | TEST_DRIVE | EXCHANGE | INFO`).
  String get wire {
    switch (this) {
      case VehicleBookingIntent.buy:
        return 'BUY';
      case VehicleBookingIntent.testDrive:
        return 'TEST_DRIVE';
      case VehicleBookingIntent.exchange:
        return 'EXCHANGE';
      case VehicleBookingIntent.info:
        return 'INFO';
    }
  }

  /// Localised display label for the chips / detail rows.
  String get label {
    switch (this) {
      case VehicleBookingIntent.buy:
        return AppStrings.bookingIntentBuy.tr;
      case VehicleBookingIntent.testDrive:
        return AppStrings.bookingIntentTestDrive.tr;
      case VehicleBookingIntent.exchange:
        return AppStrings.bookingIntentExchange.tr;
      case VehicleBookingIntent.info:
        return AppStrings.bookingIntentInfo.tr;
    }
  }

  static VehicleBookingIntent parse(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'TEST_DRIVE':
        return VehicleBookingIntent.testDrive;
      case 'EXCHANGE':
        return VehicleBookingIntent.exchange;
      case 'INFO':
        return VehicleBookingIntent.info;
      case 'BUY':
      default:
        return VehicleBookingIntent.buy;
    }
  }
}

/// Lifecycle state of a booking.
enum VehicleBookingStatus { pending, accepted, declined, cancelled }

extension VehicleBookingStatusWire on VehicleBookingStatus {
  /// Wire value (`pending | accepted | declined | cancelled`).
  String get wire => name;

  String get label {
    switch (this) {
      case VehicleBookingStatus.pending:
        return AppStrings.bookingStatusPending.tr;
      case VehicleBookingStatus.accepted:
        return AppStrings.bookingStatusAccepted.tr;
      case VehicleBookingStatus.declined:
        return AppStrings.bookingStatusDeclined.tr;
      case VehicleBookingStatus.cancelled:
        return AppStrings.bookingStatusCancelled.tr;
    }
  }

  bool get isPending => this == VehicleBookingStatus.pending;

  static VehicleBookingStatus parse(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'accepted':
        return VehicleBookingStatus.accepted;
      case 'declined':
        return VehicleBookingStatus.declined;
      case 'cancelled':
        return VehicleBookingStatus.cancelled;
      case 'pending':
      default:
        return VehicleBookingStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Snapshot — denormalised listing card carried on every booking
// ─────────────────────────────────────────────────────────────────────

/// Self-contained listing card embedded in a booking (and in the Kafka
/// chat event). Render it directly — no re-fetch of the listing needed.
class VehicleBookingSnapshot {
  final String? title;
  final String? image;
  final String? priceText; // pre-formatted Indian-grouped rupees
  final String? condition; // NEW / USED
  final String? location;

  VehicleBookingSnapshot({
    this.title,
    this.image,
    this.priceText,
    this.condition,
    this.location,
  });

  factory VehicleBookingSnapshot.fromJson(Map<String, dynamic> j) =>
      VehicleBookingSnapshot(
        title: j['title'] as String?,
        image: j['image'] as String?,
        priceText: j['priceText'] as String?,
        condition: j['condition'] as String?,
        location: j['location'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────
// Booking
// ─────────────────────────────────────────────────────────────────────

class VehicleBooking {
  final String id;
  final String? buyerId;
  final String? sellerId;
  final String? sellerType; // "User" | "Business"
  final String? inventoryId;
  final String? variantId;
  final VehicleBookingIntent intent;
  final double? offerPrice;
  final String? note;
  final List<String> photos;
  final VehicleBookingSnapshot? snapshot;
  final VehicleBookingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleBooking({
    required this.id,
    this.buyerId,
    this.sellerId,
    this.sellerType,
    this.inventoryId,
    this.variantId,
    required this.intent,
    this.offerPrice,
    this.note,
    this.photos = const [],
    this.snapshot,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleBooking.fromJson(Map<String, dynamic> j) => VehicleBooking(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        buyerId: j['buyerId'] as String?,
        sellerId: j['sellerId'] as String?,
        sellerType: j['sellerType'] as String?,
        inventoryId: j['inventoryId'] as String?,
        variantId: j['variantId'] as String?,
        intent: VehicleBookingIntentWire.parse(j['intent'] as String?),
        offerPrice: (j['offerPrice'] as num?)?.toDouble(),
        note: j['note'] as String?,
        photos:
            ((j['photos'] as List?) ?? const []).whereType<String>().toList(),
        snapshot: j['snapshot'] is Map
            ? VehicleBookingSnapshot.fromJson(
                Map<String, dynamic>.from(j['snapshot'] as Map))
            : null,
        status: VehicleBookingStatusWire.parse(j['status'] as String?),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );
}

/// Parsed `{ status, page, limit, total, bookings[] }` list payload used
/// by both `GET /me` and `GET /seller/me`.
class PaginatedVehicleBookings {
  final List<VehicleBooking> bookings;
  final int page;
  final int limit;
  final int total;

  PaginatedVehicleBookings({
    required this.bookings,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaginatedVehicleBookings.fromJson(Map<String, dynamic> j) =>
      PaginatedVehicleBookings(
        bookings: ((j['bookings'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => VehicleBooking.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        page: (j['page'] as num?)?.toInt() ?? 1,
        limit: (j['limit'] as num?)?.toInt() ?? 20,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}
