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

  final String checkAnyEarnServiceCreated = 'earn-service/services/any/check';
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

  /// Earn Profiles
  final String earnProfiles = "earn-service/earn-profiles";
}
