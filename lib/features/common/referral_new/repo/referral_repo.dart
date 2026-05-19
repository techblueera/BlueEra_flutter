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

  Future<ResponseModel> getBdmDetails() => _userRepo.getBdmDetailsRepo();

  Future<ResponseModel> getWalletReferralStats() =>
      _userRepo.getWalletReferralStatsRepo();

  Future<ResponseModel> getWalletReferralHistory({
    Map<String, dynamic>? queryParams,
  }) =>
      _userRepo.getWalletReferralHistoryRepo(queryParms: queryParams);

  Future<ResponseModel> getReferralSuggestions() =>
      _userRepo.referralSuggestionsRepo();

  /// Single-step registration: the UI only collects a referral code.
  /// We still POST to `/bdm/register/step2` because that endpoint is the
  /// status "finish line" — the backend flips status to COMPLETED on
  /// success even without `documents.bankDetails`.
  Future<ResponseModel> registerStepTwo({String? referralCode}) {
    final params = <String, dynamic>{
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    };
    return _userRepo.bdmRegisterStepTwoRepo(params);
  }

  // ---------------------------------------------------------------------------
  // Admin posts — single endpoint, filtered by `type`
  // ---------------------------------------------------------------------------

  /// Hits `GET /earn-service/admin-posts?type=<type>&page=<page>&limit=<limit>`.
  /// Used for the testimonials, overview, tutorial and the user's own
  /// posts (`type=post`) — the caller picks the right `type` string
  /// and maps the response to its view model.
  Future<ResponseModel> getAdminPosts({
    required String type,
    int page = 1,
    int limit = 10,
  }) {
    return ApiBaseHelper().getHTTP(
      adminPosts,
      params: {
        'type': type,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST /earn-service/admin-posts` — creates a new social post from
  /// a pasted URL. The caller passes the detected platform name as
  /// [title] (e.g. `instagram`, `twitter`, `youtube`) and the raw URL
  /// as [link]; the backend resolves the metadata and surfaces the
  /// resulting record under `type=post`.
  Future<ResponseModel> createAdminPost({
    required String link,
    required String title,
  }) {
    return ApiBaseHelper().postHTTP(
      adminPosts,
      params: {'type': 'post', 'link': link, 'title': title},
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
      _ => 'Link preview',
    };
    return {
      'url': url,
      'platform': platform,
      'title': title,
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
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
    return 'unknown';
  }
}
