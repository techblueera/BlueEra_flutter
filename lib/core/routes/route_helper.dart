import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/business/business_verification/view/business_verification_screen.dart';
import 'package:BlueEra/features/business/business_verification/view/ownership_verification_screen.dart';
import 'package:BlueEra/features/business/business_verification/view/select_company_verification_screen.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_details_edit_page_one.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_profile.dart';
import 'package:BlueEra/features/common/auth/views/screens/business_account_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_account_type_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_user_account.dart';
import 'package:BlueEra/features/common/auth/views/screens/mobile_number_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/otp_page_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step2.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';
import 'package:BlueEra/features/common/jobs/view/applied_screen/applied_jobs_screen.dart';
import 'package:BlueEra/features/common/jobs/view/interview_invites_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_overview_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_qna_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_resume_screen.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_one.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_two.dart';
import 'package:BlueEra/features/common/map/view/category_selection_screen.dart';
import 'package:BlueEra/features/common/map/view/customize_map_screen.dart';
import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
import 'package:BlueEra/features/common/notification/view/notification_screen.dart';
import 'package:BlueEra/features/common/onboarding/view/onboarding_slider_screen.dart';
import 'package:BlueEra/features/common/onboarding/view/splash_screen.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_post_screen_new.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_preview_screen.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_review_screen.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_screen.dart';
import 'package:BlueEra/features/common/post/poll_post/poll_input_screen.dart';
import 'package:BlueEra/features/common/post/poll_post/poll_review_screen.dart';
import 'package:BlueEra/features/common/reel/models/song_model.dart';
import 'package:BlueEra/features/common/reel/view/channel/channel_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/manage_channel_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
import 'package:BlueEra/features/common/reel/view/music/add_song_screen.dart';
import 'package:BlueEra/features/common/reel/view/music/all_songs_screen.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_player_screen.dart';
import 'package:BlueEra/features/common/reel/view/tag_people_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/full_video_preview_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_player_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_recorder_screen.dart';
import 'package:BlueEra/features/journey/view/journey_planning_screen.dart';
import 'package:BlueEra/features/journey/view/update_journy_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/my_enquires_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_enquiries_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/send_enquiry_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/earn_blueera_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents_screen/add_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/add_account_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_upi/add_accountupi_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/product_listing_screen/product_listing_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/see_all_transactions.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_screen.dart';
import 'package:BlueEra/features/personal/resume/create_resume_screen.dart';
import 'package:BlueEra/features/personal/resume/sections/resume_templates_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/sub_feature/draft_screen.dart';

import '../../features/chat/contacts/view/contact_list_page.dart';
import '../../features/common/store/add_update_product/add_update_product_screen.dart';
import '../../features/common/store/models/get_channel_product_model.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/appointment_booking_form.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/bookings_enquiries.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/my_booking_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/received_booking_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/set_availability_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/videography_tutorial_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/videography_tutorial_screen2.dart';

class RouteHelper {
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  static String getMobileNumberLoginRoute() => RouteConstant.MobileNumberScreen;

  static String getOnboardingSliderScreenRoute() =>
      RouteConstant.OnboardingSliderScreen;

  // static String getOnboardingStartedScreenRoute() => RouteConstant.OnboardingStartedScreen;

  static String getOtpPageScreenRoute() => RouteConstant.OtpPageScreen;

  static String getSelectAccountScreenRoute() =>
      RouteConstant.SelectAccountScreen;

  static String getCreateUserAccountRoute() => RouteConstant.CreateUserAccount;

  static String getHomeScreenRoute() => RouteConstant.HomeScreen;

  static String getSplashScreenRoute() => RouteConstant.SplashScreen;

  static String getAudioCallScreenRoute() => RouteConstant.AudioCallScreen;

  static String getBusinessAccountRoute() => RouteConstant.BusinessAccount;

  static String getAddEditVisitingCardScreenRoute() =>
      RouteConstant.AddEditVisitingCardScreen;

  static String getBottomNavigationBarScreenRoute() =>
      RouteConstant.BottomNavigationBarScreen;

