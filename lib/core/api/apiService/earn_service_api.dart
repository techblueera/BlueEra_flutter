import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `earn-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin EarnServiceApi {
  String earnServices = "earn-service/services";
  String earnServicesById(String serviceId) =>
      'earn-service/services/$serviceId';
  String earnServicesImages(String serviceId) =>
      'earn-service/services/$serviceId/images';
  final String servicesByLatLng = "earn-service/services/all/map";
  String earnServiceByUserID(String userId) =>
      'earn-service/services/user/$userId';

  //help and support
  final String getFaqs = 'earn-service/help-support/faqs';
  final String createQueries = 'earn-service/help-support/queries';
  final String mediaUploadUrlEarn = 'earn-service/s3/generate-upload-urls?';
  String getQueriesById(String QueriesId) =>
      'earn-service/help-support/queries/$QueriesId';
  final String professionalsFull = 'earn-service/professional/full';
  final String professionalsUpdate = 'earn-service/professional/update';
  final String professionalsCertificate =
      'earn-service/professional/certificate';
  final String professionalsContactUs = 'earn-service/professional/contact';
  final String professionalsContactUsById = 'earn-service/professional/';
  final String professionalsTiming = 'earn-service/professional';
  final String professionalsPortfolio = 'earn-service/professional/portfolio';
  final String professionalSearch = 'earn-service/professional/search';

  /// Service enquiry raised from the Discover self-profession "Enquire" form.
  /// `POST` creates the enquiry AND (server-side) the in-chat enquiry card +
  /// `newServiceEnquiryReceived` socket emit. The status `PUT` lets the
  /// provider accept / decline, emitting `serviceEnquiryStatusUpdated`.
  /// See docs/backend/service-enquiry-api.md for the full contract.
  final String serviceEnquiries = 'earn-service/service-enquiries';
  String serviceEnquiryStatus(String enquiryId) =>
      'earn-service/service-enquiries/$enquiryId/status';

  String predefinedServiceCategory(String category) =>
      'earn-service/predefined/$category';
  String predefinedProfessionServices(String professionSlugId) =>
      'earn-service/predefined-professional/$professionSlugId';

  /// Tiffin
  final String tiffins = "earn-service/tiffins";
  final String tiffinsByUserId = "earn-service/tiffins/user/$userId";
  final String tiffinsCenters = "earn-service/tiffins/centers";
  final String homeFood = "earn-service/homeFood";
  final String homeFoodByUserId = "earn-service/homeFood/user/$userId";

  /// Per-store (consumer-side) tiffins — same path but for an arbitrary
  /// store's [storeUserId], not the logged-in user. The store details screen
  /// keys everything off the store's userId.
  String tiffinsByUser(String storeUserId) =>
      'earn-service/tiffins/user/$storeUserId';

  /// Earn Profiles
  final String earnProfiles = "earn-service/earn-profiles";

  /// All home made food items for a given earn profile — backs the consumer
  /// store details screen. `GET earn-service/earn-profiles/{id}/home-foods`.
  String earnProfileHomeFoods(String id) =>
      'earn-service/earn-profiles/$id/home-foods';

  /// Place a home made food order. `POST earn-service/homeFoodOrders`.
  final String homeFoodOrders = "earn-service/homeFoodOrders";

  /// Mark a home made food self-pickup order ready (cook side).
  /// `PUT earn-service/homeFoodOrders/{orderId}/ready`.
  String homeFoodOrderReady(String orderId) =>
      'earn-service/homeFoodOrders/$orderId/ready';

  /// Place a home made product order. `POST earn-service/homeProductOrders`.
  final String homeProductOrders = "earn-service/homeProductOrders";

  /// Admin posts feed — drives the testimonials, overview and tutorial
  /// sections on the new BDM/referral dashboard. Filter by `type` query
  /// param (`testimonial` | `overview` | `tutorial`) plus `page` / `limit`.
  final String adminPosts = "earn-service/admin-posts";
}
