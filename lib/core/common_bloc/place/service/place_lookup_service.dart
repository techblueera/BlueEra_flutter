import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';

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
}
