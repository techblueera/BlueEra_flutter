/// All `videofeed-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin VideofeedServiceApi {
  /// Shorts-feed service
  final String feedPersonalized = "videofeed-service/feeds/personalized";
  final String feedTrending = "videofeed-service/feeds/trending";
  final String feedNearBy = "videofeed-service/feeds/nearby";

  /// Video-service (note: video CRUD lives in `VideoServiceApi`; this is
  /// the consolidated home feed only.)
  final String feedHome = "videofeed-service/feeds/home";
}
