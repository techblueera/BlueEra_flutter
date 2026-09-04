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
    int perSection = 10,
  }) async {
    return await ApiBaseHelper().getHTTP(
      nearbyDiscover,
      params: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (types != null && types.isNotEmpty) 'types': types,
        'per_category': perCategory,
        // The SECTIONED response (`shops_near_me` / `services_near_me` /
        // `recent_visited`) sizes itself off this — `meta.per_section` echoes
        // it back. Sent alongside the legacy `per_category` because one
        // endpoint answers both shapes and each ignores the other's knob.
        //
        // 10 rather than 3: the two rails scroll horizontally and
        // "Recent Visited Stores" shows five rows before it defers to
        // "View All", so a per-section cap of 3 would starve both.
        'per_section': perSection,
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}
