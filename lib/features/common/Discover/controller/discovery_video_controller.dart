import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:get/get.dart';

/// Holds the Discover intro clip's URL for the guest header banner.
///
/// Fetched once per app run and cached in memory: the clip is a fixed
/// marketing asset, the banner is rebuilt on every Discover repaint, and
/// re-requesting it on each of those would be a request per scroll.
///
/// [videoUrl] stays null until the fetch succeeds, so the banner simply shows
/// its existing slides until the clip arrives and never has a hole where the
/// video will be.
class DiscoveryVideoController extends GetxController {
  /// Injectable so the parsing rules can be tested without a network stack.
  /// Production callers use the default.
  DiscoveryVideoController({DiscoverRepo? repo}) : _repo = repo ?? DiscoverRepo();

  final DiscoverRepo _repo;

  /// The clip's URL, or null while loading / when there is none.
  final Rxn<String> videoUrl = Rxn<String>();

  /// The clip's own first frame, served by the backend — null when it doesn't
  /// send one, which is the case this stays dormant for.
  ///
  /// It is worth having only because it can be on screen BEFORE the player
  /// can paint: it is one small image against a video that has to open a
  /// connection, buffer and decode. Generating a frame on the device instead
  /// (the bundled `get_thumbnail_video`) would mean downloading the video to
  /// find out what its first frame is — the very wait this covers — so it
  /// would arrive after the clip could have started, not before.
  ///
  /// Never the last line of defence: whatever fails the clip (no network, a
  /// dead host) usually fails this too, so callers still end at bundled
  /// artwork.
  final Rxn<String> thumbnailUrl = Rxn<String>();

  /// First of [keys] that holds a usable URL. The endpoint's exact spelling
  /// isn't pinned down here, and a key that isn't there simply reads as null —
  /// the same as a backend that sends no thumbnail at all.
  static String? _firstUrl(dynamic data, List<String> keys) {
    if (data is! Map) return null;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Guards against the concurrent fetches a rebuilding banner would otherwise
  /// fire, and against re-fetching after a failure on every repaint. A retry
  /// still happens on the next app run.
  bool _attempted = false;

  /// Fetches the clip once. Safe to call from `build` — subsequent calls are
  /// no-ops.
  Future<void> ensureLoaded() async {
    if (_attempted) return;
    _attempted = true;

    try {
      final response = await _repo.fetchDiscoveryVideo();
      if (!response.isSuccess) return;

      final data = response.data;
      final url = (data is Map) ? data['video_url'] : null;
      if (url is String && url.trim().isNotEmpty) {
        videoUrl.value = url.trim();
      }
      thumbnailUrl.value = _firstUrl(data, const [
        'thumbnail_url',
        'thumbnail',
        'thumb_url',
        'poster_url',
        'poster',
      ]);
    } catch (e) {
      // A missing promo clip is not worth surfacing — the banner carries its
      // bundled slides regardless.
      logs('discovery video fetch failed: $e');
    }
  }
}
