/// All `userfeed-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin UserfeedServiceApi {
  final String addSupport = 'userfeed-service/support/addSupport';
  final String getSupportQuery = "userfeed-service/support/query/filter";
  final String getQueryById = "userfeed-service/support/search";
  final String userFeedReport = "userfeed-service/report/add-reports";
  final String homeFeed = 'userfeed-service/feed';
  final String userFeedServiceVideo = "userfeed-service/feed/videos?";
  final String userFeedPost = 'userfeed-service/feed/posts';
}
