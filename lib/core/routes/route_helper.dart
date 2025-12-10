import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/business/business_verification/view/business_verification_screen.dart';
import 'package:BlueEra/features/business/business_verification/view/ownership_verification_screen.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/views/screens/gst_verification_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/Individual/add_bio_via_ai_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/Individual/personal_account_new_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/business/add_business_live_photo.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/business/create_business_account_new_step_one.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/business/create_business_account_new_step_three.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/business/create_business_account_new_step_two.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/create_new_account_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/mobile_number_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/otp_page_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/address_location_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/driving_verification_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_identification_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_information_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_images_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/add_grocery_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/add_grocery_variant_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_category_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_subcategory_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/grocery_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_category_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_screen.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step2.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';
import 'package:BlueEra/features/common/jobs/view/applied_screen/applied_jobs_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_overview_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_qna_screen.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_one.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_two.dart';
import 'package:BlueEra/features/common/map/view/category_selection_screen.dart';
import 'package:BlueEra/features/common/map/view/customize_map_screen.dart';
import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
import 'package:BlueEra/features/common/more/view/more_cards_screen.dart';
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
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/features/common/store/view/newstore_screen.dart';
import 'package:BlueEra/features/journey/view/journey_planning_screen.dart';
import 'package:BlueEra/features/journey/view/update_journy_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/my_enquires_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_enquiries_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/send_enquiry_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/earn_blueera_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/add_product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/add_product_via_ai_step1.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/add_product_via_ai_step2.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/create_varient_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/generate_ai_product_content.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/product_preview_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/store_product_preview_screen_product.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_business_cards_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents_screen/add_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/add_account_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_upi/add_accountupi_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/product_listing_screen/product_listing_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/add_flat_room_rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/home_stay_rental_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_full_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/vehicle_rental_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/see_all_transactions.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_screen.dart';
import 'package:BlueEra/features/personal/resume/create_resume_screen.dart';
import 'package:BlueEra/features/personal/resume/sections/resume_templates_screen.dart';
import 'package:BlueEra/permissionCentralize/permission_gate.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
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

  static String getOtpPageScreenRoute() =>
      RouteConstant.OtpPageScreen;

  // static String getSelectAccountScreenRoute() =>
  //     RouteConstant.SelectAccountScreen;

  // static String getCreateUserAccountRoute() =>
  //     RouteConstant.CreateUserAccount;

  static String getHomeScreenRoute() =>
      RouteConstant.HomeScreen;

  static String getSplashScreenRoute() =>
      RouteConstant.SplashScreen;

  static String getPermissionScreenRoute() =>
      RouteConstant.PermissionScreen;

  static String getAudioCallScreenRoute() =>
      RouteConstant.AudioCallScreen;

  // static String getBusinessAccountRoute() =>
  //     RouteConstant.BusinessAccount;

  // static String getAddEditVisitingCardScreenRoute() =>
  //     RouteConstant.AddEditVisitingCardScreen;

  static String getBottomNavigationBarScreenRoute() =>
      RouteConstant.BottomNavigationBarScreen;

  static String getPersonalProfileCreateScreenRoute() =>
      RouteConstant.PersonalProfileCreateScreen;

  static String getFeedScreenRoute() => RouteConstant.FeedScreen;



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


  static String getJobQnaScreenRoute() => RouteConstant.JobQnaScreen;

  static String getJobDetailsOverviewScreenRoute() =>
      RouteConstant.JobDetailsOverviewScreen;

  static String getAppliedJobsScreenRoute() => RouteConstant.AppliedJobsScreen;



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

  static String getTagPeopleScreenRoute() =>
      RouteConstant.tagPeopleScreen;

  static String getVideoReelRecorderScreenRoute() =>
      RouteConstant.videoRecorderScreen;

  static String getFullVideoPreviewRoute() =>
      RouteConstant.fullVideoPreview;

  static String getVideoTrimScreenRoute() =>
      RouteConstant.videoTrimScreen;

  static String getAllSongsScreenRoute() =>
      RouteConstant.allSongsScreen;

  static String getCreateMessagePostScreenRoute() =>
      RouteConstant.CreateMessagePostScreen;

  static String getPollInputScreenRoute() =>
      RouteConstant.PollInputScreen;

  static String getPollReviewScreenRoute() =>
      RouteConstant.PollReviewScreen;

  static String getPhotoPostScreenRoute() =>
      RouteConstant.PhotoPostScreen;

  static String getPhotoPostPreviewScreenRoute() =>
      RouteConstant.PhotoPostPreviewScreen;

  static String getPhotoPostReviewScreenRoute() =>
      RouteConstant.PhotoPostReviewScreen;

  static String getVideoPlayerScreenRoute() =>
      RouteConstant.videoPlayerScreen;

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

  static String getMyBookingScreenRoute() =>
      RouteConstant.MyBookingScreen;

  static String getReceivedBookingScreenRoute() =>
      RouteConstant.ReceivedBookingScreen;

  static String getVideographyTutorialScreenRoute() =>
      RouteConstant.VideographyTutorialScreen;

  static String getReceivedEnquiriesScreenRoute() =>
      RouteConstant.ReceivedEnquiriesScreen;

  static String getVideographyTutorialScreen2Route() =>
      RouteConstant.VideographyTutorialScreen2;

  static String getMyEnquiresRoute() =>
      RouteConstant.MyEnquiresScreen;

  static String sentEnquiresRoute() =>
      RouteConstant.EnquiryForm;

  static String getBookingAndEnquiresRoute() =>
      RouteConstant.BookingAndEnquiresScreen;

  static String getAvailabilityScreenRoute() =>
      RouteConstant.SetAvailabilityScreen;

  static String getAppointmentBookingScreenRoute() =>
      RouteConstant.AppointmentBookingScreen;

  static String getAddAccountScreenRoute() =>
      RouteConstant.addAccountScreen;

  static String getAddAccountUpiScreenRoute() =>
      RouteConstant.addAccountUpiScreen;

  static String getWalletScreenRoute() =>
      RouteConstant.walletScreen;

  static String getAllTransactionsScreen() =>
      RouteConstant.allTransactionsScreen;

  static String getEarnBlueEraScreenRoute() =>
      RouteConstant.earnBlueeraScreen;

  static String getAddDocumentScreenRoute() =>
      RouteConstant.addDocumentScreen;

  static String getPostDetailPageRoute() =>
      RouteConstant.postDetailPage;

  static String getMoreCardsScreenRoute() =>
      RouteConstant.moreCardsScreen;

  static String getAddProductScreenRoute() =>
      RouteConstant.addProductScreen;

  // static String getListingFormScreenRoute() =>
  //      RouteConstant.listingFormScreen;

  static String getInventoryScreenRoute() =>
      RouteConstant.inventoryScreen;

  static String getAddServicesScreenRoute() =>
      RouteConstant.addServicesScreen;

  static String getAddProductViaAiStep1Route() =>
      RouteConstant.addProductViaAiStep1;

  static String getAddProductViaAiStep2Route() =>
      RouteConstant.addProductViaAiStep2;

  static String getProductPreviewScreenRoute() =>
      RouteConstant.productPreviewScreen;

  static String getCreateVariantScreenRoute() =>
      RouteConstant.createVariantScreen;

  static String getStoreProductPreviewScreenProductRoute() =>
      RouteConstant.storeProductPreviewScreenProduct;

  static String getStoreFeedScreenRoute() =>
      RouteConstant.storeFeedScreen;

  static String getEarnWithBlueEraNewScreenRoute() =>
      RouteConstant.earnWithBlueEraNewScreen;

  static String getInventoryBusinessCardsScreenRoute() =>
      RouteConstant.inventoryBusinessCardsScreen;

  static String getFoodUploadScreenRoute() =>
      RouteConstant.foodUploadScreen;

  static String getAddFlatRoomRentalServiceScreenRoute() =>
      RouteConstant.addFlatRoomRentalServiceScreen;

  static String getPersonalInformationRidingScreenRoute() =>
      RouteConstant.personalInformationRidingScreen;

  static String getAddressLocationRidingScreenRoute() =>
      RouteConstant.addressLocationRidingScreen;

  static String getPersonalIdentificationRidingScreenRoute() =>
      RouteConstant.personalIdentificationRidingScreen;

  static String getDrivingVerificationRidingScreenRoute() =>
      RouteConstant.drivingVerificationRidingScreen;

  static String getVehicleImagesRidingScreenRoute() =>
      RouteConstant.vehicleImagesRidingScreen;

  static String getVehicleInformationRidingScreenRoute() =>
      RouteConstant.vehicleInformationRidingScreen;

  static String getHomeStayRentalServiceRoute() =>
      RouteConstant.homeStayRentalService;

  static String getVehicleRentalServiceRoute() =>
      RouteConstant.vehicleRentalService;

  static String getRentalServiceScreenRoute() =>
      RouteConstant.rentalServiceScreen;

  static String getRentalServiceFullDetailsScreenRoute() =>
      RouteConstant.rentalServiceFullDetailsScreen;

  static String getCreateNewAccountScreenRoute() =>
      RouteConstant.createNewAccountScreen;

  static String getCreateBusinessAccountNewStepOneRoute() =>
      RouteConstant.createBusinessAccountNewStepOne;

  static String getCreateBusinessAccountNewStepTwoRoute() =>
      RouteConstant.createBusinessAccountNewStepTwo;

  static String getCreateBusinessAccountNewStepThreeRoute() =>
      RouteConstant.createBusinessAccountNewStepThree;

  static String getAddBusinessLivePhotoRoute() =>
      RouteConstant.addBusinessLivePhoto;

  static String getPersonalAccountNewScreenRoute() =>
      RouteConstant.personalAccountNewScreen;

  static String getGstNumberScreenRoute() =>
      RouteConstant.gstNumberScreen;

  static String getAddBioViaAiScreenRoute() =>
      RouteConstant.addBioViaAiScreen;

  static String getGroceryScreenRoute() =>
      RouteConstant.groceryScreen;

  static String getGroceryCategoryScreenRoute() =>
      RouteConstant.groceryCategoryScreen;

  static String getGrocerySubCategoryScreenRoute() =>
      RouteConstant.grocerySubCategoryScreen;

  static String getAddGroceryScreenRoute() =>
      RouteConstant.addGroceryScreen;

  static String getAddGroceryVariantScreenRoute() =>
      RouteConstant.addGroceryVariantScreen;

  static String getMyGroceryCategoryScreenRoute() =>
      RouteConstant.myGroceryCategoryScreen;

  static String getMyGroceryScreenRoute() =>
      RouteConstant.myGroceryScreen;

  ///REDIRECT ROUTING SETUP.....
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstant.PermissionScreen:
        return MaterialPageRoute(
          builder: (_) => PermissionGate(),
          settings: RouteSettings(name: RouteHelper.getPermissionScreenRoute()),
        );
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
      // case RouteConstant.SelectAccountScreen:
      //   return MaterialPageRoute(builder: (_) => CreateAccountScreen());
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
        final args = settings.arguments as Map<dynamic, dynamic>?;
        int? initialIndex = args?[ApiKeys.initialIndex];
        return MaterialPageRoute(
          builder: (_) => BottomNavigationBarScreen(
              initialIndex: initialIndex,
              ),
          settings: RouteSettings(
              name: RouteHelper.getBottomNavigationBarScreenRoute()),
        );
      // case RouteConstant.CreateUserAccount:
      //   final args = settings.arguments as Map<String, dynamic>;
      //   final accountType = args[ApiKeys.argAccountType] as String;
      //   final businessType = args[ApiKeys.argBusinessType] as BusinessType?;
      //   final categoryData = args[ApiKeys.argCategoryData] as CategoryData?;
      //   final subCategory = args[ApiKeys.argSubCategory] as SubCategories?;
      //
      //   return MaterialPageRoute(
      //     builder: (_) => CreateUserAccount(
      //       accountType: accountType,
      //       businessType: businessType,
      //       categoryData: categoryData,
      //       subCategory: subCategory,
      //     ),
      //     settings: RouteSettings(name: RouteHelper.getCreateUserAccountRoute())
      //   );
      // case RouteConstant.BusinessAccount:
      //   return MaterialPageRoute(builder: (_) => BusinessAccountScreen());
      // case RouteConstant.AddEditVisitingCardScreen:
      //   // final companyData =
      //   //     args[ApiKeys.argCompanyData] != null ? args[ApiKeys.argCompanyData] as GetMyProfileModel : null;
      //   return MaterialPageRoute(builder: (_) => BusinessDetailsEditPageOne());
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
              video: videoPath, images: images, audioUrl: audioUrl, song: song),
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
          builder: (_) =>
              VideoPlayerScreen(videoItem: videoItem, videoType: videoType),
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
        final String channelId = args[ApiKeys.channelId] as String;
        final AvailabilityModel? availabilityBookingData = args[ApiKeys.availabilityBookingData] as AvailabilityModel?;
        return MaterialPageRoute(
          builder: (_) => SetAvailabilityScreen(
              id: channelId,
              availabilityBookingData: availabilityBookingData
          ),
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
      case RouteConstant.addDocumentScreen:
        return MaterialPageRoute(
            builder: (_) => AddDocumentScreen(),
            settings:
                RouteSettings(name: RouteHelper.getAddDocumentScreenRoute()));
      case RouteConstant.earnBlueeraScreen:
        return MaterialPageRoute(
            builder: (_) => EarnBlueeraScreen(),
            settings: RouteSettings(name: getEarnBlueEraScreenRoute()));
      case RouteConstant.postDetailPage:
        return MaterialPageRoute(
            builder: (_) => PostDeatilPage(),
            settings: RouteSettings(name: getPostDetailPageRoute()));
      case RouteConstant.moreCardsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final bool isFromHomeScreen = args[ApiKeys.isFromHomeScreen] as bool;
        final double? headerHeight = args[ApiKeys.headerHeight] as double?;
        final onHeaderVisibilityChanged =
            args[ApiKeys.onHeaderVisibilityChanged] as Function(bool)?;

        return MaterialPageRoute(
            builder: (_) => MoreCardsScreen(
                  isFromHomeScreen: isFromHomeScreen,
                  headerHeight: headerHeight,
                  onHeaderVisibilityChanged: onHeaderVisibilityChanged,
                ),
            settings: RouteSettings(name: getMoreCardsScreenRoute()));
      case RouteConstant.addProductScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;

        return MaterialPageRoute(
            builder: (_) => AddProductScreen(
              id: id,
              providerType: providerType,
            ),
            settings: RouteSettings(name: getAddProductScreenRoute()));
      // case RouteConstant.listingFormScreen:
      //   return MaterialPageRoute(
      //       builder: (_) => ListingFormScreen(),
      //       settings: RouteSettings(name: getListingFormScreenRoute()));
      case RouteConstant.inventoryScreen:
        return MaterialPageRoute(
            builder: (_) => InventoryScreen(),
            settings: RouteSettings(name: getInventoryScreenRoute()));
      case RouteConstant.addServicesScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;
        final EarnWithBlueEraServiceTypes? serviceSubType = args[ApiKeys.serviceSubType] as EarnWithBlueEraServiceTypes?;
        final bool? isFromEarnWithBlueEraService = args[ApiKeys.isFromEarnWithBlueEraService] as bool?;
        final String? designation = args[ApiKeys.designation] as String?;
        final String? channelId = args[ApiKeys.channelId] as String?;

        return MaterialPageRoute(
            builder: (_) => ServiceUploadScreen(
              providerType: providerType,
              isFromEarnWithBlueEraService: isFromEarnWithBlueEraService,
              channelId: channelId,
              designation: designation,
              serviceSubType: serviceSubType,
            ),
            // builder: (_) => AddServicesScreen(),
            settings: RouteSettings(name: getAddServicesScreenRoute()));
      case RouteConstant.addProductViaAiStep1:
        final args = settings.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;

        return MaterialPageRoute(
            builder: (_) => AddProductViaAiStep1(
                id: id,
              providerType: providerType
            ),
            settings: RouteSettings(name: getAddProductViaAiStep1Route()));
      case RouteConstant.addProductViaAiStep2:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final GenerateAiProductContent generateAiProductContent =
            args[ApiKeys.generateAiProductContent] as GenerateAiProductContent;
        final String id = args[ApiKeys.id] as String;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;

        return MaterialPageRoute(
            builder: (_) => AddProductViaAiStep2(
                controller: controller,
                generateAiProductContent: generateAiProductContent,
                id: id,
                providerType: providerType,
            ),
            settings: RouteSettings(name: getAddProductViaAiStep2Route()));
      // case RouteConstant.productPreviewScreen:
      //   final args = settings.arguments as Map<String, dynamic>?;
      //   final OwnProductData? productData =
      //       args?[ApiKeys.argProductData] as OwnProductData?;
      //
      //   return MaterialPageRoute(
      //       builder: (_) => ProductPreviewScreen(productData: productData),
      //       settings: RouteSettings(name: getProductPreviewScreenRoute()));
        case RouteConstant.productPreviewScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final ProductPreviewArgs? argProductData =
            args?[ApiKeys.argProductData] as ProductPreviewArgs?;
        final bool? isFromProductCreation = args?[ApiKeys.isFromProductCreation] as bool?;
        final bool? isUserCanCreateVariants = args?[ApiKeys.isUserCanCreateVariants] as bool?;
        final String? id = args?[ApiKeys.id] as String?;
        final ProductServiceProviderType? providerType = args?[ApiKeys.providerType] as ProductServiceProviderType?;

        return MaterialPageRoute(
            builder: (_) => ProductPreviewScreen(
                id: id,
                providerType: providerType,
                productPreviewArgs: argProductData,
                isFromProductCreation: isFromProductCreation ?? false,
                isUserCanCreateVariants: isUserCanCreateVariants ?? true,

            ),
            settings: RouteSettings(name: getProductPreviewScreenRoute()));
      case RouteConstant.storeProductPreviewScreenProduct:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductStore? productStore =
            args[ApiKeys.argProductData] as ProductStore?;
        // final bool? productDataBool = args["isShowBusinessInfo"] as bool?;
        final String id = args[ApiKeys.id] as String;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;

        return MaterialPageRoute(
            builder: (_) => StoreProductPreviewScreenProduct(
                  productStore: productStore,
                  // isShowBusinessInfo: productDataBool,
                  id: id,
                  providerType: providerType
                ),
            settings:
                RouteSettings(name: getStoreProductPreviewScreenProductRoute()));
      case RouteConstant.createVariantScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final String id = args[ApiKeys.id] as String;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;

        return MaterialPageRoute(
            builder: (_) => CreateVariantScreen(
                controller: controller,
                id: id,
                providerType: providerType,
            ),
            settings: RouteSettings(name: getCreateVariantScreenRoute()));

      case RouteConstant.storeFeedScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final isHeaderVisible = args[ApiKeys.isHeaderVisible] as bool;
        final onHeaderVisibilityChanged =
        args[ApiKeys.onHeaderVisibilityChanged] as Function(bool)?;
        return MaterialPageRoute(
            builder: (_) => StoreFeedScreen(
              isHeaderVisible: isHeaderVisible,
              onHeaderVisibilityChanged: onHeaderVisibilityChanged
            ),
            settings: RouteSettings(name: getStoreFeedScreenRoute()));
      case RouteConstant.earnWithBlueEraNewScreen:
        return MaterialPageRoute(
            builder: (_) => EarnWithBlueEraNewScreen(),
            settings: RouteSettings(name: getEarnWithBlueEraNewScreenRoute()));
     case RouteConstant.inventoryBusinessCardsScreen:
        return MaterialPageRoute(
            builder: (_) => InventoryBusinessCardsScreen(),
            settings: RouteSettings(name: getInventoryBusinessCardsScreenRoute()));
      case RouteConstant.foodUploadScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductServiceProviderType providerType = args[ApiKeys.providerType] as ProductServiceProviderType;
        final EarnWithBlueEraServiceTypes? serviceSubType = args[ApiKeys.serviceSubType] as EarnWithBlueEraServiceTypes?;
        final String? category = args[ApiKeys.category] as String?;

        return MaterialPageRoute(
            builder: (_) => FoodUploadScreen(
                providerType: providerType,
                serviceSubType: serviceSubType,
                category: category
            ),
            settings: RouteSettings(name: getFoodUploadScreenRoute()));
      case RouteConstant.addFlatRoomRentalServiceScreen:
        return MaterialPageRoute(
            builder: (_) => AddFlatRoomRentalServiceScreen(),
            settings: RouteSettings(name: getAddFlatRoomRentalServiceScreenRoute()));
      case RouteConstant.personalInformationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => PersonalInformationRidingScreen(),
            settings: RouteSettings(name: getPersonalInformationRidingScreenRoute()));
      case RouteConstant.addressLocationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => AddressLocationRidingScreen(),
            settings: RouteSettings(name: getAddressLocationRidingScreenRoute()));
      case RouteConstant.personalIdentificationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => PersonalIdentificationRidingScreen(),
            settings: RouteSettings(name: getPersonalIdentificationRidingScreenRoute()));
      case RouteConstant.drivingVerificationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => DrivingVerificationRidingScreen(),
            settings: RouteSettings(name: getDrivingVerificationRidingScreenRoute()));
      case RouteConstant.vehicleImagesRidingScreen:
        return MaterialPageRoute(
            builder: (_) => VehicleImagesRidingScreen(),
            settings: RouteSettings(name: getVehicleImagesRidingScreenRoute()));
      case RouteConstant.vehicleInformationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => VehicleInformationRidingScreen(),
            settings: RouteSettings(name: getVehicleInformationRidingScreenRoute()));
      case RouteConstant.homeStayRentalService:
        return MaterialPageRoute(
            builder: (_) => HomeStayRentalService(),
            settings: RouteSettings(name: getHomeStayRentalServiceRoute()));
      case RouteConstant.vehicleRentalService:
        return MaterialPageRoute(
            builder: (_) => VehicleRentalService(),
            settings: RouteSettings(name: getVehicleRentalServiceRoute()));
      case RouteConstant.rentalServiceScreen:
        return MaterialPageRoute(
            builder: (_) => RentalServiceScreen(),
            settings: RouteSettings(name: getRentalServiceScreenRoute()));
      case RouteConstant.rentalServiceFullDetailsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final RentalServiceData rentalServiceData = args[ApiKeys.argRentalData] as RentalServiceData;
        return MaterialPageRoute(
            builder: (_) => RentalServiceFullDetailsScreen(
                rentalServiceData: rentalServiceData
            ),
            settings: RouteSettings(name: getRentalServiceFullDetailsScreenRoute()));
      case RouteConstant.createNewAccountScreen:
        // final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => CreateNewAccountScreen(),
           settings: RouteSettings(name: getCreateNewAccountScreenRoute())
          );
      case RouteConstant.createBusinessAccountNewStepOne:
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepOne(),
            settings: RouteSettings(name: getCreateBusinessAccountNewStepOneRoute())
        );
      case RouteConstant.createBusinessAccountNewStepTwo:
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepTwo(),
            settings: RouteSettings(name: getCreateBusinessAccountNewStepTwoRoute())
        );
      case RouteConstant.createBusinessAccountNewStepThree:
        final args = settings.arguments as Map<String, dynamic>;
        final String? city = args[ApiKeys.city] as String?;
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepThree(
                city: city
            ),
            settings: RouteSettings(name: getCreateBusinessAccountNewStepThreeRoute())
        );
      case RouteConstant.addBusinessLivePhoto:
        return MaterialPageRoute(
            builder: (_) => AddBusinessLivePhoto(),
            settings: RouteSettings(name: getAddBusinessLivePhotoRoute())
        );
      case RouteConstant.personalAccountNewScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final professionTagId = args[ApiKeys.argProfessionTagId] as String;
        final professionSubCategory = args[ApiKeys.argProfessionSubCategory] as List<SubcategoriesFiledName>?;
        final selfEmployment = args[ApiKeys.argSelfEmployment] as String?;
        final selfEmploymentTagId = args[ApiKeys.argSelfEmploymentTagId] as String?;

        return MaterialPageRoute(
            builder: (_) => PersonalAccountNewScreen(
              accountType: accountType,
              professionTagId: professionTagId,
              professionSubCategory: professionSubCategory,
              selfEmployment: selfEmployment,
              selfEmploymentTagId: selfEmploymentTagId,
            ),
            settings: RouteSettings(name: RouteHelper.getPersonalAccountNewScreenRoute())
        );

      case RouteConstant.gstNumberScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final businessType = args[ApiKeys.argBusinessType] as BusinessType;
        final categoryData = args[ApiKeys.argCategoryData] as CategoryData?;
        final subCategory = args[ApiKeys.argSubCategory] as SubCategories?;

        return MaterialPageRoute(
            builder: (_) => GstNumberScreen(
              accountType: accountType,
              businessType: businessType,
              categoryData: categoryData,
              subCategory: subCategory,
            ),
            settings: RouteSettings(name: RouteHelper.getGstNumberScreenRoute())
        );
      case RouteConstant.addBioViaAiScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final profession = args[ApiKeys.argProfession] as String;
        final designation = args[ApiKeys.argDesignation] as String?;
        final selectedDay = args[ApiKeys.argSelectedDay] as int?;
        final selectedMonth = args[ApiKeys.argSelectedMonth] as int?;
        final selectedYear = args[ApiKeys.argSelectedYear] as int?;

        return MaterialPageRoute(
            builder: (_) => AddBioViaAiScreen(
              profession: profession,
              designation: designation,
              selectedDay: selectedDay,
              selectedMonth: selectedMonth,
              selectedYear: selectedYear
            ),
            settings: RouteSettings(name: getAddBioViaAiScreenRoute())
        );

      case RouteConstant.groceryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final bool? argFromBottomNavBar = args[ApiKeys.argFromBottomNavBar] as bool?;
        return MaterialPageRoute(
            builder: (_) => GroceryScreen(
                fromBottomNavBar: argFromBottomNavBar
            ),
            settings: RouteSettings(name: getGroceryScreenRoute())
        );
      case RouteConstant.groceryCategoryScreen:
        return MaterialPageRoute(
            builder: (_) => GroceryCategoryScreen(),
            settings: RouteSettings(name: getGroceryCategoryScreenRoute())
        );
      case RouteConstant.grocerySubCategoryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<CollapsibleGridModel> argGroceries = args[ApiKeys.argGroceries] as List<CollapsibleGridModel>;
        final CollapsibleGridModel argSelectedGroceryData = args[ApiKeys.argSelectedGroceryData] as CollapsibleGridModel;
        return MaterialPageRoute(
            builder: (_) => GrocerySubCategoryScreen(
                arrGroceries: argGroceries,
                selectedGroceryData: argSelectedGroceryData
            ),
            settings: RouteSettings(name: getGrocerySubCategoryScreenRoute())
        );
      case RouteConstant.addGroceryScreen:
        return MaterialPageRoute(
            builder: (_) => AddGroceryScreen(),
            settings: RouteSettings(name: getAddGroceryScreenRoute())
        );
      case RouteConstant.addGroceryVariantScreen:
        return MaterialPageRoute(
            builder: (_) => AddGroceryVariantScreen(),
            settings: RouteSettings(name: getAddGroceryVariantScreenRoute())
        );
      case RouteConstant.myGroceryCategoryScreen:
        return MaterialPageRoute(
            builder: (_) => MyGroceryCategoryScreen(),
            settings: RouteSettings(name: getMyGroceryCategoryScreenRoute())
        );
      case RouteConstant.myGroceryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String argCategoryId = args[ApiKeys.argCategoryId] as String;
        final bool? argIsShowInGrid = args[ApiKeys.argIsShowInGrid] as bool?;
        return MaterialPageRoute(
            builder: (_) => MyGroceryScreen(
                categoryId: argCategoryId,
                isShowInGrid: argIsShowInGrid
            ),
            settings: RouteSettings(name: getMyGroceryScreenRoute())
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: CustomText('No route found')),
          ),
        );
    }
  }
}