  static String getPersonalProfileCreateScreenRoute() =>
      RouteConstant.PersonalProfileCreateScreen;

  static String getFeedScreenRoute() => RouteConstant.FeedScreen;

  static String getSelectCompanyVerificationScreenRoute() =>
      RouteConstant.SelectCompanyVerificationScreen;

  static String getBusinessVerificationScreenRoute() =>
      RouteConstant.BusinessVerificationScreen;

  static String getOwnershipVerificationScreenRoute() =>
      RouteConstant.OwnershipVerificationScreen;

  static String getNotificationScreenRoute() =>
      RouteConstant.NotificationScreen;

  static String getManageChannelScreenRoute() =>
      RouteConstant.ManageChannelScreen;

  static String getChannelScreenRoute() => RouteConstant.ChannelScreen;

  static String getCreateReelScreenRoute() => RouteConstant.CreateReelScreen;

  static String getCustomizeMapScreenRoute() =>
      RouteConstant.CustomizeMapScreen;

  static String getSearchLocationScreenRoute() =>
      RouteConstant.SearchLocationScreen;

  static String getAddSongScreenRoute() => RouteConstant.addSongScreen;

  static String getAddPlaceStepOneScreenRoute() =>
      RouteConstant.addPlaceStepOne;

  static String getAddPlaceStepTwoScreenRoute() =>
      RouteConstant.addPlaceStepTwo;

  static String getCategorySelectionScreenRoute() =>
      RouteConstant.categorySelectionScreen;

  static String getJobResumeScreenRoute() => RouteConstant.JobResumeScreen;

  static String getJobQnaScreenRoute() => RouteConstant.JobQnaScreen;

  static String getJobDetailsOverviewScreenRoute() =>
      RouteConstant.JobDetailsOverviewScreen;

  static String getAppliedJobsScreenRoute() => RouteConstant.AppliedJobsScreen;

  static String getInterviewInvitesScreenRoute() =>
      RouteConstant.InterviewInvitesScreen;
  static String getAddUpdateProductScreenRoute() =>
      RouteConstant.addUpdateProductScreen;

  static String getFollowerFollowingScreenRoute() =>
      RouteConstant.FollowerFollowingScreen;

  static String getChatContactsRoute() => RouteConstant.ChatContactsScreen;

  static String getCreateJobPostScreenRoute() =>
      RouteConstant.CreateJobPostScreen;

  static String getCreateJobPostStep2Route() =>
      RouteConstant.CreateJobPostStep2;

  static String getCreateJobPostStep3Route() =>
      RouteConstant.CreateJobPostStep3;

  static String getCreateJobPostStep4Route() =>
      RouteConstant.CreateJobPostStep4;

  static String getCreateJobPostStep5Route() =>
      RouteConstant.CreateJobPostStep5;

  static String getTagPeopleScreenRoute() => RouteConstant.tagPeopleScreen;

  static String getVideoReelRecorderScreenRoute() =>
      RouteConstant.videoRecorderScreen;

  static String getFullVideoPreviewRoute() => RouteConstant.fullVideoPreview;

  static String getVideoTrimScreenRoute() => RouteConstant.videoTrimScreen;

  static String getAllSongsScreenRoute() => RouteConstant.allSongsScreen;

  static String getCreateMessagePostScreenRoute() =>
      RouteConstant.CreateMessagePostScreen;

  static String getPollInputScreenRoute() => RouteConstant.PollInputScreen;

  static String getPollReviewScreenRoute() => RouteConstant.PollReviewScreen;

  static String getPhotoPostScreenRoute() => RouteConstant.PhotoPostScreen;

  static String getPhotoPostPreviewScreenRoute() =>
      RouteConstant.PhotoPostPreviewScreen;

  static String getPhotoPostReviewScreenRoute() =>
      RouteConstant.PhotoPostReviewScreen;

  static String getVideoPlayerScreenRoute() => RouteConstant.videoPlayerScreen;

