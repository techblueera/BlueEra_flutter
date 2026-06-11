import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when Serper rejects a request because the plan credits / rate limit
/// are exhausted, so callers can show a friendlier message than "no results".
class SerperImageQuotaException implements Exception {
  final String message;
  const SerperImageQuotaException([
    this.message = 'Daily image-search limit reached. Please try again later.',
  ]);

  @override
  String toString() => message;
}

/// Thrown when Serper rejects the request for a configuration reason (bad /
/// missing API key, plan disabled), so callers can show a clearer message than
/// a silent empty result.
class SerperImageUnavailableException implements Exception {
  final String message;
  const SerperImageUnavailableException([
    this.message = 'Image search is currently unavailable. Please try again later.',
  ]);

  @override
  String toString() => message;
}

/// Fetches product images from **Serper.dev** (https://serper.dev) — a Google
/// Search API — by name/brand, so the add-product flow can pull a photo without
/// the user having to shoot or upload one.
///
/// Calls `POST https://google.serper.dev/images` with an `X-API-KEY` header and
/// `{ "q": "<name/brand>" }` body; reads image URLs from `images[].imageUrl`.
///
/// The API key is NOT bundled in the app — it's fetched at runtime from
/// `product-service/api/products/fe/ai-keys` and supplied via [configure].
/// When the key is missing, [isConfigured] is false and [search] returns an
/// empty list.
class SerperImageSearchService {
  SerperImageSearchService._();

  static const String _endpoint = 'https://google.serper.dev/images';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Runtime-supplied key (from the ai-keys endpoint). Empty until configured.
  static String _apiKey = '';

  /// Stores the Serper API key fetched from the backend so [search] can
  /// authenticate. Safe to call repeatedly; ignores blank values so a failed
  /// refresh can't wipe a previously-working config.
  static void configure({String? apiKey}) {
    if (apiKey != null && apiKey.trim().isNotEmpty) _apiKey = apiKey.trim();
  }

  /// True only when the API key is present.
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Per-query result cache (session-lived). Keyed by the normalised query so
  /// re-searching the same name/brand doesn't spend another API call.
  static final Map<String, List<String>> _cache = {};

  /// Returns up to [count] image URLs for [query]. Empty on misconfiguration,
  /// no results, or any non-quota network/parse error (those are logged).
  /// Throws [SerperImageQuotaException] when credits/rate are exhausted, and
  /// [SerperImageUnavailableException] on an auth/config rejection.
  static Future<List<String>> search(String query, {int count = 12}) async {
    final q = query.trim();
    if (q.isEmpty || !isConfigured) return const [];

    final key = q.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final response = await _dio.post(
        _endpoint,
        data: {
          'q': q,
          'num': count.clamp(1, 100),
        },
        options: Options(
          headers: {
            'X-API-KEY': _apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data;
      final images = (data is Map && data['images'] is List)
          ? data['images'] as List
          : const [];
      final urls = images
          .map((e) => (e is Map
                  ? (e['imageUrl'] ?? e['image'] ?? e['link'])?.toString()
                  : null) ??
              '')
          .where((url) => url.isNotEmpty)
          .toList();
      _cache[key] = urls; // cache success (incl. genuine empty) to save credits
      return urls;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 429 → rate/credit limit; 401/403 → bad/disabled key.
      if (status == 429) {
        throw const SerperImageQuotaException();
      }
      debugPrint('SerperImageSearchService.search error: $e');
      debugPrint(
          'SerperImageSearchService.search response -> '
          'status=$status body=${e.response?.data}');
      if (status == 401 || status == 403) {
        throw const SerperImageUnavailableException();
      }
      return const [];
    } catch (e) {
      debugPrint('SerperImageSearchService.search error: $e');
      return const [];
    }
  }

  /// Downloads [url] into the temp directory and returns the saved file path,
  /// or null on failure. The path can be fed straight into image flows that
  /// expect a local file.
  static Future<String?> downloadToTemp(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/serper_img_$stamp.jpg';
      await _dio.download(url, path);
      final file = File(path);
      if (await file.exists() && await file.length() > 0) return path;
      return null;
    } catch (e) {
      debugPrint('SerperImageSearchService.downloadToTemp error: $e');
      return null;
    }
  }
}
