import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';

/// ----------------- BASE URL START -----------------------
///DEV BASE URL......
String? baseURL = baseUrl;
final String initUpload = "video-service/upload/init";

abstract class BaseService {
  /// ----------------- API URL END DEVICE-----------------------
  final String sentOtp = 'auth-service/sent-otp';
  final String verifyOtp = 'auth-service/verify-otp';
  final String addUser = 'user-service/user/add-user';
  final String getAllcategories = 'user-service/business/getAllcategories';
  final String viewBusinessProfile = '/user-service/business/$businessId';
  final String updateBusinessProfile =
      '/user-service/business/updateBusinessProfile';
  final String subcategories = '/user-service/business/getAllSubcategories';
  final String channels = 'channel-service/channels';
  final String socialLinks = 'channel-service/channels/$channelId/social-links';
  String viewChannelProfile(String channelId) =>
      "channel-service/channels/$channelId";
  final String postVerifyBusinessDocs =
      '/user-service/business/postVerifyBusinessDocs';
  final String postVerificationOwnerDocs =
      '/user-service/business/postVerificationOwnerDocs';
  final String verifyBusinessStatus =
      '/user-service/business/verifyBusinessStatus';
  final String videoUpload = 'video-service/videos/upload';
  final String getUser = 'user-service/user/get?contact_no=$userMobileGlobal';
   String getotherUsers (String contactNo )  =>
       'user-service/user/get?contact_no=$contactNo';
  final String updateUserProfile = 'user-service/user/updateUser';
  final String videosSearch = 'video-service/videos/search';
  String channelStats(String channelId) =>
      'channel-service/channels/$channelId/stats';
  final String bookings = 'booking-enquiry-service/bookings';
   String receivedBooking(String channelId) =>
       'booking-enquiry-service/bookings/summary/by-videos?channelId=$channelId';
   String  receivedEnquiry(String channelId) =>
       'booking-enquiry-service/inquiries/summary/by-videos?channelId=$channelId';
   String receivedVideoBooking(String channelId,String videoId)=>
       'booking-enquiry-service/bookings?channelId=$channelId&videoId=$videoId';
      String receivedVideoEnquiry(String channelId,String videoId)=>''
          'booking-enquiry-service/inquiries?channelId=$channelId&videoId=$videoId';
   String getBookingById(String bookingId)=>
       'booking-enquiry-service/bookings/$bookingId';
   String updateBookingStatus(String id)=>
       'booking-enquiry-service/bookings/$id';
      String enquiryBookingStatus(String id)=>
          'booking-enquiry-service/inquiries/$id/status';
  final String MyBookingList = 'booking-enquiry-service/bookings/my-bookings';
  final String myInquiries = 'booking-enquiry-service/inquiries/my-inquiries';
  final String  Inquiries = 'booking-enquiry-service/inquiries';
  final String allUsers = 'user-service/user/getAllKindOfUser';
  final String songs = 'video-service/songs';
  final String favourite = 'video-service/favorites';
  final String checkFavourite = 'video-service/favorites/check';
  final String songsSearch = 'video-service/songs/search';
  final String favouriteSearch = 'video-service/favorites/search';

  final String updateBusinessDescription =
      'user-service/business/updateBusinessDescription';
  final String businessLivePhotos = 'user-service/business/live-photosOne';
  final String removeBusinessLivePhotos =
      'user-service/business/remove-live-image';

  /// CREATE RESUME
  final String resumeUrl = "user-service/resumes";
  final String profilePicUrl = "user-service/resumes/profile-picture";
  final String profileBioUrl = "user-service/resumes/profile";
  final String updateBioUrl = "user-service/resumes/bio";
  final String addSalaryDetailsUrl = "user-service/resumes/salary-details";
  final String highestQualificationUrl = "user-service/resumes/education";
  final String currentJobUrl = "user-service/resumes/current-job";
  final String blocked = 'user-service/blocked';
  final String portfoliosUrl = 'user-service/resumes/portfolios';

  String channelFollow(String channelId) =>
      "channel-service/follower/$channelId/follow";
  String channelUnFollow(String channelId) =>
      "channel-service/follower/$channelId/unfollow";
  String channelVideos(String channelOrUserId) =>
      'video-service/videos/channel/$channelOrUserId';
  String ownChannelVideos(String authorId) =>
      'video-service/videos/users/$authorId/videos';
  String channelReports(String channelId) =>
      'channel-service/channels/$channelId/reports';
  String channelBlockUser(String channelId) =>
      'channel-service/channels/$channelId/block-user';
  String channelUnBlockUser(String channelId) =>
      'channel-service/channels/$channelId/unblock-user';
  String channelMuteUser(String channelId) =>
      'channel-service/channels/$channelId/mute-user';
  String channelUnMuteUser(String channelId) =>
      'channel-service/channels/$channelId/unmute-user';

