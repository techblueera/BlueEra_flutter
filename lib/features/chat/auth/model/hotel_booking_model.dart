/// Payload carried by a `messageType: "hotel_booking"` chat message.
///
/// Mirrors the shape settled in `lib/docs/enquiry-flows-ui-integration.md`
/// §2b: a hotel id (`hotel_id` on the request body, denormalised back as
/// `hotelId` on the card), fixed booking fields (`roomType`, `checkIn`,
/// `checkOut`, `guests`), optional [note] / [photos], and a [status] the
/// owner flips via the `hotelBookingStatusUpdated` socket. The buyer can
/// also cancel while `pending` (booking-only extra transition — same
/// socket event carries `status: cancelled`).
///
/// A small listing snapshot ([listingName] / [listingImage] / [priceText]
/// / [location]) is embedded so the in-chat card renders without
/// re-fetching the listing. `priceText` is **display only** — nothing is
/// charged.
class HotelBookingModel {
  String? bookingId;
  String? hotelId;
  String? ownerId;
  String? customerId;

  // Listing snapshot.
  String? listingName;
  String? listingImage;
  String? priceText;
  String? location;

  /// Selected room type (e.g. "Deluxe" / "Suite"). Optional.
  String? roomType;

  /// ISO-8601 timestamps. `checkOut` must be after `checkIn`
  /// (server-enforced with a 400).
  String? checkIn;
  String? checkOut;

  /// Number of guests. Optional.
  int? guests;

  List<String>? photos;
  String? note;

  /// 'pending' | 'accepted' | 'declined' | 'cancelled' (buyer-cancel only).
  String? status;

  HotelBookingModel({
    this.bookingId,
    this.hotelId,
    this.ownerId,
    this.customerId,
    this.listingName,
    this.listingImage,
    this.priceText,
    this.location,
    this.roomType,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.photos,
    this.note,
    this.status,
  });

  static List<String>? _stringList(dynamic v) => v is List
      ? List<String>.from(v.map((e) => e.toString()))
      : null;

  factory HotelBookingModel.fromJson(Map<String, dynamic> json) {
    return HotelBookingModel(
      bookingId: (json['bookingId'] ?? json['_id'] ?? json['id'])?.toString(),
      hotelId: (json['hotelId'] ?? json['hotel_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName: json['listingName']?.toString(),
      listingImage:
          (json['listingImage'] ?? json['listing_image'])?.toString(),
      priceText: (json['priceText'] ?? json['price_text'])?.toString(),
      location: json['location']?.toString(),
      roomType: (json['roomType'] ?? json['room_type'])?.toString(),
      checkIn: (json['checkIn'] ?? json['check_in'])?.toString(),
      checkOut: (json['checkOut'] ?? json['check_out'])?.toString(),
      guests: (json['guests'] is num)
          ? (json['guests'] as num).toInt()
          : int.tryParse(json['guests']?.toString() ?? ''),
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'hotelId': hotelId,
      'ownerId': ownerId,
      'customerId': customerId,
      'listingName': listingName,
      'listingImage': listingImage,
      'priceText': priceText,
      'location': location,
      'roomType': roomType,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'guests': guests,
      'photos': photos,
      'note': note,
      'status': status,
    };
  }
}
