/// Snapshot of the hotel being booked — denormalised so the sheet header
/// and (later) the in-chat card render without re-fetching the listing.
class HotelBookingListing {
  final String hotelId;
  final String ownerId;
  final String ownerName;
  final String hotelName;
  final String? coverImage;
  final String? location;

  const HotelBookingListing({
    required this.hotelId,
    required this.ownerId,
    required this.ownerName,
    required this.hotelName,
    this.coverImage,
    this.location,
  });
}

/// One selectable room in the booking sheet — a slim projection of the
/// discover screen's `Rooms` model (see
/// `lib/features/common/Discover/model/hotel_search_model.dart`) so this
/// widget doesn't couple to the search-response shape.
///
/// When the customer picks a room the booking becomes **room-level**
/// (doc §2.1): the id is sent as `room_id`, dates become required, and
/// `roomName`/`roomType`/`pricePerNight` are derived by the server from
/// the Room doc — so we never need to send them ourselves.
class HotelBookingRoomOption {
  final String id;
  final String name;
  final String type;
  final String? image;
  final int? pricePerDay;
  final String? bedType;
  final String? maxOccupancy;

  const HotelBookingRoomOption({
    required this.id,
    required this.name,
    required this.type,
    this.image,
    this.pricePerDay,
    this.bedType,
    this.maxOccupancy,
  });
}
