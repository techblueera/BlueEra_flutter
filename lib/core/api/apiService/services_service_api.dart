/// All `services-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin ServicesServiceApi {
  final String createService = "services-service/services";
  final String businessServices = 'services-service/services';
  String businessServicesByUserId(String userId) =>
      'services-service/services/user/$userId';
  final String serviceExistsStatus = "services-service/services/exists";
  final String serviceExistenceStatus =
      "services-service/services/all/check-existence";
  String businessServicesById(String serviceId) =>
      'services-service/services/$serviceId';
}
