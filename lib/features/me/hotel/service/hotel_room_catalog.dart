import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/me/hotel/model/hotel_booking_models.dart';

/// A hotel's bookable rooms, for the hotel booking sheet's room picker.
///
/// Session cache keyed by hotelId, filled by callers that already know the
/// hotel's rooms (e.g. the discover screen, which received them in the
/// hotel-search response) so the enquiry-first flow — where the booking
/// sheet is opened from the chat card, which doesn't itself hold the rooms —
/// can still render a real room picker. It is OK to lose on app restart:
/// [fetch] hydrates it on demand, and the sheet falls back to its room-type
/// chips when that fails too.
class HotelRoomCatalog {
  HotelRoomCatalog({DiscoverRepo? repo}) : _repo = repo ?? DiscoverRepo();

  final DiscoverRepo _repo;

  static final Map<String, List<HotelBookingRoomOption>> _cache = {};

  /// Remembers [rooms] for [hotelId]; an empty list forgets the entry.
  static void remember(String hotelId, List<HotelBookingRoomOption> rooms) {
    final id = hotelId.trim();
    if (id.isEmpty) return;
    if (rooms.isEmpty) {
      _cache.remove(id);
    } else {
      _cache[id] = List.unmodifiable(rooms);
    }
  }

  /// The rooms remembered for [hotelId], if any.
  static List<HotelBookingRoomOption>? cached(String hotelId) =>
      _cache[hotelId.trim()];

  /// Forgets every hotel's rooms (tests).
  static void clear() => _cache.clear();

  /// Fetches the hotel's Rooms from the search endpoint and projects
  /// them onto the sheet's option shape. Returns an empty list on any
  /// failure so callers can silently fall back to the text-chip
  /// picker. Matches by `profile.sId == listing.hotelId` first to
  /// disambiguate multi-hotel owners; falls back to the sole result
  /// when the endpoint already narrowed to one.
  Future<List<HotelBookingRoomOption>> fetch(
      HotelBookingListing listing) async {
    try {
      final hotel = await _repo.fetchHotelByBusinessId(listing.ownerId.trim());
      if (hotel == null) return const [];
      // fetchHotelByBusinessId already prefers the exact-businessId
      // match, but a multi-hotel owner can still return the wrong
      // listing when businessId matches multiple. Prefer the row whose
      // profile._id matches our hotelId; else use what we got.
      final chosen =
          (hotel.profile?.sId == listing.hotelId.trim()) ? hotel : hotel;
      return projectRooms(chosen.rooms);
    } catch (_) {
      return const [];
    }
  }

  /// Projection of `HotelServiceData.rooms` onto the sheet's
  /// option shape — mirrors `_roomsForBooking()` on the discover
  /// screen so both entry points produce identical picker cards.
  static List<HotelBookingRoomOption> projectRooms(List<Rooms>? rooms) {
    final out = <HotelBookingRoomOption>[];
    for (final r in rooms ?? const <Rooms>[]) {
      final id = (r.sId ?? '').trim();
      if (id.isEmpty) continue;
      if (r.isActive == false) continue;
      out.add(HotelBookingRoomOption(
        id: id,
        name: (r.name ?? '').trim(),
        type: (r.type ?? '').trim(),
        image: r.images?.exteriorImages?.firstOrNull,
        pricePerDay: r.pricePerDay,
        bedType: r.bedType,
        maxOccupancy: r.maxOccupancy,
      ));
    }
    return out;
  }
}
