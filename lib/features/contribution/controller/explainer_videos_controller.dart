import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:get/get.dart';

/// One explainer video on the Contribution (Account Plans) screen.
///
/// Extracted from the deleted `SecurityDepositVideo`. The security-deposit
/// feature is gone, but these videos are not part of it — they explain the
/// contribution flow and are simply served from a path that still sits under
/// the old namespace. Only `active` videos with a playable URL are surfaced.
class ExplainerVideo {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String mimeType;
  final String status;

  ExplainerVideo.fromJson(Map<String, dynamic> j)
      : id = (j['_id'] ?? '').toString(),
        title = (j['title'] ?? '').toString(),
        description = (j['description'] ?? '').toString(),
        fileUrl = (j['fileUrl'] ?? '').toString(),
        fileName = (j['fileName'] ?? '').toString(),
        mimeType = (j['mimeType'] ?? '').toString(),
        status = (j['status'] ?? '').toString();

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasUrl => fileUrl.isNotEmpty;
}

class ExplainerVideosRepo extends BaseService {
  /// `GET /security-deposit/videos`.
  ///
  /// The PATH keeps the old segment because that is what the server serves —
  /// renaming the Dart constant does not move the endpoint. Only the app-side
  /// naming has been brought in line with what these videos actually are.
  Future<ResponseModel> fetchVideos() =>
      ApiBaseHelper().getHTTP(explainerVideos, showProgress: false);
}

/// The explainer videos at the top of `ContributionScreen`.
///
/// All that survives of `SecurityDepositController`, which was deleted with the
/// rest of the security-deposit feature. That controller was constructed for
/// this one list and nothing else — its catalog, held-deposit status, GST rate
/// and Razorpay checkout were all unread by the time the screen moved to
/// Account Plans.
class ExplainerVideosController extends GetxController {
  final ExplainerVideosRepo _repo = ExplainerVideosRepo();

  final RxList<ExplainerVideo> videos = <ExplainerVideo>[].obs;

  static const String _cacheKey = 'videos';

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  /// Cache-first: once fetched, the raw list is persisted to Hive and served
  /// from there on subsequent opens so the API isn't called again — the videos
  /// are effectively static, and the box is wiped on logout so a re-login
  /// refetches once. Only a cache miss hits the network.
  ///
  /// Silent on failure: the section just stays hidden. Nothing on the screen
  /// depends on it.
  Future<void> fetchVideos() async {
    final cached = await explainerVideosCache.get(_cacheKey);
    final cachedList = cached?['videos'];
    if (cachedList is List && cachedList.isNotEmpty) {
      _apply(cachedList);
      return;
    }

    final ResponseModel res = await _repo.fetchVideos();
    if (res.statusCode == 200 && res.response?.data?['data'] is List) {
      final raw = res.response!.data['data'] as List;
      _apply(raw);
      final maps =
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      await explainerVideosCache.save(_cacheKey, {'videos': maps});
    }
  }

  /// Parses a raw list (cache or API), keeping only active videos that carry a
  /// playable URL.
  void _apply(List raw) {
    videos.assignAll(
      raw
          .whereType<Map>()
          .map((e) => ExplainerVideo.fromJson(Map<String, dynamic>.from(e)))
          .where((v) => v.isActive && v.hasUrl),
    );
  }
}
