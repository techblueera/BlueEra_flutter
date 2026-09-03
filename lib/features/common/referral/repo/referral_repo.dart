import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';

/// Repository for the new BDM/referral flow.
///
/// Real endpoints (status, suggestions, stats, history, register step 2,
/// admin posts) are issued either through [UserRepo] (legacy paths the
/// rest of the app already calls) or via [ApiBaseHelper] directly for
/// new endpoints. The only stub left is the social-link metadata fetch
/// used by the Post tab — replace the body of [fetchLinkMetadata] with
/// a live call when the backend ships.
class ReferralRepoNew extends BaseService {
  final UserRepo _userRepo = UserRepo();

  // ---------------------------------------------------------------------------
  // Live endpoints (proxied to UserRepo)
  // ---------------------------------------------------------------------------

  Future<ResponseModel> getWalletReferralStats() =>
      _userRepo.getWalletReferralStatsRepo();

  Future<ResponseModel> getWalletReferralHistory({
    Map<String, dynamic>? queryParams,
  }) =>
      _userRepo.getWalletReferralHistoryRepo(queryParms: queryParams);

  Future<ResponseModel> getDirectReferralIncome({
    Map<String, dynamic>? queryParams,
  }) =>
      _userRepo.getDirectReferralIncomeRepo(queryParms: queryParams);

  Future<ResponseModel> getReferralSuggestions() =>
      _userRepo.referralSuggestionsRepo();

