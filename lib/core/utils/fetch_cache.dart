/// A tiny, reusable freshness guard for "fetch-on-screen-entry" APIs.
///
/// Many screens call the same GET endpoint in `initState`, so navigating back
/// and re-entering refetches identical data even though the (persistent) GetX
/// controller still holds it. Wrap such a fetch with a [FetchCache] to skip the
/// network call when the data is already loaded for the *same request* and was
/// fetched within [ttl] (stale-while-revalidate style).
///
/// The cache is keyed by an arbitrary `signature` string that the caller builds
/// from whatever makes the request unique — e.g. business type + category +
/// location, or a user id. This matters when one controller/list is shared by
/// several screens (stores, grocery, food, products, services): each screen
/// passes its own signature, so it only ever reuses data that actually matches
/// its request, and never another screen's leftovers.
///
/// Usage:
/// ```dart
/// final _cache = FetchCache();
/// String get _signature => 'stores|$type|$category|$lat|$lng';
///
/// Future<void> loadIfNeeded() async {
///   if (_cache.isFresh(_signature, hasData: list.isNotEmpty)) return;
///   await load();
/// }
///
/// Future<void> load() async {
///   // ... on success, after the list is populated:
///   _cache.mark(_signature);
/// }
/// ```
class FetchCache {
  FetchCache({this.ttl = const Duration(minutes: 5)});

  /// How long a successful fetch stays "fresh" before a re-entry refetches.
  final Duration ttl;

  String? _signature;
  DateTime? _fetchedAt;

  /// Whether a refetch can be skipped: there is data on screen, the last
  /// successful fetch was for the *same* [signature], and it is within [ttl].
  bool isFresh(String signature, {required bool hasData}) {
    if (!hasData) return false;
    final at = _fetchedAt;
    if (at == null || _signature != signature) return false;
    return DateTime.now().difference(at) < ttl;
  }

  /// Record a successful fetch for [signature]. Call this only after the data
  /// has actually been written into the controller's list/model. Any code that
  /// overwrites a *shared* list must call this with its own signature so the
  /// next reader can tell whose data is currently loaded.
  void mark(String signature) {
    _signature = signature;
    _fetchedAt = DateTime.now();
  }

  /// Force the next [isFresh] check to fail (e.g. after a mutation that the
  /// server now knows about and a re-entry should reflect).
  void invalidate() {
    _signature = null;
    _fetchedAt = null;
  }
}
