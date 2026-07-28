import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';

/// Repository for the global hybrid search service.
///
/// Endpoints live under `search-service/*` on the shared API gateway
/// (`https://be.beapp.in/api/`), so they route through the app's usual
/// [ApiBaseHelper] — same interceptors, auth headers and logging as every
/// other service. Progress dialog is suppressed on all calls; the search
/// screen renders its own inline loaders.
///
/// See docs/backend/FLUTTER_INTEGRATION_SEARCH.md.
class SearchRepo {
  static const String _searchPath = 'search-service/search';
  static const String _contentPath = 'search-service/search/content';
  static const String _suggestPath = 'search-service/suggest';

  /// Full hybrid search. [type] scopes to a single entityType (optional).
  /// Throws (via [ApiBaseHelper.handleError]) on network failure — callers
  /// wrap in try/catch.
  Future<SearchResponse> search(
    String q, {
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final ResponseModel res = await ApiBaseHelper().getHTTP(
      _searchPath,
      showProgress: false,
      params: {
        'q': q,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'limit': limit,
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
  /// Separate endpoint from [search]: the scope is fixed server-side, so no
  /// query parameter can widen it to products/groceries/hospitals. [type]
  /// narrows further to a single kind and accepts `post` or `video` only
  /// (anything else is a 400); omit it for both.
  ///
  /// See docs/backend/CONTENT_SEARCH_INTEGRATION.md.
  Future<SearchResponse> searchContent(
    String q, {
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final ResponseModel res = await ApiBaseHelper().getHTTP(
      _contentPath,
      showProgress: false,
      params: {
        'q': q,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'limit': limit,
      },
      onError: (_) {},
      onSuccess: (_) {},
    );

    // Same envelope-less shape as [search] — fields sit at the top level.
    final raw = res.response?.data;
    if (res.isSuccess && raw is Map) {
      return SearchResponse.fromJson(Map<String, dynamic>.from(raw));
    }
    throw (raw is Map ? raw['message'] : null) ?? 'search failed';
  }

  /// Type-ahead suggestions (call while typing, debounced). Empty query short
  /// circuits to an empty list without a network call.
  Future<List<Suggestion>> suggest(String q, {int limit = 8}) async {
    if (q.trim().isEmpty) return [];
    final ResponseModel res = await ApiBaseHelper().getHTTP(
      _suggestPath,
      showProgress: false,
      params: {'q': q, 'limit': limit},
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
