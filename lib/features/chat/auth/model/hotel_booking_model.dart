/// Payload carried by a `messageType: "hotel_booking"` chat message.
///
/// Mirrors the shape settled in
/// `lib/docs/UI_INTEGRATION_HOTEL_ENQUIRY_BOOKING.md` §2.3:
///
/// - Hotel id (`hotel_id` on the request body, denormalised back as `hotelId`).
/// - Booking fields: [roomType] (single string), [checkIn]/[checkOut],
///   [guests].
/// - **Room-level** fields (only present when the caller sent `room_id`):
///   [roomId], [roomName], [pricePerNight], [nights], [totalAmount].
/// - [enquiryId] — non-null only for the enquiry-first flow.
/// - Listing snapshot ([listingName]/[listingImage]/[priceText]/[location]).
/// - [status] flipped by owner (`accepted`/`declined`) or buyer (`cancelled`).
///
/// ⚠️ Field-name difference vs. hotel-enquiry: the booking owner field is
/// **`businessId`**, not `ownerId` (doc §2.3 warning). We accept both here
/// so older cached cards keep working, but new server payloads use
/// `businessId`.
class HotelBookingModel {
  String? bookingId;
  String? hotelId;

  /// Owner's user id. Server sends this as `businessId` (doc §2.3);
  /// legacy cached documents may still use `ownerId`. Both are accepted.
  String? businessId;

  String? customerId;

  // Listing snapshot.
  String? listingName;
  String? listingImage;
  String? priceText;
  String? location;

  /// Selected room type. Single string (e.g. "Deluxe"). When the booking
  /// is room-level the server overwrites this with the Room's own type.
  String? roomType;

  /// ISO-8601 timestamps. `checkOut` must be after `checkIn`
  /// (server-enforced with a 400). Both are **required** when the
  /// booking is room-level (i.e. [roomId] is set).
  String? checkIn;
  String? checkOut;

  /// Number of guests. Optional; coerced by the server to `>= 1`.
  int? guests;

  /// Room-level fields — populated by the server from the Room doc when
  /// the booking targets a specific room (`room_id`). `null`/`0` on
  /// type-level bookings.
  String? roomId;
  String? roomName;
  num? pricePerNight;
  int? nights;

  /// `pricePerNight × nights`. Display-only — nothing is charged.
  num? totalAmount;

  /// Set only when this booking was raised via the enquiry-first flow
  /// (customer sent `enquiry_id` linking back to their prior enquiry).
  String? enquiryId;

  List<String>? photos;
  String? note;

  /// 'pending' | 'accepted' | 'declined' | 'cancelled' (buyer-cancel only).
  String? status;

  HotelBookingModel({
    this.bookingId,
    this.hotelId,
    this.businessId,
    this.customerId,
    this.listingName,
    this.listingImage,
    this.priceText,
    this.location,
    this.roomType,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.roomId,
    this.roomName,
    this.pricePerNight,
    this.nights,
    this.totalAmount,
    this.enquiryId,
    this.photos,
    this.note,
    this.status,
  });

  /// Owner user id — alias for [businessId] to keep older widget code
  /// working. Doc §2.3 warns that booking uses `businessId` (not the
  /// enquiry's `ownerId`); both point at the same thing.
  String? get ownerId => businessId;
  set ownerId(String? value) => businessId = value;

  static List<String>? _stringList(dynamic v) => v is List
      ? List<String>.from(v.map((e) => e.toString()))
      : null;

  static num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String && v.trim().isNotEmpty) return num.tryParse(v);
    return null;
  }

  static int? _int(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v);
    return null;
  }

  factory HotelBookingModel.fromJson(Map<String, dynamic> json) {
    return HotelBookingModel(
      bookingId: (json['bookingId'] ?? json['_id'] ?? json['id'])?.toString(),
      hotelId: (json['hotelId'] ?? json['hotel_id'])?.toString(),
      // Doc §2.3: booking owner is `businessId`. Fall back to `ownerId`
      // for cards created before the field rename.
      businessId: (json['businessId'] ??
              json['business_id'] ??
              json['ownerId'] ??
              json['owner_id'])
          ?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName: json['listingName']?.toString(),
      listingImage:
          (json['listingImage'] ?? json['listing_image'])?.toString(),
      priceText: (json['priceText'] ?? json['price_text'])?.toString(),
      location: json['location']?.toString(),
      roomType: (json['roomType'] ?? json['room_type'])?.toString(),
      checkIn: (json['checkIn'] ?? json['check_in'])?.toString(),
      checkOut: (json['checkOut'] ?? json['check_out'])?.toString(),
      guests: _int(json['guests']),
      roomId: (json['roomId'] ?? json['room_id'])?.toString(),
      roomName: (json['roomName'] ?? json['room_name'])?.toString(),
      pricePerNight: _num(json['pricePerNight'] ?? json['price_per_night']),
      nights: _int(json['nights']),
      totalAmount: _num(json['totalAmount'] ?? json['total_amount']),
      enquiryId: (json['enquiryId'] ?? json['enquiry_id'])?.toString(),
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'hotelId': hotelId,
      'businessId': businessId,
      'customerId': customerId,
      'listingName': listingName,
      'listingImage': listingImage,
      'priceText': priceText,
      'location': location,
      'roomType': roomType,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'guests': guests,
      'roomId': roomId,
      'roomName': roomName,
      'pricePerNight': pricePerNight,
      'nights': nights,
      'totalAmount': totalAmount,
      'enquiryId': enquiryId,
      'photos': photos,
      'note': note,
      'status': status,
    };
  }
}
