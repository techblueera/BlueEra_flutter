/// All `health-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `enableHotelServiceStatus` is named after hotels but actually
/// targets `health-service/api/hp/categories/...`. Likely a misnamed
/// constant — preserved here as-is for the refactor.
mixin HealthServiceApi {
  String enableHotelServiceStatus(String categoryId) =>
      'health-service/api/hp/categories/$categoryId/status';
  final String healthAndServiceImageUpload = 'health-service/api/upload/init';
}