  final String addCareerObjectiveUrl = "user-service/resumes/career-objective";
  final String getCareerObjectiveUrl = "user-service/resumes/career-objective";
  final String updateCareerObjectiveUrl =
      "user-service/resumes/career-objective";
  final String deleteCareerObjectiveUrl =
      "user-service/resumes/career-objective";

  final String addSkillsUrl = "user-service/resumes/skills";
  final String getSkillsUrl = "user-service/resumes/skills";
  final String deleteSkillsUrl = "user-service/resumes/skills";

  final String addLanguageUrl = "user-service/resumes/languages";
  final String getLanguageUrl = "user-service/resumes/languages";
  final String deleteLanguageUrl = "user-service/resumes/languages";

  final String addHobbiesUrl = "user-service/resumes/hobbies";
  final String getHobbiesUrl = "user-service/resumes/hobbies";
  final String deleteHobbiesUrl = "user-service/resumes/hobbies";

  final String getAllAwardsUrl = "user-service/resumes/awards";
  final String addAwardUrl = "user-service/resumes/awards";
  final String getAwardByIdUrl = "user-service/resumes/awards";
  final String updateAwardUr = "user-service/resumes/awards";
  final String deleteAwardUrl = "user-service/resumes/awards";

  final String getAllAchievementsUrl = "user-service/resumes/achievements";
  final String addAchievementUrl = "user-service/resumes/achievements";
  final String updateAchievementUrl = "user-service/resumes/achievements";
  final String deleteAchievementUrl = "user-service/resumes/achievements";
  final String getAchievementByIdUrl = "user-service/resumes/achievements";

  final String getAllCertificationsUrl = "user-service/resumes/certifications";
  final String getCertificationByIdUrl = "user-service/resumes/certifications";
  final String addCertificationUrl = "user-service/resumes/certifications";
  final String updateCertificationUrl = "user-service/resumes/certifications";
  final String deleteCertificationUrl = "user-service/resumes/certifications";

  final String getAllPublicationsUrl = "user-service/resumes/publications";
  final String getPublicationByIdUrl = "user-service/resumes/publications";
  final String addPublicationUrl = "user-service/resumes/publications";
  final String updatePublicationUrl = "user-service/resumes/publications";
  final String deletePublicationUrl = "user-service/resumes/publications";

  final String addExperienceUrl = "user-service/resumes/fullTimeExperience";
  final String addPartExperienceUrl = "user-service/resumes/partTimeExperience";

  final String addAdditionalInfoUrl = "user-service/resumes/fullTimeExperience";
  final String getAdditionalInfoUrl = "user-service/resumes/fullTimeExperience";
  final String updateAdditionalInfoUrl =
      "user-service/resumes/fullTimeExperience";
  final String deleteAdditionalInfoUrl =
      "user-service/resumes/fullTimeExperience";
  final String addSupport = 'userfeed-service/support/addSupport';

  /// PATENTS
  final String patentsBaseUrl = "user-service/resumes/patents";

  /// NGO / Student Organisations
  final String ngoBaseUrl = "user-service/resumes/ngo-organizations";

  /// Additional Information
  final String additionalInfoBaseUrl =
      "user-service/resumes/additional-information";

  /// CREATE RESUME END
  /// ADD POST
  final String sendMessage = 'chat-service/chat/send-message';
  final String sendGroupMessage = 'group-chat-service/chat/send-message';
  final String updateMessage = 'chat-service/chat/update-message';
  final String updateGroupMessage = 'group-chat-service/chat/update-message';
  final String generateUploadUrls = 'chat-service/s3/generate-upload-urls';
  final String generateGroupUploadUrls = 'group-chat-service/s3/generate-upload-urls';
  final String generateDownloadUrls = 'chat-service/s3/generate-download-url';
  final String sendDownloadLargeFile =
      'chat-service/chat/send-message-large-file';
  final String sync_offline_messages =
      'chat-service/chat/sync-offline-messages';

  final String sendDownloadGroupLargeFile = 'group-chat-service/chat/send-message-large-file';

