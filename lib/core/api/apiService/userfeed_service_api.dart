/// All `userfeed-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin UserfeedServiceApi {
  final String addSupport = 'userfeed-service/support/addSupport';
  final String getSupportQuery = "userfeed-service/support/query/filter";
  final String getQueryById = "userfeed-service/support/search";
  final String userFeedReport = "userfeed-service/report/add-reports";
  final String homeFeed = 'userfeed-service/feed';

  /// Merged home feed: posts + reels + "who to follow" blocks in one
  /// cursor-paged list. Superset of [homeFeed] — same envelope and the same
  /// item-type vocabulary, plus the new `user_suggestions` item.
  /// See docs/HOME_FEED_INTEGRATION_GUIDE.md.
  ///
  /// [homeFeed] stays live and unchanged — rollback is a one-line swap in
  /// `FeedController._useMergedHomeFeed`.
  final String homeFeedMerged = 'userfeed-service/feed/home';
  final String userFeedServiceVideo = "userfeed-service/feed/videos?";
  final String userFeedPost = 'userfeed-service/feed/posts';
}
