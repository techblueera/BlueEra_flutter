import 'package:BlueEra/core/map/osm_config.dart';
import 'package:dio/dio.dart';

/// The HTTP client used for every OSM service call — and **deliberately not**
/// [ApiBaseHelper].
///
/// ## Why this is separate
///
/// `ApiBaseHelper`'s Dio carries `Authorization: Bearer $authTokenGlobal` on
/// every request, because every request it was built for goes to our own
/// backend. The Google map calls it used to make went to `maps.googleapis.com`
/// wearing that header — a BlueEra session token handed to a third party on
/// every address keystroke.
///
/// That was survivable when the third party was Google. It is not something to
/// carry forward to a community-run geocoder that anyone can operate, so OSM
/// traffic gets its own client with **no app credentials on it at all**.
///
/// It also means a slow or wedged geocoder can never occupy a connection in the
/// pool the rest of the app depends on, and that the global progress dialog and
/// 401-triggered logout — both wired into `ApiBaseHelper`'s interceptors — can
/// never be triggered by a map lookup. A failed address search should show "no
/// results", not sign the user out.
class OsmHttpClient {
  const OsmHttpClient._();

  static Dio? _dio;

  /// Timeouts are short on purpose. These calls sit directly under a typing
  /// user or a moving map; a geocoder that has not answered in a few seconds
  /// has missed its moment, and holding the request open only delays the
  /// fallback path.
  static Dio get instance => _dio ??= Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          responseType: ResponseType.json,
          headers: {
            // Nominatim rejects requests without a meaningful User-Agent, and
            // the OSM tile policy requires one. See OsmConfig.userAgent.
            'User-Agent': OsmConfig.userAgent,
            'Accept': 'application/json',
          },
          // Any 2xx is a result; everything else is handled as a null return by
          // the callers rather than as a thrown exception, so validateStatus
          // stays permissive and the services decide.
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  /// Query parameters plus the provider key, when one is configured. Public
  /// servers take no key, so this is usually a no-op.
  static Map<String, dynamic> withKey(Map<String, dynamic> params) {
    final key = OsmConfig.apiKey;
    if (key == null || key.isEmpty) return params;
    return {...params, 'api_key': key};
  }

  /// Drops the cached client so the next call picks up a changed
  /// [OsmConfig.userAgent] or host. Only needed if config changes after
  /// start-up, which it normally does not.
  static void reset() {
    _dio?.close(force: true);
    _dio = null;
  }
}
