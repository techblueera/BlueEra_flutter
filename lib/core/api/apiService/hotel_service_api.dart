/// All `hotel-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `hotelBulkStatus` and `hotelBulkCatalogStatus` contain double
/// slashes (`/hotels//offerings/...`, `/businesses/hotels//catalog`) —
/// preserved here to mirror what the client currently sends. Worth a
/// separate cleanup ticket rather than a silent fix during refactor.
mixin HotelServiceApi {
  final String hotelServiceCategory = 'hotel-service/api/categories/nested';
  final String fetchHotelFromAi = 'ai-service/api/ai-hotel/fetch-details';
  final String createHotelService = 'hotel-service/api/hotel-profile';
  final String hotelBulkStatus =
      'hotel-service/api/hotels//offerings/bulk-toggle';
  final String hotelBulkCatalogStatus =
      'hotel-service/api/businesses/hotels//catalog';
  final String hotelsOfferings = 'hotel-service/api/hotels/offerings';
  final String hotelsContactUsGet =
      'hotel-service/api/businesses/profile/about-us';

  ///HOTEL....
  final String hotelAmenities = 'hotel-service/api/hotel-amenities';
  final String hotelRoomAmenities = 'hotel-service/api/room-amenities';
  final String hotelPolicies = 'hotel-service/api/hotel-policies';
  final String hotelPropertyPhotos = 'hotel-service/api/property-photos';
  final String hotelRoom = 'hotel-service/api/rooms';
  final String hotelContacts = 'hotel-service/api/contacts';
  final String hotelProfile = 'hotel-service/api/hotel-profile';
  final String hotelRoomType = 'hotel-service/api/room-types';
  final String hotelRoomsType = 'hotel-service/api/rooms/type';
  final String hotelHomeFull = 'hotel-service/api/hotels/full';
  final String hotelSearch = 'hotel-service/api/hotels/Search';
}
