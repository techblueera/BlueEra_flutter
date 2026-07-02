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

  /// Place a tiffin order. `POST earn-service/tiffinOrders`. Separate from
  /// home-made-food orders — tiffins are ordered on their own flow.
  final String tiffinOrders = "earn-service/tiffinOrders";

  /// Mark a tiffin self-pickup order ready (cook side).
  /// `PUT earn-service/tiffinOrders/{orderId}/ready`.
  String tiffinOrderReady(String orderId) =>
      'earn-service/tiffinOrders/$orderId/ready';

  /// Customer's tiffin order history (paginated). `GET earn-service/tiffinOrders/me`.
  final String tiffinOrdersMe = "earn-service/tiffinOrders/me";

  /// Whether the customer has an ongoing tiffin order.
  /// `GET earn-service/tiffinOrders/status/me`.
  final String tiffinOrdersStatusMe = "earn-service/tiffinOrders/status/me";

  /// Cook's incoming tiffin orders (paginated).
  /// `GET earn-service/tiffinOrders/seller/me`.
  final String tiffinOrdersSellerMe = "earn-service/tiffinOrders/seller/me";

  /// Update / cancel a tiffin order. `PUT earn-service/tiffinOrders/{id}`.
  String tiffinOrderById(String orderId) =>
      'earn-service/tiffinOrders/$orderId';

  /// Alternative cooks for a tiffin order's meal slot(s).
  /// `GET earn-service/tiffinOrders/{orderId}/alternatives`.
  String tiffinOrderAlternatives(String orderId) =>
      'earn-service/tiffinOrders/$orderId/alternatives';

  /// Place a home made product order. `POST earn-service/homeProductOrders`.
  final String homeProductOrders = "earn-service/homeProductOrders";

  /// Admin posts feed — drives the testimonials, overview and tutorial
  /// sections on the new BDM/referral dashboard. Filter by `type` query
  /// param (`testimonial` | `overview` | `tutorial`) plus `page` / `limit`.
  final String adminPosts = "earn-service/admin-posts";

  /// Referral-page testimonials. Each item carries a title, description and
  /// either `images[]` or a `video`. `GET earn-service/testimonial`.
  final String earnTestimonials = "earn-service/testimonial";

  /// Referral-page tutorials (same media shape as testimonials).
  /// `GET earn-service/tutorial`.
  final String earnTutorials = "earn-service/tutorial";

  /// Referral-page overview posts (same media shape — title/description/
  /// images[]/video). `GET earn-service/overview`.
  final String earnOverview = "earn-service/overview";

  /// Content-creator program: bonus/program details, progress and the user's
  /// submitted videos — one call powers the whole Creator tab.
  /// `GET earn-service/creator`.
  final String earnCreator = "earn-service/creator";
  final String earnCreatorVideos = "earn-service/creator/videos";

  /// Earn-Coin (gamification) — coin chip + Coin Wallet card + the 5-tab
  /// "View Details" screen. Service-internal prefix is `/earn`.
  /// See docs/backend/FLUTTER-MASTER-GUIDE.md.
  final String earnBalance = 'earn-service/earn/balance';
  final String earnDashboard = 'earn-service/earn/dashboard';
  final String earnTasks = 'earn-service/earn/tasks';
  final String earnHistory = 'earn-service/earn/history';
  final String earnLeaderboard = 'earn-service/earn/leaderboard';
  final String earnStreak = 'earn-service/earn/streak';
  final String earnRedeem = 'earn-service/earn/redeem';
}
