import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/search/model/search_category.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';

/// Repository for the global hybrid search service.
///
/// Endpoints live under `search-service/*` on the shared API gateway
/// (`https://be.beapp.in/api/`), so they route through the app's usual
/// [ApiBaseHelper] — same interceptors, auth headers and logging as every
/// other service. Progress dialog is suppressed on all calls; the search
/// screen renders its own inline loaders.
///
/// TWO routes, not one per vertical: `/search` scoped by [SearchCategory], and
/// the unscoped `/suggest`. The old per-vertical paths (`/search/content`,
/// `/search/grocery`, `/search/shops`) were retired and now `404`.
///
/// See `docs/SEARCH_API_INTEGRATION.md`.
class SearchRepo {
  static const String _searchPath = 'search-service/search';
  static const String _suggestPath = 'search-service/suggest';

  /// Full hybrid search.
  ///
  /// [category] fixes the vertical server-side — see [SearchCategory]. Null or
  /// [SearchCategory.all] searches everything, which is what the global search
  /// bar has always done. A category cannot leak: scoping to `grocery` can
  /// never return a video no matter what else is in the query.
  ///
  /// [type] narrows *within* that category and may be a comma-separated list.
  /// It must be legal for the category or the API answers `400` — see the
  /// per-category table in `docs/SEARCH_API_INTEGRATION.md` §2.
  ///
  /// Throws (via [ApiBaseHelper.handleError]) on network failure — callers
  /// wrap in try/catch.
  /// [lat]/[lng] are the searcher's position and give every located row an
  /// `address` + `distanceMeters`/`distanceText`. They are sent **both or
  /// neither** — one alone is a `400`, and so is `0,0` (what an unset location
  /// object usually serialises to), hence [_geoParams].
  Future<SearchResponse> search(
    String q, {
    SearchCategory? category,
    String? type,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
  }) async {
    final ResponseModel res = await ApiBaseHelper().getHTTP(
      _searchPath,
      showProgress: false,
      params: {
        'q': q,
        // Omitted for `all` — that's the server default, and leaving it off
        // keeps this identical to the request shape the global search bar has
        // always sent.
        if (category != null && category != SearchCategory.all)
          'category': category.value,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'limit': limit,
        ..._geoParams(lat, lng),
      },
      onError: (_) {},
      onSuccess: (_) {},
    );

    // The search service returns fields at the top level (no `data` envelope),
    // so parse from the raw response map rather than ResponseModel.data.
    final raw = res.response?.data;
    if (res.isSuccess && raw is Map) {
      return SearchResponse.fromJson(Map<String, dynamic>.from(raw));
    }
    throw (raw is Map ? raw['message'] : null) ?? 'search failed';
  }

  /// Content-only search — posts and videos, never catalogue entities.
  ///
  /// The scope is fixed server-side, so no query parameter can widen it to
  /// products/groceries/hospitals. [type] narrows further to a single kind and
  /// accepts `post` or `video` only (anything else is a 400); omit it for both.
  ///
  /// Now a scoped [search] rather than its own route: `/search/content` was
  /// retired and returns `404` — see the migration table at the bottom of
  /// `docs/SEARCH_API_INTEGRATION.md`. Same request shape otherwise, same
  /// response, so callers are unaffected.
  Future<SearchResponse> searchContent(
    String q, {
    String? type,
    int page = 1,
    int limit = 20,
  }) {
    return search(
      q,
      category: SearchCategory.content,
      type: type,
      page: page,
      limit: limit,
    );
  }

  /// Coordinates for a search/suggest request, or an empty map when they can't
  /// legally be sent. The API rejects a lone `lat`, a lone `lng` and `0,0`
  /// outright, so a half-known position is dropped rather than half-sent.
  Map<String, dynamic> _geoParams(double? lat, double? lng) {
    if (lat == null || lng == null) return const {};
    if (lat == 0 && lng == 0) return const {};
    if (lat.abs() > 90 || lng.abs() > 180) return const {};
    return {'lat': lat, 'lng': lng};
  }

  /// Type-ahead suggestions (call while typing, debounced). Empty query short
  /// circuits to an empty list without a network call.
  ///
  /// [category] scopes the dropdown exactly like it scopes [search], and a
  /// scoped screen MUST pass its own rather than filter the response: the row
  /// cap is applied inside the query, so asking for 8 unscoped rows and
  /// discarding the off-vertical ones can leave a near-empty panel. Omitted for
  /// [SearchCategory.all] — the server default.
  ///
  /// `type` is not accepted here — an 8-row dropdown has no sub-filter.
  /// [lat]/[lng] follow the same both-or-neither rule as [search].
  Future<List<Suggestion>> suggest(
    String q, {
    SearchCategory? category,
    int limit = 8,
    double? lat,
    double? lng,
  }) async {
    if (q.trim().isEmpty) return [];
    final ResponseModel res = await ApiBaseHelper().getHTTP(
      _suggestPath,
      showProgress: false,
      params: {
        'q': q,
        if (category != null && category != SearchCategory.all)
          'category': category.value,
        'limit': limit,
        ..._geoParams(lat, lng),
      },
      onError: (_) {},
      onSuccess: (_) {},
    );
    final raw = res.response?.data;
    if (res.isSuccess && raw is Map) {
      final list = (raw['suggestions'] as List?) ?? const [];
      return list
          .map((e) => Suggestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }
}