  // In route_helper.dart
  static String getJourneyPlanningScreenRoute() =>
      RouteConstant.journeyPlanningScreen;

  // In route_helper.dart
  static String getUpdateJourneyScreenRoute() =>
      RouteConstant.UpdateJourneyScreen;

  static String getShortsPlayerScreenRoute() =>
      RouteConstant.shortsPlayerScreen;

  static String getCreateResumeScreenRoute() =>
      RouteConstant.CreateResumeScreen;

  static String getResumeTemplateScreenRoute() =>
      RouteConstant.ResumeTemplateScreen;

  static String getProductListingScreenRoute() =>
      RouteConstant.ProductListingScreen;
  static String getMyBookingScreenRoute() => RouteConstant.MyBookingScreen;
  static String getReceivedBookingScreenRoute() =>
      RouteConstant.ReceivedBookingScreen;
  static String getVideographyTutorialScreenRoute() =>
      RouteConstant.VideographyTutorialScreen;
  static String getReceivedEnquiriesScreenRoute() =>
      RouteConstant.ReceivedEnquiriesScreen;
  static String getVideographyTutorialScreen2Route() =>
      RouteConstant.VideographyTutorialScreen2;
  static String getMyEnquiresRoute() => RouteConstant.MyEnquiresScreen;
  static String getBookingAndEnquiresRoute() => RouteConstant.MyEnquiresScreen;
  static String sentEnquiresRoute() => RouteConstant.EnquiryForm;
  static String getAddProductScreenRoute() =>
      RouteConstant.BookingAndEnquiresScreen;
  static String getAvailabilityScreenRoute() =>
      RouteConstant.SetAvailabilityScreen;
  static String getAppointmentBookingScreenRoute() =>
      RouteConstant.AppointmentBookingScreen;
  static String getAddAccountScreenRoute() => RouteConstant.addAccountScreen;
  static String getAddAccountUpiScreenRoute() =>
      RouteConstant.addAccountUpiScreen;
  static String getWalletScreenRoute() => RouteConstant.walletScreen;
  static String getAllTransactionsScreen() =>
      RouteConstant.allTransactionsScreen;
  static String getearnBlueeraScreenRoute() => RouteConstant.earnBlueeraScreen;
  static String getaddDocumentScreenRoute() => RouteConstant.addDocumentScreen;
  static String getpostDetailPageRoute() => RouteConstant.postDetailPage;

