/// All `video-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: the top-level `initUpload = "video-service/upload/init"` in
/// `base_service.dart` is a file-scope constant (not part of any class)
/// and is intentionally left there.
mixin VideoServiceApi {
  final String videoUpload = 'video-service/videos/upload';
  final String videosSearch = 'video-service/videos/search';
  final String songs = 'video-service/songs';
  final String favourite = 'video-service/favorites';
  final String checkFavourite = 'video-service/favorites/check';
  final String songsSearch = 'video-service/songs/search';
  final String favouriteSearch = 'video-service/favorites/search';

  String channelVideos(String channelId) =>
      'video-service/videos/channel/$channelId';
  String ownVideos(String authorId) =>
      'video-service/videos/users/$authorId/videos';

  String postLikeUnlike(String id) => "video-service/likes/$id/like";
  String videoView(String id) => "video-service/videos/metadata/$id";
  // String videoCategories = "video-service/categories";
  String videosShare(String videoId) => "video-service/share/videos/$videoId";

  String videoComments(String videoId) =>
      "video-service/comments/video/$videoId";
  String videoCommentLike(String commentId) =>
      "video-service/comments/$commentId/like";
  final String videoAddComment = "video-service/comments";
  String videos(String videoId) => "video-service/videos/$videoId";
  String videosMetaData(String videoId) => "video-service/videos/$videoId";

  /// Trending/"hot" videos. `type` is `short` (reels) or `long`.
  /// Returns a flat `data: Video[]` array (no author/channel resolution).
  String hotVideos(String type) => "video-service/videos/hot/$type";

  final String deleteVideoServiceCommentById = 'video-service/comments/';
  final String videoUploadStatus = 'video-service/videos/upload-status';
  final String adminVideos = 'video-service/admin-videos';
  final String ottChannelVideo = 'video-service/ott/channel/';
}