  final String forwardMessage = 'chat-service/chat/forward-messages';
  final String groupForwardMessage = 'group-chat-service/chat/forward-messages';
  final String createGroup = 'group-chat-service/group/create';
  final String getGroupMembersChat = 'group-chat-service/group/members';
  final String addGroupMember = "group-chat-service/group/add-members";
  final String checkChatConnection = 'chat-service/connections/check-connection';
  final String getGroupMembers = 'group-chat-service/chat/get-group-members';
  final String deleteChatList = 'chat-service/chat/delete-chatlist';
  final String clearAllChat = 'chat-service/chat/clear-all-chat';
  final String deleteMessage = 'chat-service/chat/delete-messages';
  final String deleteGroupMessage = 'group-chat-service/chat/delete-messages';
  final String addToPinMessage = 'chat-service/chat/add-to-pin-message';
  final String getPinMessageList = 'chat-service/chat/pin-message-list';
  final String addToStarMessage = 'chat-service/chat/add-to-star-message';
  final String getStarMessageList = 'chat-service/chat/star-message-list';
  final String getOneToOneMedia = 'chat-service/chat/get-one-to-one-media';
  final String addToArchive = 'chat-service/chat/add-to-archive';
  final String messageLikeUnlike = 'chat-service/chat/message-like-unlike';
  final String groupMessageLikeUnlike = 'group-chat-service/chat/message-like-unlike';
  final String getChatRequest = 'chat-service/connections/requests';
  final String getLatestChat = 'chat-service/chat/latest-chat';
  final String reactChatRequest = 'chat-service/connections/respond';
  final String connectionsSync = 'chat-service/connections/sync';
    final String myconnectionsSync = 'chat-service/connections/my';
  final String requestForPersonalChat = 'chat-service/connections/request';

  /// Video-feed service
  final String feedPersonalized = "videofeed-service/feeds/personalized";
  final String feedTrending = "videofeed-service/feeds/trending";
  final String feedHome = "videofeed-service/feeds/home";
  final String feedNearBy = "videofeed-service/feeds/nearby";

  /// Video-service
  String postLikeUnlike(String id) => "video-service/likes/$id/like";
  String videoView(String id) => "video-service/videos/metadata/$id";
  String videoCategories = "video-service/categories";
  String videosShare(String videoId) => "video-service/share/videos/$videoId";

  /// Post service
  final String addPost = "post-service/post/add-post";
  final String getAllPosts = "post-service/post/allPosts";
  final String getFilteredPosts = "post-service/post/channel-posts-filtered";
  final String postLike = "post-service/post/like";
  final String post = "post-service/post";
  final String hidePost = "post-service/post/hide-post";
  final String repost = "post-service/post/repost";
  final String sharePost = "post-service/post/shares";
  final String pollAnswer = "poll/answer";
  final String postByID = "post-service/post/view/";
  String postAllLikes(String postId) => "post-service/post/$postId/likes";
  final String songsPost = 'post-service/songs';
  final String favouriteSongPost = 'post-service/favorites';
  final String checkFavouriteSongPost = 'post-service/favorites/check';
  final String songsSearchSongPost = 'post-service/songs/search';
  final String favouriteSearchSongPost = 'post-service/favorites/search';
  final String cardCategories = 'post-service/categories';
  final String cardCategoriesSortByDate = 'post-service/categories/sorted/by-date';

  /// Comment
  String postComments(String postId) =>
      "post-service/post/comments/$postId";
  final String postComment = "post-service/post/comment";
  final String postCommentLike = "post-service/post/comment/like";
  String videoComments(String videoId) =>
      "video-service/comments/video/$videoId";
  String videoCommentLike(String commentId) =>
      "video-service//comments/$commentId/like";
  final String videoAddComment = "video-service/comments";
  String videos(String videoId) =>
      "video-service/videos/$videoId";
  String videosMetaData(String videoId) =>
      "video-service/videos/$videoId";

  final String getSocialMediaHandlers = "user-service/user/getSMediaHandlers";
  final String addSocialMediaHandler = "user-service/user/addSMediaHandler";
  final String getLiveVideo = "user-service/user/getLiveVideo";
  final String uploadLiveVideo = "user-service/user/uploadLiveVideo";
  final String userVerifyGst = "user-service/user/verify-gst";
  final String updateGSTBusinessDetails =
      "user-service/business/updateGSTBusinessDetails";

