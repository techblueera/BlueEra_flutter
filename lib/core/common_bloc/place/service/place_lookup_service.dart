import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:flutter/foundation.dart';

/// Place autocomplete and coordinate lookup for address fields that have no
/// controller of their own (bottom sheets).
///
/// Both halves go through [PlaceRepo]'s session caches: autocomplete per
/// query, and [PlaceRepo.resolvePlace] per `place_id`, so a place resolved on
/// one screen is free on the next (docs/GOOGLE_MAPS_COST_GUIDE.md §3.1).
class PlaceLookupService {
  PlaceLookupService({PlaceRepo? repo}) : _repo = repo ?? PlaceRepo();

  final PlaceRepo _repo;

  /// Predictions for [query]; empty for a blank query or a failed lookup.
  Future<List<PlacePrediction>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final response = await _repo.autoCompleteSearch(query: query);
      if (response.statusCode != 200) return const [];
      final list = response.response?.data?['predictions'] as List? ?? [];
      return PlacePrediction.fromList(list);
    } catch (_) {
      return const [];
    }
  }

  /// Coordinates for a tapped prediction, or null when it can't be resolved.
  Future<ResolvedPlace?> resolve(String? placeId) =>
      _repo.resolvePlace(placeId);

  /// Like [search], for fields that show why a search failed: the
  /// predictions, or Places' `error_message` when it answered with an error.
  ///
  /// Transport failures (timeouts, no connection) are left to the caller,
  /// which words them for its own field.
  Future<({List<PlacePrediction> predictions, String? error})> searchDetailed(
      String query) async {
    final response = await _repo.autoCompleteSearch(query: query);
    if (response.statusCode != 200) {
      // Top-level key: the Places envelope has no `data` wrapper.
      return (
        predictions: const <PlacePrediction>[],
        error: (response.getExtraData('error_message') as String?) ??
            'Something went wrong',
      );
    }
    final list = response.getExtraData('predictions') as List? ?? const [];
    // Parsed off the UI isolate so a long list doesn't drop a frame.
    return (
      predictions: await compute(PlacePrediction.fromList, list),
      error: null,
    );
  }

  /// The full Place Details body for [placeId] (cached per session by
  /// [PlaceRepo]), for hosts that read more than coordinates. Null when the
  /// response had no body; transport failures are left to the caller.
  Future<Map<String, dynamic>?> details(String placeId) async {
    final body =
        (await _repo.getCompletePlaceDetails(placeId: placeId)).response?.data;
    return body is Map ? Map<String, dynamic>.from(body) : null;
  }

  /// The coordinates in a [details] body, or null when it carries none.
  static ({double lat, double lng})? coordinatesIn(
      Map<String, dynamic>? details) {
    final loc = details?['result']?['geometry']?['location'];
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lng = (loc?['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : (lat: lat, lng: lng);
  }
}
