/// All `booking-enquiry-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin BookingEnquiryServiceApi {
  final String bookings = 'booking-enquiry-service/bookings';
  String receivedBooking(String channelId) =>
      'booking-enquiry-service/bookings/summary/by-videos?channelId=$channelId';
  String receivedEnquiry(String channelId) =>
      'booking-enquiry-service/inquiries/summary/by-videos?channelId=$channelId';
  String receivedVideoBooking(String channelId, String videoId) =>
      'booking-enquiry-service/bookings?channelId=$channelId&videoId=$videoId';
  String receivedVideoEnquiry(String channelId, String videoId) => ''
      'booking-enquiry-service/inquiries?channelId=$channelId&videoId=$videoId';
  String getBookingById(String bookingId) =>
      'booking-enquiry-service/bookings/$bookingId';
  String updateBookingStatus(String id) =>
      'booking-enquiry-service/bookings/$id';
  String enquiryBookingStatus(String id) =>
      'booking-enquiry-service/inquiries/$id/status';
  final String MyBookingList = 'booking-enquiry-service/bookings/my-bookings';
  final String myInquiries = 'booking-enquiry-service/inquiries/my-inquiries';
  final String Inquiries = 'booking-enquiry-service/inquiries';

  String setAvailability(String id) =>
      "booking-enquiry-service/availability/$id";
  String setUserAvailability(String id) =>
      "booking-enquiry-service/availability/user/$id";
  String getcalender(String channelId) =>
      "booking-enquiry-service/availability/calendar/$channelId";
//  String getReceivedBooking (String channelId,String videoId)=>"booking-enquiry-service/bookings/$channelId/$videoId";

  /// Booking & Inquiry
  String bookingAvailability(String channelId) =>
      "booking-enquiry-service/availability/$channelId";

  final String bookingGetRentalServiceMap = "booking-enquiry-service/rentals";
  final String rentalService = "booking-enquiry-service/rentals";
  String updateRentalService(String rentalId) =>
      "booking-enquiry-service/rentals/$rentalId";
  String uploadRentalImages(String rentalId) =>
      "booking-enquiry-service/rentals/$rentalId/upload-images";
  String deleteRentalService(String rentalId) =>
      "booking-enquiry-service/rentals/$rentalId";

  final String properties = 'booking-enquiry-service/properties';
  final String propertyStats = 'booking-enquiry-service/properties/stats';
  String propertyById(String id) =>
      'booking-enquiry-service/properties/$id';
  // Ratings on a property — mirrors the user/business ratings
  // convention (`<entity>/$id/ratings`).
  String propertyRatings(String id) =>
      'booking-enquiry-service/properties/$id/ratings';
  String propertiesByFilter(String listingType, String propertyType) =>
      'booking-enquiry-service/properties?listingType=$listingType&propertyType=$propertyType';

  /// Property enquiry raised from the rental Discover listing card. `POST`
  /// creates the enquiry AND (server-side) the in-chat `property_enquiry`
  /// card + `newPropertyEnquiryReceived` socket emit. The status `PUT` lets
  /// the owner accept / decline, emitting `propertyEnquiryStatusUpdated`.
  /// See docs/backend/property-enquiry-flutter-integration.md.
  final String propertyEnquiries =
      'booking-enquiry-service/property-enquiries';
  String propertyEnquiryStatus(String enquiryId) =>
      'booking-enquiry-service/property-enquiries/$enquiryId/status';
}