  //JOB POST
  final String jobPost = "job-service/jobs";
  String jobPostStep2(String jobId) =>
      "job-service/jobs/$jobId/step2";
  String jobPostStep3(String jobId) =>
      "job-service/jobs/$jobId/step3";
  String jobPostStep4(String jobId) =>
      "job-service/jobs/$jobId/step4";
  String publishJob(String jobId) =>
      "job-service/jobs/$jobId/publish";
  String updateJobDetails(String jobId) =>
      "job-service/jobs/$jobId";
  String getJobByLat(String lat, lng) =>
      "map-service/api/jobs?lat=$lat&lng=$lng&radius=25";
  String getStoreByLat(String lat, lng) =>
      "map-service/api/stores?lat=$lat&lng=$lng&radius=25";

  String getJobDetails(String jobId) =>
      "job-service/jobs/$jobId";
  String getResumeById(String resumeId) =>
      "job-service/resumes/$resumeId";
  String getPlaceById(String placeId) =>
      "map-service/api/places/$placeId";
  String getStoreById(String storeId) =>
      "map-service/api/stores/$storeId";
  String getPlaceByLat(double lat,double lng) =>
      "map-service/api/places?lat=$lat&lng=$lng&radius=25";
  final String servicesByLatLng = "map-service/api/services";
  final String foodServicesByLatLng = "map-service/api/services/food-services";
  String getServiceProfileByUserId(String userId) =>
      "map-service/services/$userId";
  final String storesByLatLng = "map-service/stores";
  String getStoresDetailsByStoreId(String storeId) =>
      "map-service/stores/$storeId";
  final String getSupportQuery = "userfeed-service/support/query/filter";
  final String getQueryById = "userfeed-service/support/search";
  final String getAllJobs = "job-service/jobs";
  final String getAllResumes = "job-service/resumes";
  final String jobApplication = "job-service/applications";

  String setAvailability(String channelId) =>
      "booking-enquiry-service/availability/$channelId";
 String getcalender(String channelId) =>
     "booking-enquiry-service/availability/calendar/$channelId";
//  String getReceivedBooking (String channelId,String videoId)=>"booking-enquiry-service/bookings/$channelId/$videoId";
  ///TRAVEL
  final String addPlace = "travel-service/places/add";
  final String placeCategory = "travel-service/categories";
  final String travelServiceJourney = "travel-service/journey";
  final String travelJourneyPost = "travel-service/journey-post";

  final String resumes = "resumes";
  final String resumesTemplates = "user-service/resumes/templates";
  final String resumeTemplatesDownload = "user-service/resumes/download";

  final String languages = "language-service/languages/names";
  final String languagesDownload = "language-service/languages";
  final String myPost = "post-service/post/my-posts";
  final String otherPost = "post-service/post/others-user-posts";
  final String updatePost = "post-service/post/update-post/";
  final String postSearch = "post-service/post/search";
  final String journeyStatus = "travel-service/journey/status";

  final String getUserByIdUrl = "user-service/user/getUserById";
  final String bussinessProfileById = "/user-service/business";
  final String businessRating = "/user-service/business/business";
  final String postBusinessRating = 'user-service/business/rating';

  ///SUBSCRIPTION....
  final String subscriptionCreate =
      'subscription-service/subscription/create-subscription';
  final String subscriptionVerification =
      'subscription-service/subscription/verify-subscription-payment';
  final String subscriptionCancel =
      'subscription-service/subscription/cancel-subscription';

  final String FollowersAndPostsCount =
      'user-service/user/getUserWithFollowersAndPostsCount';
  final String getSubscriptionPlans =
      'subscription-service/subscription/subscription-plans';
  final String getSubscriptionOffer =
      'subscription-service/subscription/subscription-offers';
  final String getAllProducts = 'inventory-service/product/getAllProducts';
  final String getParticularRating = 'user-service/business/rating';

  ///SAVED,DELETE,GET
  final String savedJob = 'job-service/saved-jobs';
  final String jobServiceFeedback = 'job-service/feedback';
  final String applicationBulkClear = 'job-service/applications/bulk-clear';
  final String applicationJobService = 'job-service/applications/job/';
  final String jobServiceInterviews = 'job-service/interviews/bulk-schedule';
  final String jobServiceInterviewsReschedule =
      'job-service/interviews/bulk-reschedule';
  final String jobApplicationJob = 'job-service/applications/job/';
  final String jobApplicationStatusBulk =
      'job-service/applications/bulk-status';
  final String jobServiceInterviewsFeedback = 'job-service/interviews/';

