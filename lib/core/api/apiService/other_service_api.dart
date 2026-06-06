/// All `other-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin OtherServiceApi {
  final String createAboutOrganisation = "other-service/about-organisation";
  final String management = "other-service/management";
  final String staff = "other-service/staff";
  final String otherBlogs = "other-service/blogs";
  final String otherNews = "other-service/news";
  final String otherDownloads = "other-service/downloads";
  final String otherTNC = "other-service/terms-and-conditions";
  final String otherTimings = "other-service/timings";
  final String otherGallery = "other-service/gallery";
  final String otherBusinessProfile = "other-service/business-profile";
  final String otherBusinessProfileSearch =
      "other-service/business-profile/search";
  final String otherContactUsService = 'other-service/contact';
}
