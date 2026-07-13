import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/home/controller/home_feed_controller.dart';
import 'package:get/get.dart';

/// Drives the full-screen, reels-style image feed (opened when an image post is
/// tapped in the home feed).
///
/// The API + pagination are delegated to the existing [HomeFeedController]
/// (cursor-based `homeFeedRepo`) — we don't add a second feed endpoint. This
/// controller only:
///   • filters that mixed feed down to IMAGE posts,
///   • seeds the tapped post first so it shows instantly, and
///   • owns the per-post actions (like / comment count / repost) so they work
///     for every post regardless of the home-screen [FeedController]'s state.
class ImagePostFeedController extends GetxController {
  /// Unique tag so each opened screen gets its own paginating [HomeFeedController]
  /// instance and never clobbers another screen's feed.
  final String tag;

  ImagePostFeedController({required this.tag});

  late final HomeFeedController _home;

  /// Image posts shown in the pager (deduped, tapped-post-first).
  final RxList<Post> imagePosts = <Post>[].obs;

  /// Ids already added — guards against the seeded post reappearing from the
  /// fetched page and against duplicates across pages.
  final Set<String> _seenIds = {};

  RxBool get isLoading => _home.isLoading;

  RxBool get hasMoreData => _home.hasMoreData;

  @override
  void onInit() {
    super.onInit();
    // Reuse the existing paginated home-feed controller for all API calls.
    _home = Get.put(HomeFeedController(), tag: tag);
    // Mirror every new page of the mixed feed into our image-only list.
    ever<List<Post>>(_home.mixedFeed, (_) => _syncFromFeed());
    _syncFromFeed();
  }

  /// Puts the tapped post at index 0 so the screen opens on it immediately,
  /// before the first page finishes loading.
  void seedInitial(Post post) {
    if (post.id.isEmpty) return;
    if (_seenIds.add(post.id)) {
      imagePosts.insert(0, post);
    }
  }

  void _syncFromFeed() {
    for (final p in _home.mixedFeed) {
      if (p.id.isEmpty) continue;
      if (!_isImagePost(p)) continue;
      if (_seenIds.add(p.id)) {
        imagePosts.add(p);
      }
    }
  }

  /// A post counts as an image post when it carries at least one media item and
  /// that media is an image (not a reel / short video / poll).
  bool _isImagePost(Post p) {
    if (p.isReel) return false;
    if (p.media?.isEmpty ?? true) return false;

    final type = (p.type ?? '').toLowerCase();
    if (type == 'short_video' || type == 'poll_post') return false;

    final firstMedia = p.media!.first;
    final firstType =
        (p.media_types?.isNotEmpty ?? false) ? p.media_types!.first : null;

    final isVideo =
        (firstType?.startsWith('video/') ?? false) || isVideoUrl(firstMedia);
    if (isVideo) return false;

    return (firstType?.startsWith('image/') ?? false) || isImageUrl(firstMedia);
  }

  /// Fetch the next page (near the end of the pager).
  void loadMore() => _home.handleScrollToBottom();

  /// Optimistic like toggle with revert on failure.
  Future<void> toggleLike(int index) async {
    if (index < 0 || index >= imagePosts.length) return;
    final post = imagePosts[index];
    final postId = post.id;
    final newLiked = !(post.isLiked ?? false);

    _applyLike(postId, liked: newLiked, delta: newLiked ? 1 : -1);

    try {
      final res = await FeedRepo().likePost(postId: postId);
      if (!res.isSuccess) {
        // revert
        _applyLike(postId, liked: !newLiked, delta: newLiked ? -1 : 1);
      }
    } catch (_) {
      _applyLike(postId, liked: !newLiked, delta: newLiked ? -1 : 1);
    }
  }

  void _applyLike(String postId, {required bool liked, required int delta}) {
    final i = imagePosts.indexWhere((e) => e.id == postId);
    if (i == -1) return;
    final cur = imagePosts[i];
    imagePosts[i] = cur.copyWith(
      isLiked: liked,
      likesCount: (cur.likesCount ?? 0) + delta,
    );
  }

  void updateCommentCount(String postId, int count) {
    final i = imagePosts.indexWhere((e) => e.id == postId);
    if (i != -1) {
      imagePosts[i] = imagePosts[i].copyWith(commentsCount: count);
    }
  }

  void incrementRepost(String postId) {
    final i = imagePosts.indexWhere((e) => e.id == postId);
    if (i != -1) {
      imagePosts[i] =
          imagePosts[i].copyWith(repostCount: (imagePosts[i].repostCount ?? 0) + 1);
    }
  }

  @override
  void onClose() {
    Get.delete<HomeFeedController>(tag: tag);
    super.onClose();
  }
}
