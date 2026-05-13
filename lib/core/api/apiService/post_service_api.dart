/// All `post-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `videoCategories` lives here despite the name because it resolves
/// to `post-service/nature-of-posts`. The video-related routes that target
/// `video-service/...` live in `VideoServiceApi`.
mixin PostServiceApi {
  /// ADD POST
  final String addPost = "post-service/post/add-post";
  final String getAllPosts = "post-service/post/allPosts";
  final String getFilteredPosts = "post-service/post/channel-posts-filtered";
  final String postLike = "post-service/post/like";
  final String post = "post-service/post";
  final String hidePost = "post-service/post/hide-post";
  final String repost = "post-service/post/repost";
  final String sharePost = "post-service/post/shares";
  final String postByID = "post-service/post/view";
  String postAllLikes(String postId) => "post-service/post/$postId/likes";
  final String songsPost = 'post-service/songs';
  final String favouriteSongPost = 'post-service/favorites';
  final String checkFavouriteSongPost = 'post-service/favorites/check';
  final String songsSearchSongPost = 'post-service/songs/search';
  final String favouriteSearchSongPost = 'post-service/favorites/search';
  final String cardCategories = 'post-service/categories';
  final String cardCategoriesSortByDate =
      'post-service/categories/sorted/by-date';
  final String allCardCategories = 'post-service/categories/cards/all';

  /// Comment
  String postComments(String postId) => "post-service/post/comments/$postId";
  final String postComment = "post-service/post/comment";
  final String postCommentLike = "post-service/post/comment/like";

  final String myPost = "post-service/post/my-posts";
  final String otherPost = "post-service/post/others-user-posts";
  final String updatePost = "post-service/post/update-post/";
  final String postSearch = "post-service/post/search";

  final String deletePostCommentById = 'post-service/post/delete-comment/';

  final String initPostServiceUpload =
      "post-service/post/generate-presigned-url";

  String videoCategories = "post-service/nature-of-posts";

  final String postRepost = 'post-service/post/repost';
}
