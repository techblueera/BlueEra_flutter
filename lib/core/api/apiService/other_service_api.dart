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
  final String otherBusinessProfileSearch = "other-service/business-profile/search";
  final String otherContactUsService = 'other-service/contact';

  /// Promo creatives (Qureka Lite artwork) grouped by placement, plus the
  /// bilingual notification copy. Public — no token, so it can be prefetched
  /// before login. See docs/backend/ADS_API_FLUTTER_GUIDE.md.
  final String promoAds = "other-service/ads";

  // "Other" business enquiry surface — banking / insurance / loans /
  // capital-market / data. Same generic-selections shape as the
  // healthcare-business endpoint, but a distinct `business_enquiry` card
  // type. See lib/docs/other-enquiry-ui-integration.md.
  final String otherEnquiries = "other-service/other-enquiries";
  final String otherEnquiriesMe = "other-service/other-enquiries/me";
  final String otherEnquiriesOwnerMe = "other-service/other-enquiries/owner/me";
  String otherEnquiryById(String enquiryId) => "other-service/other-enquiries/$enquiryId";
  String otherEnquiryStatus(String enquiryId) => "other-service/other-enquiries/$enquiryId/status";

  /// Server-driven chip catalog for the "other" business enquiry sheet.
  /// One category → an ordered list of `{ title, options[], multiSelect }`
  /// groups. Backend uppercases the segment, so `loans_sector` works too.
  /// See lib/docs/predefined-enquiry-ui-integration.md §1. A 404 means the
  /// category isn't seeded — the sheet falls back to a note-only form
  /// (§1 error table + §2 rendering rules).
  String predefinedEnquiry(String category) =>
      "other-service/predefined-enquiry/${category.trim().toUpperCase()}";
}