  // job-service/interviews/bulk-reschedule

  // final String jobServiceInterviews='job-service/interviews';

  ///Channel-product-service
  final String products = 'channel-product-service/products';
  String channelProducts(String channelId) =>
      "channel-product-service/products/channel/$channelId";
  String product(String productId) =>
      "channel-product-service/products/$productId";
  final String jobWithScheduleInterview = 'job-service/jobs/with-interviews';
  final String candidateWithScheduleInterview =
      'job-service/interviews/candidate';
  final String jobSearch = 'job-service/feed/search';
  final String previewForAll = 'user-service/resumes/previewForAll';
  final String deleteIntroVideo = 'user-service/user/introVideo';

  /// Booking & Inquiry
  String bookingAvailability(String channelId) =>
      "booking-enquiry-service/availability/$channelId";
  final String follow = 'user-service/followers/follow';
  final String unfollow = 'user-service/followers/unfollow';
  final String addTestimonial = 'user-service/testimonials/add-testimonial';
  final String getTestimonialById = 'user-service/testimonials/public/';
  final String getUserProfileOverviewById =
      "user-service/user/getUserProfileOverview/";
  final String user_project = "user-service/user/project/";
  final String user_experience = "user-service/user/experience/";
  final String getStoreListing = "map-service/api/stores";
  final String userUploadInit = "user-service/upload/init";
  String bankDetails(String channelId) =>
      'channel-service/channels/$channelId/bank-details';
  final String checkUsername = "user-service/user/checkUsername";
  final String followersList = "user-service/followers/followers/";
  final String followingList = "user-service/followers/following/";

  // final String deleteUserAccount="user-service/user/checkUsername";

// Payment Setting;

  final String addAccountApi = "/wallet-service/payment/addAccount";
  final String getAccountApi = "/wallet-service/payment/getAccounts";
  final String updateAccountIdApi = "/wallet-service/payment/updateAccount/";
  final String accountDeleteApi = "/wallet-service/payment/deleteAccount/";
  final String setDefaultBankApi = "/wallet-service/payment/setDefaultBank/";

  // Wallet
  final String WithdrawalApi = "/wallet-service/wallet/withdrawal-request";
  final String WalletApi = "/wallet-service/wallet/me";
  final String WalletTransctionApi =
      "/wallet-service/wallet/transactions?";

  final String versionControl = 'user-service/version-control/check-version';


  // Notification

  final String notificationListApi = "/notification-service/notifications";
  String clearNotificationWithId(String notifyId) =>
      '/notification-service/notifications/$notifyId';
  final String clearAllNotification = '/notification-service/notifications/all';
  final String individualProfessions = 'user-service/individual-professions';
  final String deletePostCommentById = 'post-service/post/delete-comment/';
  final String deleteVideoServiceCommentById = 'video-service/comments/';

  //categories
  final String toplevelcategoriesApi = "/inventory-service/product/categories/top-level";
  final String createGuestAccount = "/user-service/user/create-guest-account";
  final String userFeedReport = "userfeed-service/report/add-reports";
  final String updateIndividualAccountUser = "user-service/user/updateIndividualAccountUser/";
  final String updateBusinessAccount = "user-service/user/updateBusinessAccount/";
  final String socialLinksUpdate = "channel-service/channels/social-links/";
  final String getCountRating="user-service/business/getCountOfRating/";
    String getRattingSummary(String userID)=>"user-service/business/rating/$userID/summary";
    String userGetRattingSummary(String userID)=>"user-service/user/$userID/ratings";
    String userGetRattingDetails(String userID)=>"user-service/user/$userID/rating-details";
  String businessGetRattingSummary(String userID)=>"user-service/business/$userID/ratings";

  final String subchildORRootCategroy = "product-service/api/categories/getSubchildORRootCategroy";
  final String searchProductCategory = "product-service/api/categories/searchCategories";
  final String createProduct = "product-service/api/product/create-product";
  String updateProductFeature(String productId) =>
      'product-service/api/product/updateProductFeature/$productId';
  String updatePriceAndWarranty(String productId) =>
      'product-service/api/product/updatePriceAndWarranty/$productId';
  final String createService = "services-service/services";
  final String generateAiContent = "ai-service/api/ai-product/generate-content";
  final String createProductViaAi = "product-service/api/product/createProductAI";

  final String homeFeed = 'userfeed-service/feed';

}
