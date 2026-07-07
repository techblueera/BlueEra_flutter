import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `user-service/*` endpoint constants used by the app.
///
/// Split out of `base_service.dart` so the user-service surface lives in one
/// place. `BaseService` mixes this in (`with UserServiceApi, ...`), so every
/// repo that already extends `BaseService` inherits these fields/methods
/// unchanged — no call site needs to be updated.
///
/// Constants are copied verbatim from the original `base_service.dart`,
/// including:
///   * leading slashes on some paths (`/user-service/...`) — kept to match
///     the wire format the client currently sends.
///
/// Companion reference docs:
///   * `lib/docs/user-service-api-endpoints.md` — this file's endpoint table.
///   * `lib/docs/api-services-index.md` — index of all `*_service_api.dart`
///     mixins composed into `BaseService`.
mixin UserServiceApi {
  // ──────────────────────────────────────────────────────────────────────
  // 1. User account & profile
  // ──────────────────────────────────────────────────────────────────────
  final String accountDeletionInit = 'user-service/user/account/deletion/init';
  final String getUser = 'user-service/user/get?contact_no=$userMobileGlobal';
  final String allUsers = 'user-service/user/getAllKindOfUser';
  final String getUserByIdUrlForAddress = "user-service/user/getUserById";
  final String getUserProfileOverviewById =
      "user-service/user/getUserProfileOverview/";
  // Public share-card overview — backs the deep-link landing screen for
  // /app/profile/{id} and /app/business/{id}. Returns a trimmed user blob
  // plus follower/post counts and isFollowing for the viewer.
  String shareProfileOverview(String userId) =>
      'user-service/share/users/$userId/profile-overview';
  final String FollowersAndPostsCount =
      'user-service/user/getUserWithFollowersAndPostsCount';
  final String checkUsername = "user-service/user/checkUsername";
  // Look up a user by their 10-digit phone number — used when a phone number
  // tapped inside a chat message needs to be resolved to a BlueEra user.
  String getUserByPhone(String phone) => 'user-service/user/by-phone/$phone';
  final String createGuestAccount = "/user-service/user/create-guest-account";
  // Fetch an existing guest user's profile (name + image) so the
  // account-creation screens can pre-fill it during a guest → full upgrade.
  String getGuestUser(String id) => "user-service/user/getGuestUser/$id";
  final String updateIndividualAccountUser =
      "user-service/user/updateIndividualAccountUser/";
  final String updateDeviceToken = "user-service/user/me/device-token";
  final String updateBusinessAccount =
      "user-service/user/updateBusinessAccount/";
  final String deleteIntroVideo = 'user-service/user/introVideo';
  final String requestMobileUpdateOtp =
      'user-service/user/request-mobile-update-otp';
  final String verifyMobileUpdateOtp =
      'user-service/user/verify-mobile-update-otp';

  // ── Aadhaar OKYC (OTP) identity verification ────────────────────────
  // Generic per-user Aadhaar KYC via UIDAI OKYC OTP (Sandbox.co.in). The
  // verified result is stored against the user account, independent of any
  // business / rider flow. See
  // docs/backend/aadhaar-verification-ui-integration.md.
  final String aadhaarStatus = 'user-service/user/aadhaar/status';
  final String aadhaarGenerateOtp = 'user-service/user/aadhaar/generate-otp';
  final String aadhaarVerifyOtp = 'user-service/user/aadhaar/verify-otp';
  final String userVerifyGst = "user-service/user/verify-gst";
  final String user_project = "user-service/user/project/";
  final String user_experience = "user-service/user/experience/";

  // ── Intro live video upload ─────────────────────────────────────────
  final String uploadLiveVideo = "user-service/user/uploadLiveVideo";

  // ── Ratings on the user object ──────────────────────────────────────
  String userGetRattingSummary(String userID) =>
      "user-service/user/$userID/ratings";

  // ──────────────────────────────────────────────────────────────────────
  // 2. Business profile
  // ──────────────────────────────────────────────────────────────────────
  // final String viewBusinessProfile = '/user-service/business/6a265c5df09a0aaf6cabbb6c';
  final String viewBusinessProfile = '/user-service/business/$businessId';
  final String updateBusinessProfile =
      '/user-service/business/updateBusinessProfile';
  final String bussinessProfileById = "/user-service/business";
  final String businessIdViewForLocation = "user-service/business/user";
  final String updateBusinessDescription =
      'user-service/business/updateBusinessDescription';
  final String updateGSTBusinessDetails =
      "user-service/business/updateGSTBusinessDetails";
  final String businessLivePhotos = 'user-service/business/live-photosOne';
  final String removeBusinessLivePhotos =
      'user-service/business/remove-live-image';

  // ── Availability hours & go-live ────────────────────────────────────
  // Weekly day-by-day open/close schedule, plus going live at open time.
  // The PUT/GET write/read the same Availability document the business
  // profile already exposes under `availability`.
  final String businessAvailabilityHours =
      '/user-service/business/availability/hours';
  // Override / clear TODAY's hours only (auto-reverts tomorrow). PUT to set,
  // DELETE to revert immediately.
  final String businessAvailabilityToday =
      '/user-service/business/availability/today';
  final String businessGoLive = '/user-service/business/availability/go-live';
  final String businessEndLive = '/user-service/business/availability/end-live';


  // too — the same id keys a business account or an individual profile.
  String chatClickRecord(String userId) =>
      'user-service/business/$userId/chat-click';
  String chatClickStats(String userId) =>
      'user-service/business/$userId/chat-clicks';

  // Profile-visit tracking (POST, records one visit) + analytics (GET, summary
  // of total/unique visits). The id is the visited profile's userId — works for
  // both business and personal profiles.
  String profileVisitRecord(String userId) =>
      'user-service/profile-visit/$userId/profile-visit';
  String profileVisitStats(String userId) =>
      'user-service/profile-visit/$userId/profile-visits';

  // ── Business search ─────────────────────────────────────────────────
  // Free-text + geo business search. Query params: q, lat, lng, radius,
  // page, limit. Backs the content-creator "Add associate brands" flow.
  final String businessSearch = 'user-service/business/search';

  // ── Categories & subcategories ──────────────────────────────────────
  final String getAllcategories = 'user-service/business/getAllcategories';
  final String getAllcategoriesByType = 'user-service/business/by-type/';
  String getBusinessCategoryByType(String type) =>
      'user-service/business/by-type/$type';
  String getBusinessSubCategory(String tagId) =>
      'user-service/business/by-tag/$tagId/subcategories';

  // ── Verification docs ───────────────────────────────────────────────
  final String postVerifyBusinessDocs =
      '/user-service/business/postVerifyBusinessDocs';
  final String postVerificationOwnerDocs =
      '/user-service/business/postVerificationOwnerDocs';
  final String verifyBusinessStatus =
      '/user-service/business/verifyBusinessStatus';

  // ── Business rating ─────────────────────────────────────────────────
  String businessRattingSummary(String businessId) =>
      "user-service/business/$businessId/ratings";

  // ──────────────────────────────────────────────────────────────────────
  // 3. Resumes
  // ──────────────────────────────────────────────────────────────────────
// ── Base + profile ──────────────────────────────────────────────────
  final String resumeUrl = "job-service/resumes";
  final String previewForAll = 'job-service/resumes/previewForAll';
  final String resumesTemplates = "job-service/resumes/templates";
  final String resumeTemplatesDownload = "job-service/resumes/download";
  final String profilePicUrl = "job-service/resumes/profile-picture";
  final String profileBioUrl = "job-service/resumes/profile";
  final String updateBioUrl = "job-service/resumes/bio";
  final String addSalaryDetailsUrl = "job-service/resumes/salary-details";
  final String highestQualificationUrl = "job-service/resumes/education";
  final String currentJobUrl = "job-service/resumes/current-job";
  final String portfoliosUrl = 'job-service/resumes/portfolios';
  final String resumeProjects = 'job-service/resumes/projects';

  // ── Career objective ────────────────────────────────────────────────
  final String addCareerObjectiveUrl = "job-service/resumes/career-objective";
  final String updateCareerObjectiveUrl =
      "job-service/resumes/career-objective";
  final String deleteCareerObjectiveUrl =
      "job-service/resumes/career-objective";

  // ── Skills / Languages / Hobbies ────────────────────────────────────
  final String addSkillsUrl = "job-service/resumes/skills";
  final String deleteSkillsUrl = "job-service/resumes/skills";

  final String addLanguageUrl = "job-service/resumes/languages";
  final String getLanguageUrl = "job-service/resumes/languages";
  final String deleteLanguageUrl = "job-service/resumes/languages";

  final String addHobbiesUrl = "job-service/resumes/hobbies";
  final String deleteHobbiesUrl = "job-service/resumes/hobbies";

  // ── Awards ──────────────────────────────────────────────────────────
  final String addAwardUrl = "job-service/resumes/awards";
  final String updateAwardUr = "job-service/resumes/awards";
  final String deleteAwardUrl = "job-service/resumes/awards";

  // ── Achievements ────────────────────────────────────────────────────
  final String addAchievementUrl = "job-service/resumes/achievements";
  final String updateAchievementUrl = "job-service/resumes/achievements";
  final String deleteAchievementUrl = "job-service/resumes/achievements";

  // ── Certifications ──────────────────────────────────────────────────
  final String addCertificationUrl = "job-service/resumes/certifications";
  final String updateCertificationUrl = "job-service/resumes/certifications";
  final String deleteCertificationUrl = "job-service/resumes/certifications";

  // ── Publications ────────────────────────────────────────────────────
  final String addPublicationUrl = "job-service/resumes/publications";
  final String updatePublicationUrl = "job-service/resumes/publications";
  final String deletePublicationUrl = "job-service/resumes/publications";

  // ── Experience ──────────────────────────────────────────────────────
  final String addExperienceUrl = "job-service/resumes/fullTimeExperience";
  final String addPartExperienceUrl = "job-service/resumes/partTimeExperience";

  // ── Patents / NGO / Additional info ─────────────────────────────────
  final String patentsBaseUrl = "job-service/resumes/patents";
  final String ngoBaseUrl = "job-service/resumes/ngo-organizations";
  final String additionalInfoBaseUrl =
      "job-service/resumes/additional-information";
  /*// ── Base + profile ──────────────────────────────────────────────────
  final String resumeUrl = "user-service/resumes";
  final String previewForAll = 'user-service/resumes/previewForAll';
  final String resumesTemplates = "user-service/resumes/templates";
  final String resumeTemplatesDownload = "user-service/resumes/download";
  final String profilePicUrl = "user-service/resumes/profile-picture";
  final String profileBioUrl = "user-service/resumes/profile";
  final String updateBioUrl = "user-service/resumes/bio";
  final String addSalaryDetailsUrl = "user-service/resumes/salary-details";
  final String highestQualificationUrl = "user-service/resumes/education";
  final String currentJobUrl = "user-service/resumes/current-job";
  final String portfoliosUrl = 'user-service/resumes/portfolios';
  final String resumeProjects = 'user-service/resumes/projects';

  // ── Career objective ────────────────────────────────────────────────
  final String addCareerObjectiveUrl = "user-service/resumes/career-objective";
  final String updateCareerObjectiveUrl =
      "user-service/resumes/career-objective";
  final String deleteCareerObjectiveUrl =
      "user-service/resumes/career-objective";

  // ── Skills / Languages / Hobbies ────────────────────────────────────
  final String addSkillsUrl = "user-service/resumes/skills";
  final String deleteSkillsUrl = "user-service/resumes/skills";

  final String addLanguageUrl = "user-service/resumes/languages";
  final String getLanguageUrl = "user-service/resumes/languages";
  final String deleteLanguageUrl = "user-service/resumes/languages";

  final String addHobbiesUrl = "user-service/resumes/hobbies";
  final String deleteHobbiesUrl = "user-service/resumes/hobbies";

  // ── Awards ──────────────────────────────────────────────────────────
  final String addAwardUrl = "user-service/resumes/awards";
  final String updateAwardUr = "user-service/resumes/awards";
  final String deleteAwardUrl = "user-service/resumes/awards";

  // ── Achievements ────────────────────────────────────────────────────
  final String addAchievementUrl = "user-service/resumes/achievements";
  final String updateAchievementUrl = "user-service/resumes/achievements";
  final String deleteAchievementUrl = "user-service/resumes/achievements";

  // ── Certifications ──────────────────────────────────────────────────
  final String addCertificationUrl = "user-service/resumes/certifications";
  final String updateCertificationUrl = "user-service/resumes/certifications";
  final String deleteCertificationUrl = "user-service/resumes/certifications";

  // ── Publications ────────────────────────────────────────────────────
  final String addPublicationUrl = "user-service/resumes/publications";
  final String updatePublicationUrl = "user-service/resumes/publications";
  final String deletePublicationUrl = "user-service/resumes/publications";

  // ── Experience ──────────────────────────────────────────────────────
  final String addExperienceUrl = "user-service/resumes/fullTimeExperience";
  final String addPartExperienceUrl = "user-service/resumes/partTimeExperience";

  // ── Patents / NGO / Additional info ─────────────────────────────────
  final String patentsBaseUrl = "user-service/resumes/patents";
  final String ngoBaseUrl = "user-service/resumes/ngo-organizations";
  final String additionalInfoBaseUrl =
      "user-service/resumes/additional-information";*/

  // ──────────────────────────────────────────────────────────────────────
  // 4. Followers
  // ──────────────────────────────────────────────────────────────────────
  final String follow = 'user-service/followers/follow';
  final String unfollow = 'user-service/followers/unfollow';
  final String followersList = "user-service/followers/followers/";
  final String followingList = "user-service/followers/following/";

  // ──────────────────────────────────────────────────────────────────────
  // 5. Testimonials
  // ──────────────────────────────────────────────────────────────────────
  final String addTestimonial = 'user-service/testimonials/add-testimonial';
  final String getTestimonialById = 'user-service/testimonials/public/';

  // ──────────────────────────────────────────────────────────────────────
  // 6. Addresses
  // ──────────────────────────────────────────────────────────────────────
  final String getAddressApi = "user-service/addresses";
  String updateExistingAddress(String addressId) =>
      "user-service/addresses/$addressId";

  // ──────────────────────────────────────────────────────────────────────
  // 7. Individual professions
  // ──────────────────────────────────────────────────────────────────────
  final String individualProfessions = 'user-service/individual-professions';
  String getIndividualFields(String tagId) =>
      'user-service/individual-professions/$tagId/designation';

  // ──────────────────────────────────────────────────────────────────────
  // 8. Upload (S3 presigned)
  // ──────────────────────────────────────────────────────────────────────
  final String userUploadInit = "user-service/upload/init";

  // ──────────────────────────────────────────────────────────────────────
  // 9. Blocking
  // ──────────────────────────────────────────────────────────────────────
  final String blocked = 'user-service/blocked';

  // ──────────────────────────────────────────────────────────────────────
  // 10. Franchise inquiry
  // ──────────────────────────────────────────────────────────────────────
  final String franchiseInquiry = "user-service/inquiries";

  // ──────────────────────────────────────────────────────────────────────
  // 11. Healthcare enquiry — non-hospital endpoint
  // ──────────────────────────────────────────────────────────────────────
  /// Healthcare enquiry — non-hospital endpoint (be_user_service producer).
  /// Covers Doctors, Labs, Pharmacy, Surgical, and any future non-hospital
  /// healthcare category. `POST` accepts JSON only — photos must be uploaded
  /// first via the `userUploadInit` presign flow and passed as URLs. The
  /// `PUT` status path lets the listing owner accept / decline. Hospital
  /// listings use `hospitalEnquiries` instead. See
  /// lib/docs/healthcare-enquiry-ui-integration.md.
  final String businessEnquiries = "user-service/business-enquiries";
  String businessEnquiryStatus(String enquiryId) =>
      'user-service/business-enquiries/$enquiryId/status';

  /// GET one — used by the owner chat card to fetch the enquiry's true
  /// current status when the message metadata's local latch is empty.
  String businessEnquiryById(String enquiryId) =>
      'user-service/business-enquiries/$enquiryId';
}