  /// `PUT wallet-service/wallet/referral` — updates the signed-in user's
  /// referral code. Body: `{ "referralCode": "<code>" }`. The backend
  /// only accepts this while the profile's `referralCodeEditable` flag
  /// is true.
  Future<ResponseModel> updateReferralCode(String referralCode) {
    return ApiBaseHelper().putHTTP(
      walletReferralUpdate,
      params: {'referralCode': referralCode},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /earn-service/overview?page=&limit=` — referral overview posts
  /// (title, description, images[] and/or a video).
  Future<ResponseModel> getOverviews({int page = 1, int limit = 50}) {
    return ApiBaseHelper().getHTTP(
      earnOverview,
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /earn-service/testimonial?page=&limit=` — referral testimonials.
  /// Response: `{ testimonials: [...], currentPage, totalPages,
  /// totalTestimonials }`; each testimonial has title, description and either
  /// `images[]` or a `video`.
  Future<ResponseModel> getTestimonials({int page = 1, int limit = 50}) {
    return ApiBaseHelper().getHTTP(
      earnTestimonials,
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /earn-service/tutorial?page=&limit=` — referral tutorials (title,
  /// description, images[] and/or a video).
  Future<ResponseModel> getTutorials({int page = 1, int limit = 50}) {
    return ApiBaseHelper().getHTTP(
      earnTutorials,
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /earn-service/creator` — content-creator program + progress + the
  /// user's submitted videos (`{ program, progress, videos: [...] }`).
  Future<ResponseModel> getCreator() {
    return ApiBaseHelper().getHTTP(
      earnCreator,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST /earn-service/creator` — submits a creator video link. The backend
  /// scrapes the URL's metadata and adds it to the user's `videos` list.
  /// [platform] is one of youtube / instagram / facebook / twitter / other.
  Future<ResponseModel> createCreatorVideo({
    required String url,
    required String platform,
  }) {
    return ApiBaseHelper().postHTTP(
      earnCreatorVideos,
      params: {'url': url, 'platform': platform},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ---------------------------------------------------------------------------
  // Dummy — link metadata for the Post tab (backend not shipped yet)
  // ---------------------------------------------------------------------------

  /// Resolves a pasted Instagram / Twitter / YouTube URL into a preview
  /// payload. Backend will eventually scrape the URL and return the
  /// canonical stream + metadata — for now we hand back a stub keyed on
  /// platform inferred from the URL string.
  Future<Map<String, dynamic>> fetchLinkMetadata(String url) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final platform = detectPlatform(url);
    final title = switch (platform) {
      'instagram' => 'Instagram reel preview',
      'youtube' => 'YouTube video preview',
      'twitter' => 'Twitter post preview',
      'facebook' => 'Facebook post preview',
      _ => 'Link preview',
    };
    return {
      'url': url,
      'platform': platform,
      'title': title,
      'description':
          'Preview details will load once the link is verified.',
      'thumbnail':
          'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=600',
      'videoUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'authorName': 'BlueEra Demo',
    };
  }

  static String detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('instagram.com')) return 'instagram';
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'youtube';
    }
    if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return 'twitter';
    }
    if (lower.contains('facebook.com') ||
        lower.contains('fb.watch') ||
        lower.contains('fb.com') ||
        lower.contains('fb.me')) {
      return 'facebook';
    }
    // Everything else is accepted as a generic "other" link.
    return 'other';
  }

  /// Share-sheet entries to drop before scraping. A browser's URL bar
  /// hands over a clean canonical address, but the OS share sheet glues
  /// on share-tracking tokens (YouTube `si`, Instagram `igsh`, X `t`/`s`)
  /// and sometimes wraps the URL in title text — both of which make the
  /// backend's `open-graph-scraper` / `youtubei.js` resolve a consent or
  /// redirect page instead of the real video, so the metadata comes back
  /// empty. We strip these here so "copied from share" behaves like
  /// "copied from browser".
  static const _trackingParams = <String>{
    'si', 'feature', 'pp', 'app', 'source',
    'igsh', 'igshid',
    's', 't', 'ref', 'ref_src', 'ref_url',
    'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
    'fbclid', 'gclid',
  };

  /// Pulls the first URL out of arbitrary pasted/shared text and rewrites
  /// it to the canonical, tracking-free form the backend scraper can
  /// resolve. Safe to call on an already-clean browser URL — it returns
  /// the same address minus tracking params. Falls back to the trimmed
  /// input if nothing parses.
  static String canonicalizeSharedUrl(String raw) {
    // 1. Extract the first http(s) URL — share text is often
    //    "<title> <url> via <app>" rather than a bare address.
    final match = RegExp(r'https?://[^\s]+').firstMatch(raw.trim());
    var urlStr = (match?.group(0) ?? raw).trim();
    // Drop trailing punctuation/brackets the share text may append.
    urlStr = urlStr.replaceAll(RegExp(r'''[)\]}>,.;'"\s]+$'''), '');

    final uri = Uri.tryParse(urlStr);
    if (uri == null || !uri.hasScheme) return urlStr;

    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final qp = Map<String, String>.from(uri.queryParameters);

    // 2. YouTube → canonical watch URL keyed on the video id. youtubei.js
    //    needs the bare id; `youtu.be/<id>` and `/shorts/<id>` confuse it.
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return _youtubeWatchUrl(id, qp['t']);
    }
    if (host.endsWith('youtube.com')) {
      var id = qp['v'];
      if ((id == null || id.isEmpty) && uri.pathSegments.length >= 2) {
        final first = uri.pathSegments.first;
        if (first == 'shorts' || first == 'embed' || first == 'live') {
          id = uri.pathSegments[1];
        }
      }
      if (id != null && id.isNotEmpty) return _youtubeWatchUrl(id, qp['t']);
    }

    // 3. X / Twitter → trim to the canonical /<user>/status/<id>. Share
    //    links append /photo/1, /video/1 or /analytics segments plus
    //    t/s tokens; the backend resolves the tweet by id, so anything
    //    past the id is noise that can break the scrape.
    if (host == 'x.com' ||
        host == 'twitter.com' ||
        host == 'mobile.twitter.com' ||
        host == 'mobile.x.com') {
      final segs = uri.pathSegments;
      final statusIdx = segs.indexOf('status');
      final canonicalHost =
          host.startsWith('mobile.') ? host.substring(7) : host;
      if (statusIdx >= 0 && statusIdx + 1 < segs.length) {
        // Keep everything up to and including the id (handles both
        // `/user/status/<id>` and `/i/web/status/<id>`), drop the rest.
        final kept = segs.sublist(0, statusIdx + 2).join('/');
        return 'https://$canonicalHost/$kept';
      }
    }

    // 4. Instagram / other — keep the path, drop only tracking params.
    qp.removeWhere((k, _) => _trackingParams.contains(k.toLowerCase()));
    return uri
        .replace(queryParameters: qp.isEmpty ? null : qp)
        .toString();
  }

  static String _youtubeWatchUrl(String id, String? startSeconds) {
    if (id.isEmpty) return 'https://www.youtube.com/';
    final base = 'https://www.youtube.com/watch?v=$id';
    return (startSeconds != null && startSeconds.isNotEmpty)
        ? '$base&t=$startSeconds'
        : base;
  }
}
