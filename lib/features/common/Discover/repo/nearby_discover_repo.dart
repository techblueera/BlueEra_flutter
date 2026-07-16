import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Nearby discover — `GET map-service/api/nearby/discover`.
/// See docs/backend/nearby-discover-integration.md.
class NearbyDiscoverRepo extends BaseService {
  /// The request uses **`lng`** (not `lon`); response locations use `lon`.
  /// `per_category`/`per_profession` are clamped server-side (max 3).
  Future<ResponseModel> getNearbyDiscover({
    required double lat,
    required double lng,
    double radius = 5,
    String? types, // e.g. "Grocery" — omit for all three
    int perCategory = 3,
  }) async {
    return await ApiBaseHelper().getHTTP(
      nearbyDiscover,
      params: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (types != null && types.isNotEmpty) 'types': types,
        'per_category': perCategory,
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}