  ///REDIRECT ROUTING SETUP.....
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstant.SplashScreen:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(),
          settings: RouteSettings(name: RouteHelper.getSplashScreenRoute()),
        );
      case RouteConstant.MobileNumberScreen:
        return MaterialPageRoute(
          builder: (_) => MobileNumberScreen(),
          settings:
              RouteSettings(name: RouteHelper.getMobileNumberLoginRoute()),
        );
      case RouteConstant.OnboardingSliderScreen:
        return MaterialPageRoute(
          builder: (_) => OnboardingSliderScreen(),
          settings:
              RouteSettings(name: RouteHelper.getOnboardingSliderScreenRoute()),
        );
      case RouteConstant.OtpPageScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final mobileNumber = args[ApiKeys.argMobileNumber] as String;
        return MaterialPageRoute(
          builder: (_) => OtpPageScreen(
            mobileNumber: mobileNumber,
          ),
        );
      case RouteConstant.SelectAccountScreen:
        return MaterialPageRoute(builder: (_) => CreateAccountScreen());
      case RouteConstant.HomeScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final onHeaderVisibilityChanged =
            args[ApiKeys.onHeaderVisibilityChanged] as Function(bool);
        final isHeaderVisible = args[ApiKeys.isHeaderVisible] as bool;
        return MaterialPageRoute(
            builder: (_) => HomeScreen(
                isHeaderVisible: isHeaderVisible,
                onHeaderVisibilityChanged: onHeaderVisibilityChanged));
      case RouteConstant.BottomNavigationBarScreen:
        // final args = settings.arguments as Map<dynamic, dynamic>;
        // int? initialIndex = args[ApiKeys.initialIndex];
        return MaterialPageRoute(
          builder: (_) => BottomNavigationBarScreen(
              // initialIndex: initialIndex??0,
              ),
          settings: RouteSettings(
              name: RouteHelper.getBottomNavigationBarScreenRoute()),
        );
      case RouteConstant.CreateUserAccount:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;

        return MaterialPageRoute(
          builder: (_) => CreateUserAccount(
            accountType: accountType,
          ),
        );
      case RouteConstant.BusinessAccount:
        return MaterialPageRoute(builder: (_) => BusinessAccountScreen());
      case RouteConstant.AddEditVisitingCardScreen:
        // final companyData =
        //     args[ApiKeys.argCompanyData] != null ? args[ApiKeys.argCompanyData] as GetMyProfileModel : null;
        return MaterialPageRoute(builder: (_) => BusinessDetailsEditPageOne());
      case RouteConstant.BusinessOwnProfileScreen:
        return MaterialPageRoute(builder: (_) => BusinessOwnProfileScreen());

      case RouteConstant.FeedScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final onHeaderVisibilityChanged =
            args[ApiKeys.onHeaderVisibilityChanged] as Function(bool)?;
        final postFilterType = args[ApiKeys.postFilterType] as PostType;
        final id = args[ApiKeys.id] as String;
        return MaterialPageRoute(
            builder: (_) => FeedScreen(
                onHeaderVisibilityChanged: onHeaderVisibilityChanged,
                postFilterType: postFilterType,
                id: id));
      case RouteConstant.SelectCompanyVerificationScreen:
        return MaterialPageRoute(
            builder: (_) => SelectCompanyVerificationScreen());
      case RouteConstant.BusinessVerificationScreen:
        return MaterialPageRoute(builder: (_) => BusinessVerificationScreen());
      case RouteConstant.OwnershipVerificationScreen:
        return MaterialPageRoute(builder: (_) => OwnershipVerificationScreen());
      case RouteConstant.NotificationScreen:
        return MaterialPageRoute(builder: (_) => NotificationScreen());
      case RouteConstant.ChannelScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final channelId = args[ApiKeys.channelId] as String;
        final authorId = args[ApiKeys.authorId] as String;
        return MaterialPageRoute(
          builder: (_) => ChannelScreen(
              accountType: accountType,
              channelId: channelId,
              authorId: authorId),
          settings: RouteSettings(
            name: RouteHelper.getChannelScreenRoute(),
            arguments: settings.arguments,
          ),
        );

      case RouteConstant.ManageChannelScreen:
        return MaterialPageRoute(
          builder: (_) => ManageChannelScreen(),
          settings: RouteSettings(
            name: RouteHelper.getManageChannelScreenRoute(),
            arguments: settings.arguments,
          ),
        );
      case RouteConstant.CreateReelScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String;
        final videoType = args[ApiKeys.videoType] as Video;
        final videoId = args[ApiKeys.videoId] as String?;
        final argPostVia = args[ApiKeys.argPostVia] as PostVia?;
        return MaterialPageRoute(
          builder: (_) => ReelUploadDetailsScreen(
              videoPath: videoPath,
              videoType: videoType,
              videoId: videoId,
              postVia: argPostVia),
        );
      case RouteConstant.CustomizeMapScreen:
        return MaterialPageRoute(builder: (_) => CustomizeMapScreen());
      case RouteConstant.SearchLocationScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final onPlaceSelected = args?[ApiKeys.onPlaceSelected] as Function(
            double?, double?, String?)?;
        final fromScreen = args?[ApiKeys.fromScreen] as String;
        return MaterialPageRoute(
          builder: (_) => SearchLocationScreen(
              onPlaceSelected: onPlaceSelected, fromScreen: fromScreen),
          settings:
              RouteSettings(name: RouteHelper.getSearchLocationScreenRoute()),
        );

      case RouteConstant.addPlaceStepOne:
        return MaterialPageRoute(
          builder: (_) => AddPlaceStepOneScreen(),
          settings:
              RouteSettings(name: RouteHelper.getAddPlaceStepOneScreenRoute()),
        );
      case RouteConstant.addPlaceStepTwo:
        return MaterialPageRoute(
          builder: (_) => AddPlaceStepTwoScreen(),
          settings:
              RouteSettings(name: RouteHelper.getAddPlaceStepTwoScreenRoute()),
        );
      case RouteConstant.categorySelectionScreen:
        return MaterialPageRoute(
          builder: (_) => CategorySelectionScreen(),
          settings: RouteSettings(
              name: RouteHelper.getCategorySelectionScreenRoute()),
        );
      case RouteConstant.JobResumeScreen:
        return MaterialPageRoute(builder: (_) => JobResumeScreen());
      case RouteConstant.JobQnaScreen:
        return MaterialPageRoute(builder: (_) => JobQNAScreen());
      case RouteConstant.JobDetailsOverviewScreen:
        return MaterialPageRoute(builder: (_) => JobDetailsOverviewScreen());
      case RouteConstant.AppliedJobsScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final headerHeight = args?[ApiKeys.headerHeight] as double;
        return MaterialPageRoute(
            builder: (_) => AppliedJobsScreen(
                  onHeaderVisibilityChanged: (bool isVisible) {},
                  headerHeight: headerHeight,
                ));
      case RouteConstant.InterviewInvitesScreen:
        return MaterialPageRoute(builder: (_) => InterviewInvitesScreen());

      // case RouteConstant.FollowerFollowingScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => FollowersFollowingPage(),
      //   );
      case RouteConstant.ChatContactsScreen:
        return MaterialPageRoute(
          builder: (_) => ContactsPage(),
        );
      case RouteConstant.CreateJobPostScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final isEditMode = args?['isEditMode'] as bool? ?? false;
        final jobId = args?['jobId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => CreateJobPostScreen(
            isEditMode: isEditMode,
            jobId: jobId,
          ),
        );
      case RouteConstant.CreateJobPostStep2:
        return MaterialPageRoute(
          builder: (_) => CreateJobPostStep2(),
        );
      case RouteConstant.CreateJobPostStep3:
        return MaterialPageRoute(
          builder: (_) => CreateJobPostStep3(),
        );
      case RouteConstant.CreateJobPostStep4:
        return MaterialPageRoute(
          builder: (_) => CreateJobPostStep4(),
        );
      // case RouteConstant.CreateJobPostStep5:
      //   return MaterialPageRoute(
      //     builder: (_) => CreateJobPostStep5(),
      //   );
      case RouteConstant.tagPeopleScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final previouslySelectedItems =
            args[ApiKeys.previouslySelectedItems] as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) =>
              TagPeopleScreen(previouslySelectedItems: previouslySelectedItems),
          settings: RouteSettings(name: RouteHelper.getTagPeopleScreenRoute()),
        );
      case RouteConstant.CreateMessagePostScreen:
        if ((settings.arguments != null)) {
          final args = settings.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;

          ///CHANGE IN ELSE BLOCK ALSO....
          return MaterialPageRoute(
            builder: (_) => CreateMessagePostScreenNew(
                isEdit: isEdit, post: postData, postVia: postVia),
          );
          // return MaterialPageRoute(
          //   builder: (_) => CreateMessagePostScreen(
          //       isEdit: isEdit, post: postData, postVia: postVia),
          // );
        } else {
          final args = settings.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return MaterialPageRoute(
            builder: (_) =>
                CreateMessagePostScreenNew(isEdit: false, postVia: postVia),
          );
        }

      case RouteConstant.videoRecorderScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return MaterialPageRoute(
          builder: (_) => VideoReelRecorderScreen(postVia: postVia),
        );
      case RouteConstant.fullVideoPreview:
        final args = settings.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String;
        final argPostVia = args[ApiKeys.argPostVia] as PostVia;
        return MaterialPageRoute(
            builder: (_) =>
                FullVideoPreview(videoPath: videoPath, argPostVia: argPostVia),
            settings: settings);
      // case RouteConstant.videoTrimScreen:
      //   final args = settings.arguments as Map<String, dynamic>;
      //   final videoPath = args[ApiKeys.videoPath] as String;
      //   final isFrom = args[ApiKeys.isFrom] as String;
      //   return MaterialPageRoute(
      //     builder: (_) => VideoTrimScreen(videoPath: videoPath, isFrom: isFrom),
      //   );
      case RouteConstant.allSongsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String?;
        final images = args[ApiKeys.filePath] as List<String>?;
        return MaterialPageRoute(
          builder: (_) => AllSongsScreen(video: videoPath, images: images),
        );
      case RouteConstant.addSongScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String?;
        final images = args[ApiKeys.filePath] as List<String>?;
        final audioUrl = args[ApiKeys.audioUrl] as String;
        final song = args[ApiKeys.song] as SongModel;

        return MaterialPageRoute(
          builder: (_) => AddSongScreen(
              video: videoPath,
              images: images,
              audioUrl: audioUrl,
              song: song
          ),
        );

      case RouteConstant.PollInputScreen:
        if ((settings.arguments != null)) {
          final args = settings.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return MaterialPageRoute(
            builder: (_) => PollInputScreen(
                isEdit: isEdit, post: postData, postVia: postVia),
          );
        } else {
          final args = settings.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return MaterialPageRoute(
            builder: (_) => PollInputScreen(isEdit: false, postVia: postVia),
          );
        }
      // return MaterialPageRoute(
      //   builder: (_) => PollInputScreen(isEdit: null,),
      // );
      case RouteConstant.PollReviewScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return MaterialPageRoute(
          builder: (_) => PollReviewScreen(postVia: postVia),
        );
      case RouteConstant.PhotoPostScreen:
        if ((settings.arguments != null)) {
          final args = settings.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return MaterialPageRoute(
            builder: (_) => PhotoPostScreen(
                isEdit: isEdit, post: postData, postVia: postVia),
          );
        } else {
          final args = settings.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return MaterialPageRoute(
            builder: (_) => PhotoPostScreen(isEdit: false, postVia: postVia),
          );
        }
      // return MaterialPageRoute(
      //   builder: (_) => PhotoPostScreen(),
      // );
      case RouteConstant.PhotoPostPreviewScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return MaterialPageRoute(
          builder: (_) => PhotoPostPreviewScreen(postVia: postVia),
        );
      case RouteConstant.PhotoPostReviewScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return MaterialPageRoute(
          builder: (_) => PhotoPostReviewScreen(postVia: postVia),
        );
      case RouteConstant.videoPlayerScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final videoItem = args[ApiKeys.videoItem] as ShortFeedItem;
        final videoType = args[ApiKeys.videoType] as VideoType;
        return MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoItem: videoItem,
              videoType: videoType
          ),
        );
      case RouteConstant.journeyPlanningScreen:
        return MaterialPageRoute(
          builder: (_) => JourneyPlanningScreen(),
        );
      case RouteConstant.UpdateJourneyScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final journeyId = args[ApiKeys.journey_id] as String;
        return MaterialPageRoute(
          builder: (_) => UpdateJourneyScreen(
            journeyId: journeyId,
          ),
        );
      case RouteConstant.shortsPlayerScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final Shorts shorts = args[ApiKeys.shorts] as Shorts;
        final List<ShortFeedItem> videoItem =
            args[ApiKeys.videoItem] as List<ShortFeedItem>;
        final int initialIndex = args[ApiKeys.initialIndex] as int;
        return MaterialPageRoute(
          builder: (_) => ShortsPlayerScreen(
              shorts: shorts,
              initialShorts: videoItem,
              initialIndex: initialIndex),
        );
      case RouteConstant.CreateResumeScreen:
        return MaterialPageRoute(
          builder: (_) => CreateResumeScreen(),
        );
      case RouteConstant.ResumeTemplateScreen:
        return MaterialPageRoute(
          builder: (_) => ResumeTemplateScreen(),
        );
      case RouteConstant.ProductListingScreen:
        return MaterialPageRoute(
          builder: (_) => const ProductListingScreen(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.MyBookingScreen:
        return MaterialPageRoute(
          builder: (_) => const MyBookingsScreen(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.ReceivedBookingScreen:
        return MaterialPageRoute(
          builder: (_) => ReceivedBookingsScreen(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.VideographyTutorialScreen:
        return MaterialPageRoute(
          builder: (_) => VideographyTutorialScreen(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.ReceivedEnquiriesScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        return MaterialPageRoute(
          builder: (_) => ReceivedEnquiriesScreen(
            channelId: channelId,
          ),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.VideographyTutorialScreen2:
        return MaterialPageRoute(
          builder: (_) => const VideographyTutorialScreen2(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.MyEnquiresScreen:
        return MaterialPageRoute(
          builder: (_) => MyEnquiriesPage(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.SetAvailabilityScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        return MaterialPageRoute(
          builder: (_) => SetAvailabilityScreen(id: id),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.AppointmentBookingScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        final videoId = args[ApiKeys.videoId] as String;
        return MaterialPageRoute(
          builder: (_) => AppointmentBookingScreen(
            channelId: channelId,
            videoId: videoId,
          ),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.EnquiryForm:
        final args = settings.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        final videoId = args[ApiKeys.videoId] as String;
        return MaterialPageRoute(
          builder: (_) => SendEnquiryScreen(
            channelId: channelId,
            videoId: videoId,
          ),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.BookingAndEnquiresScreen:
        return MaterialPageRoute(
          builder: (_) => BookingsScreen(),
          settings: settings, // Pass the settings to preserve arguments
        );
      case RouteConstant.addUpdateProductScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String channelId = args[ApiKeys.channelId] as String;
        final ProductData? productData =
            args[ApiKeys.argProductData] as ProductData?;
        return MaterialPageRoute(
          builder: (_) => AddUpdateProductScreen(
              channelId: channelId, productData: productData),
          settings:
              RouteSettings(name: RouteHelper.getAddUpdateProductScreenRoute()),
        );
      case RouteConstant.addAccountScreen:
        return MaterialPageRoute(
            builder: (_) => AddAccountScreen(),
            settings: RouteSettings(
                name: RouteHelper.getAddAccountScreenRoute(),
                arguments: settings.arguments));
      case RouteConstant.addAccountUpiScreen:
        return MaterialPageRoute(
          builder: (_) => AddAccountUpiScreen(),
          settings: RouteSettings(
              name: RouteHelper.getAddAccountUpiScreenRoute(),
              arguments: settings.arguments),
        );

      case RouteConstant.walletScreen:
        return MaterialPageRoute(
          builder: (_) => WalletScreen(),
          settings: RouteSettings(
            name: RouteHelper.getWalletScreenRoute(),
          ),
        );
      case RouteConstant.allTransactionsScreen:
        return MaterialPageRoute(
          builder: (_) => SeeAllTransactionsView(),
          settings: RouteSettings(
            name: RouteHelper.getAllTransactionsScreen(),
          ),
        );
      case RouteConstant.DraftScreen:
        return MaterialPageRoute(
          builder: (_) => const DraftScreen(),
          settings: settings,
        );
      case RouteConstant.addDocumentScreen:
        return MaterialPageRoute(
            builder: (_) => AddDocumentScreen(),
            settings:
                RouteSettings(name: RouteHelper.getaddDocumentScreenRoute()));
      case RouteConstant.earnBlueeraScreen:
        return MaterialPageRoute(
            builder: (_) => EarnBlueeraScreen(),
            settings: RouteSettings(name: getearnBlueeraScreenRoute()));
      case RouteConstant.postDetailPage:
        return MaterialPageRoute(
            builder: (_) => PostDeatilPage(),
            settings: RouteSettings(name: getpostDetailPageRoute()));

     default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: CustomText('No route found')),
          ),
        );
    }
  }
}
