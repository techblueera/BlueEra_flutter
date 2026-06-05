import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when the Custom Search API rejects a request because the daily/rate
/// quota is exhausted, so callers can show a friendlier message than a generic
/// "no results".
class GoogleImageQuotaException implements Exception {
  final String message;
  const GoogleImageQuotaException([
    this.message = 'Daily image-search limit reached. Please try again later.',
  ]);

  @override
  String toString() => message;
}

/// Fetches product images from Google's Programmable Search (Custom Search
/// JSON API) by name/brand, so the add-product flow can pull a photo without
/// the user having to shoot or upload one.
///
/// Requires `GOOGLE_CSE_API_KEY` (a Google API key with the "Custom Search
/// API" enabled) and `GOOGLE_CSE_CX` (the search-engine id, image search on)
/// in `.env`. When either is missing, [isConfigured] is false and [search]
/// returns an empty list.
class GoogleImageSearchService {
  GoogleImageSearchService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static String get _apiKey => Env.googleCseApiKey ?? '';
  static String get _cx => Env.googleCseCx ?? '';

  /// True only when both the API key and search-engine id are present.
  static bool get isConfigured => _apiKey.isNotEmpty && _cx.isNotEmpty;

  /// Per-query result cache (session-lived). Keyed by the normalised query so
  /// re-searching the same name/brand doesn't spend another API call against
  /// the limited daily quota.
  static final Map<String, List<String>> _cache = {};

  /// Returns up to [count] image URLs for [query]. Empty on misconfiguration,
  /// no results, or any non-quota network/parse error (those are logged).
  /// Throws [GoogleImageQuotaException] when the API quota is exhausted.
  static Future<List<String>> search(String query, {int count = 10}) async {
    final q = query.trim();
    if (q.isEmpty || !isConfigured) return const [];

    final key = q.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        'https://www.googleapis.com/customsearch/v1',
        queryParameters: {
          'key': _apiKey,
          'cx': _cx,
          'q': q,
          'searchType': 'image',
          'num': count.clamp(1, 10),
          'safe': 'active',
        },
      );
      final data = response.data;
      final items = (data is Map && data['items'] is List)
          ? data['items'] as List
          : const [];
      final urls = items
          .map((e) => (e is Map ? e['link']?.toString() : null) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
      _cache[key] = urls; // cache success (incl. genuine empty) to save quota
      return urls;
    } on DioException catch (e) {
      if (_isQuotaError(e.response)) {
        throw const GoogleImageQuotaException();
      }
      debugPrint('GoogleImageSearchService.search error: $e');
      return const [];
    } catch (e) {
      debugPrint('GoogleImageSearchService.search error: $e');
      return const [];
    }
  }

  /// Detects a quota/rate-limit rejection from the Custom Search error body.
  /// 429 is always quota; 403 only when the error reason says so.
  static bool _isQuotaError(Response? response) {
    final status = response?.statusCode;
    if (status == 429) return true;
    if (status != 403) return false;

    final data = response?.data;
    if (data is! Map || data['error'] is! Map) return false;
    final error = data['error'] as Map;

    if (error['status']?.toString() == 'RESOURCE_EXHAUSTED') return true;
    final errors = error['errors'];
    if (errors is List) {
      for (final e in errors) {
        final reason = e is Map ? e['reason']?.toString() : null;
        if (reason == 'dailyLimitExceeded' ||
            reason == 'rateLimitExceeded' ||
            reason == 'quotaExceeded') {
          return true;
        }
      }
    }
    return false;
  }

  /// Downloads [url] into the temp directory and returns the saved file path,
  /// or null on failure. The path can be fed straight into image flows that
  /// expect a local file.
  static Future<String?> downloadToTemp(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/google_img_$stamp.jpg';
      await _dio.download(url, path);
      final file = File(path);
      if (await file.exists() && await file.length() > 0) return path;
      return null;
    } catch (e) {
      debugPrint('GoogleImageSearchService.downloadToTemp error: $e');
      return null;
    }
  }
}
