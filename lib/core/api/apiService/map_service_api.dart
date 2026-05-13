/// All `map-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin MapServiceApi {
  String getJobByLat(String lat, lng) =>
      "map-service/api/jobs?lat=$lat&lng=$lng&radius=25";
  String getStoreByLat(String lat, lng) =>
      "map-service/api/stores?lat=$lat&lng=$lng&radius=25";
  String getPlaceById(String placeId) => "map-service/api/places/$placeId";
  String getStoreById(String storeId) => "map-service/api/stores/$storeId";
  String getPlaceByLat(double lat, double lng) =>
      "map-service/api/places?lat=$lat&lng=$lng&radius=25";
  // final String servicesByLatLng = "map-service/api/services/live";
  // final String servicesByLatLng = "map-service/api/services";
  final String foodServicesByLatLng = "map-service/api/services/food-services";
  String getServiceProfileByUserId(String userId) =>
      "map-service/services/$userId";
  final String storesByLatLng = "map-service/stores";
  String getStoresDetailsByStoreId(String storeId) =>
      "map-service/stores/$storeId";
  final String getStoreListing = "map-service/api/stores";
  final String storesFeed = "map-service/api/feed";
  final String mapServiceProviderStatus = "map-service/api/provider/status";
  final String mapServiceLocationProvider = "map-service/api/provider/location";
  final String storesByCategory = 'map-service/api/stores/inventory/category';
  final String updateLiveLocation = 'map-service/api/provider/location';
}
