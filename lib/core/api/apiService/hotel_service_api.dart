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

  /// Hotel enquiry — `POST` raises an enquiry against a hotel listing
  /// (creates the in-chat `hotel_enquiry` card + emits
  /// `newHotelEnquiryReceived`); `PUT` status lets the hotel owner
  /// accept / decline, emitting `hotelEnquiryStatusUpdated`. See
  /// lib/docs/enquiry-flows-ui-integration.md §2a.
  final String hotelEnquiries = 'hotel-service/api/hotel-enquiries';
  String hotelEnquiryStatus(String enquiryId) =>
      'hotel-service/api/hotel-enquiries/$enquiryId/status';

  /// GET one — used by the owner chat card to fetch the enquiry's true
  /// current status (`pending` | `accepted` | `declined`) when the
  /// message metadata's local latch is empty. Doc §2a "Get one".
  String hotelEnquiryById(String enquiryId) =>
      'hotel-service/api/hotel-enquiries/$enquiryId';
}
