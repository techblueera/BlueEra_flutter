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
    } catch (e) {
      // A missing promo clip is not worth surfacing — the banner carries its
      // bundled slides regardless.
      logs('discovery video fetch failed: $e');
    }
  }
}
