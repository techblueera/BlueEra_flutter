import 'package:BlueEra/features/common/Discover/model/favorite_location_model.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';

/// Saves a place to the user's favourites (Home / Office / custom tags), for
/// the transport address screens.
class FavouriteLocationService {
  FavouriteLocationService({FavoriteLocationRepo? repo})
      : _repo = repo ?? FavoriteLocationRepo();

  final FavoriteLocationRepo _repo;

  /// Saves the favourite and returns it as the server stored it. Throws
  /// [FavouriteSaveError] with the server's message when it refuses.
  Future<FavoriteLocation> add({
    required String address,
    required double latitude,
    required double longitude,
    required String tag,
    bool isCustomTag = false,
  }) async {
    final res = await _repo.addFavoriteLocation(
      address: address,
      latitude: latitude,
      longitude: longitude,
      tag: tag,
    );
    if (!res.isSuccess) throw FavouriteSaveError(res.message);
    final data = res.response?.data;
    FavoriteLocation? created;
    if (data is Map) {
      // Server may return either the FavoriteLocation directly or
      // nested under a 'favorite' key.
      final raw = data.containsKey('_id') || data.containsKey('id')
          ? data
          : (data['favorite'] as Map?);
      if (raw != null) {
        created = FavoriteLocation.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    // Fall back to a locally-built model so a list can update immediately
    // even if the server response shape differs.
    return created ??
        FavoriteLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          address: address,
          latitude: latitude,
          longitude: longitude,
          tag: tag,
          isCustomTag: isCustomTag,
        );
  }
}

/// A favourite the server refused to save; [message] is its reason, if any.
class FavouriteSaveError implements Exception {
  FavouriteSaveError(this.message);

  final String? message;
}
