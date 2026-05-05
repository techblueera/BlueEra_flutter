import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FavoriteLocationRepo extends BaseService {
  /// POST /favorite-locations — save a favourite address for the current user.
  ///
  /// `coordinates` MUST be in `[longitude, latitude]` (GeoJSON) order.
  Future<ResponseModel> addFavoriteLocation({
    required String address,
    required double latitude,
    required double longitude,
    required String tag,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{
      'address': address,
      'tag': tag,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      if (label != null && label.isNotEmpty) 'label': label,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
    return ApiBaseHelper().postHTTP(
      favoriteLocations,
      params: params,
      showProgress: false,
    );
  }

  /// GET /favorite-locations — paginated list of the user's favourites.
  Future<ResponseModel> listFavorites({
    String? tag,
    String? search,
    int page = 1,
    int limit = 50,
  }) {
    return ApiBaseHelper().getHTTP(
      favoriteLocations,
      params: {
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
    );
  }

  /// DELETE /favorite-locations/:id — remove a saved favourite.
  Future<ResponseModel> deleteFavorite(String id) {
    return ApiBaseHelper().deleteHTTP(
      '$favoriteLocations/$id',
      showProgress: false,
    );
  }
}
