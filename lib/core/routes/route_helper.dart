import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_list_screen.dart';
import 'package:BlueEra/features/chat/view/call_screen/outgoing_call_screen.dart';
import 'package:BlueEra/features/chat/view/call_screen/incoming_call_screen.dart';
import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/features/me/food/view/add_food_snap_search_screen.dart';
import 'package:BlueEra/features/me/food/view/add_single_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/food_ai_details_screen.dart';
import 'package:BlueEra/features/me/food/view/food_customer_listing_screen.dart';
import 'package:BlueEra/features/me/food/view/food_entry_ai_screen.dart';
import 'package:BlueEra/features/me/food/view/food_product_selection_screen.dart';
import 'package:BlueEra/features/me/food/view/food_review_selection_screen.dart';
import 'package:BlueEra/features/me/food/view/missing_food_itmes_screen.dart';
import 'package:BlueEra/features/me/food/view/other_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/view/add_grocery_snap_search_screen.dart';
import 'package:BlueEra/features/me/grocery/view/missing_grocery_items_screen.dart';
import 'package:BlueEra/features/me/grocery/view/other_grocery_store_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_nested_category_with_inventory_screen.dart';
import 'package:share_handler/share_handler.dart';
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
import 'package:BlueEra/features/common/auth/views/screens/new_screens/create_account_type_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/mobile_number_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/otp_page_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/address_location_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/driving_verification_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_identification_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_information_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_store/rider_store_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_images_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
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
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/view/add_grocery_screen.dart';
import 'package:BlueEra/features/me/grocery/view/add_grocery_variant_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_listing/grocery_cart_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_listing/grocery_confirm_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_listing/grocery_listing_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_nested_category_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_or_food_stores_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_products_selection_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_super_category_screen.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_screen.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/my_grocery_variant_screen.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/model/my_medical_products_response.dart';
import 'package:BlueEra/features/me/medical_new/view/add_medical_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/add_medical_variant_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_category_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_listing/medical_cart_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_listing/medical_confirm_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_listing/medical_listing_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_subcategory_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/my_medical_listing/my_medical_products_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/my_medical_listing/my_medical_variant_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/my_enquires_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_enquiries_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/send_enquiry_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/add_self_work_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_available_options_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/rider_service_screen.dart';
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
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/view/add_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/add_bank_account_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
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
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import '../../features/chat/view/contacts/view/contact_list_page.dart';
import '../../features/common/auth/model/onboarding_category_model.dart';
import '../../features/me/grocery/model/my_grocery_products_reponse.dart';
import '../../features/common/store/add_update_product/add_update_product_screen.dart';
import '../../features/common/store/models/get_channel_product_model.dart';
import '../../features/me/medical/view/category/otc_items_page.dart';
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

  // static String getSelectAccountScreenRoute() =>
  //     RouteConstant.SelectAccountScreen;

  // static String getCreateUserAccountRoute() =>
  //     RouteConstant.CreateUserAccount;

  static String getHomeScreenRoute() => RouteConstant.HomeScreen;

  static String getSplashScreenRoute() => RouteConstant.SplashScreen;

  static String getPermissionScreenRoute() => RouteConstant.PermissionScreen;

  static String getAudioCallScreenRoute() => RouteConstant.AudioCallScreen;

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

  static String sentEnquiresRoute() => RouteConstant.EnquiryForm;

  static String getBookingAndEnquiresRoute() =>
      RouteConstant.BookingAndEnquiresScreen;

  static String getAvailabilityScreenRoute() =>
      RouteConstant.setAvailabilityScreen;

  static String getAppointmentBookingScreenRoute() =>
      RouteConstant.AppointmentBookingScreen;

  static String getAddBankAccountScreenRoute() =>
      RouteConstant.addBankAccountScreen;

  static String getAddAccountUpiScreenRoute() =>
      RouteConstant.addAccountUpiScreen;

  static String getWalletScreenRoute() => RouteConstant.walletScreen;

  static String getAllTransactionsScreen() =>
      RouteConstant.allTransactionsScreen;

  static String getAddDocumentScreenRoute() => RouteConstant.addDocumentScreen;

  static String getPostDetailPageRoute() => RouteConstant.postDetailPage;

  static String getMoreCardsScreenRoute() => RouteConstant.moreCardsScreen;

  static String getAddProductScreenRoute() => RouteConstant.addProductScreen;

  // static String getListingFormScreenRoute() =>
  //      RouteConstant.listingFormScreen;

  static String getInventoryScreenRoute() => RouteConstant.inventoryScreen;

  static String getAddServicesScreenRoute() => RouteConstant.addServicesScreen;

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

  static String getStoreFeedScreenRoute() => RouteConstant.storeFeedScreen;

  static String getEarnServiceScreenRoute() => RouteConstant.earnServiceScreen;

  static String getInventoryBusinessCardsScreenRoute() =>
      RouteConstant.inventoryBusinessCardsScreen;

  static String getFoodUploadScreenRoute() => RouteConstant.foodUploadScreen;

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

  // static String getCreateNewAccountScreenRoute() =>
  //     RouteConstant.createNewAccountScreen;

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

  static String getGstNumberScreenRoute() => RouteConstant.gstNumberScreen;

  static String getAddBioViaAiScreenRoute() => RouteConstant.addBioViaAiScreen;

  static String getGroceryScreenRoute() => RouteConstant.groceryScreen;

  static String getGroceryCategoryScreenRoute() =>
      RouteConstant.groceryCategoryScreen;

  static String getGroceryProductsSelectionScreenRoute() =>
      RouteConstant.groceryProductsSelectionScreen;

  static String getAddGroceryScreenRoute() => RouteConstant.addGroceryScreen;

  static String getAddGroceryVariantScreenRoute() =>
      RouteConstant.addGroceryVariantScreen;

  static String getGroceryProductsScreenRoute() =>
      RouteConstant.groceryProductsScreen;

  static String getMyGroceryVariantScreenRoute() =>
      RouteConstant.MyGroceryVariantScreen;

  static String getGroceryCustomerListingScreenRoute() =>
      RouteConstant.groceryCustomerListingScreen;

  static String getRiderServiceScreenRoute() =>
      RouteConstant.riderServiceScreen;

  static String getGroceryCartScreenRoute() =>
      RouteConstant.groceryCartScreen;

  // static String getRiderProfileStatusScreenRoute() =>
  //     RouteConstant.RiderProfileStatusScreen;

  static String getGrocerySuperCategoryScreenRoute() =>
      RouteConstant.grocerySuperCategoryScreen;

  static String getPaymentSettingScreenRoute() =>
      RouteConstant.paymentSettingScreen;

  static String getMedicalOtcItemsScreen() =>
      RouteConstant.medicalOtcItemsScreen;

  static String getHospitalOptCategory() => RouteConstant.hospitalOptCategory;

  static String getHospitalDoctorViewCategory() =>
      RouteConstant.hospitalDoctorViewCategory;

  static String getHospitalWardViewCategory() =>
      RouteConstant.hospitalWardViewCategory;

  static String getRiderStoreScreenRoute() =>
      RouteConstant.riderStoreScreen;

  static String getGroceryConfirmScreenRoute() =>
      RouteConstant.groceryConfirmScreen;

  static String getAddSelfServiceRoute() =>
      RouteConstant.addSelfServiceScreen;

  static String getCreateAccountTypeScreenRoute() =>
      RouteConstant.createAccountTypeScreen;

  static String getEarnServiceAvailableOptionsScreenRoute() =>
      RouteConstant.earnServiceAvailableOptionsScreen;

  static String getMedicalScreenRoute() =>
      RouteConstant.medicalScreen;

  static String getMedicalCategoryScreenRoute() =>
      RouteConstant.medicalCategoryScreen;

  static String getMedicalSubCategoryScreenRoute() =>
      RouteConstant.medicalSubCategoryScreen;

  static String getAddMedicalScreenRoute  () =>
      RouteConstant.addMedicalScreen;

  static String getAddMedicalVariantScreenRoute() =>
      RouteConstant.addMedicalVariantScreen;

  static String getMyMedicalProductsScreenRoute() =>
      RouteConstant.myMedicalProductsScreen;

  static String getMyMedicalVariantScreenRoute() =>
      RouteConstant.myMedicalVariantScreen;

  static String getMedicalListingScreenRoute() =>
      RouteConstant.medicalListingScreen;

  static String getMedicalCartScreenRoute() =>
      RouteConstant.medicalCartScreen;

  static String getMedicalConfirmScreenRoute() =>
      RouteConstant.medicalConfirmScreen;

  static String getHospitalDepartmentsScreenRoute() =>
      RouteConstant.hospitalDepartmentsScreen;

  static String getGroceryOrFoodStoresScreenRoute() =>
      RouteConstant.groceryOrFoodStoresScreen;

  static String getAddGrocerySnapSearchScreenRoute() =>
      RouteConstant.addGrocerySnapSearchScreen;

 static String getMissingGroceryItemsScreenRoute() =>
      RouteConstant.missingGroceryItemsScreen;

  static String getMissingFoodItemsScreenRoute() =>
      RouteConstant.missingFoodItemsScreen;

 static String getOtherGroceryStoreScreenRoute() =>
      RouteConstant.otherGroceryStoreScreen;

  static String getOtherFoodStoreDetailsScreenRoute() =>
      RouteConstant.otherFoodStoreDetailsScreen;

  static String getAddFoodSnapSearchScreenRoute() =>
      RouteConstant.addFoodSnapSearchScreen;

  static String getGroceryNestedCategoryWithInventoryScreenRoute() =>
      RouteConstant.groceryNestedCategoryWithInventoryScreen;

  static String getAddSingleProductScreenRoute() =>
      RouteConstant.addSingleProductScreen;

  static String getProductSelectionScreenRoute() =>
      RouteConstant.productSelectionScreen;

  static String getFoodEntryAiScreenRoute() =>
      RouteConstant.foodEntryAiScreen;

  static String getFoodAiDetailScreenRoute() =>
      RouteConstant.foodAiDetailScreen;

  static String getFoodCustomerListingScreenRoute() =>
      RouteConstant.foodCustomerListingScreen;

  static String getFoodReviewSelectionScreenRoute() =>
      RouteConstant.foodReviewSelectionScreen;


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
        SharedMedia? sharedMedia = args?['sharedMedia'] as SharedMedia?;
        return MaterialPageRoute(
          builder: (_) => BottomNavigationBarScreen(
            initialIndex: initialIndex,
            sharedMedia: sharedMedia,
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
        final createJobVia = args?['createJobVia'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => CreateJobPostScreen(
            isEditMode: isEditMode,
            jobId: jobId,
            createJobVia: createJobVia,
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
      case RouteConstant.setAvailabilityScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String argId = args[ApiKeys.argId] as String;
        return MaterialPageRoute(
          builder: (_) => SetAvailabilityScreen(id: argId),
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
      case RouteConstant.addBankAccountScreen:
        return MaterialPageRoute(
            builder: (_) => AddBankAccountScreen(),
            settings: RouteSettings(
                name: RouteHelper.getAddBankAccountScreenRoute(),
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
        final Map<String, dynamic>? args =
        settings.arguments as Map<String, dynamic>?;

        final String argDocumentVia =
            args?[ApiKeys.argDocumentVia] as String? ?? "";
        final bool showViewDocProof =
            args?[ApiKeys.showViewDocProof] as bool? ?? false;

        return MaterialPageRoute(
            builder: (_) => AddDocumentScreen(
                showViewDocProof: showViewDocProof,
                documentVia: argDocumentVia
            ),
            settings:
                RouteSettings(name: RouteHelper.getAddDocumentScreenRoute()));
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
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;

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
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        final EarnServiceTypes? serviceSubType =
            args[ApiKeys.serviceSubType] as EarnServiceTypes?;
        final bool? isFromEarnWithBlueEraService =
            args[ApiKeys.isFromEarnWithBlueEraService] as bool?;
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
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;

        return MaterialPageRoute(
            builder: (_) =>
                AddProductViaAiStep1(id: id, providerType: providerType),
            settings: RouteSettings(name: getAddProductViaAiStep1Route()));
      case RouteConstant.addProductViaAiStep2:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final GenerateAiProductContent generateAiProductContent =
            args[ApiKeys.generateAiProductContent] as GenerateAiProductContent;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;

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
        final bool? isFromProductCreation =
            args?[ApiKeys.isFromProductCreation] as bool?;
        final bool? isUserCanCreateVariants =
            args?[ApiKeys.isUserCanCreateVariants] as bool?;
        final String? id = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;

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
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;

        return MaterialPageRoute(
            builder: (_) => StoreProductPreviewScreenProduct(
                productStore: productStore,
                // isShowBusinessInfo: productDataBool,
                id: id,
                providerType: providerType),
            settings: RouteSettings(
                name: getStoreProductPreviewScreenProductRoute()));
      case RouteConstant.createVariantScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;

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
                onHeaderVisibilityChanged: onHeaderVisibilityChanged),
            settings: RouteSettings(name: getStoreFeedScreenRoute()));
      case RouteConstant.earnServiceScreen:
        return MaterialPageRoute(
            builder: (_) => EarnServiceScreen(),
            settings: RouteSettings(name: getEarnServiceScreenRoute()));
      case RouteConstant.inventoryBusinessCardsScreen:
        return MaterialPageRoute(
            builder: (_) => InventoryBusinessCardsScreen(),
            settings:
                RouteSettings(name: getInventoryBusinessCardsScreenRoute()));
      case RouteConstant.foodUploadScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        final EarnServiceTypes? serviceSubType =
            args[ApiKeys.serviceSubType] as EarnServiceTypes?;
        final String? category = args[ApiKeys.category] as String?;

        return MaterialPageRoute(
            builder: (_) => FoodUploadScreen(
                providerType: providerType,
                serviceSubType: serviceSubType,
                category: category),
            settings: RouteSettings(name: getFoodUploadScreenRoute()));
      case RouteConstant.addFlatRoomRentalServiceScreen:
        return MaterialPageRoute(
            builder: (_) => AddFlatRoomRentalServiceScreen(),
            settings:
                RouteSettings(name: getAddFlatRoomRentalServiceScreenRoute()));
      case RouteConstant.personalInformationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => PersonalInformationRidingScreen(
                  screeName: '',
                ),
            settings:
                RouteSettings(name: getPersonalInformationRidingScreenRoute()));
      case RouteConstant.addressLocationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => AddressLocationRidingScreen(
                  screeName: '',
                ),
            settings:
                RouteSettings(name: getAddressLocationRidingScreenRoute()));
      case RouteConstant.personalIdentificationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => PersonalIdentificationRidingScreen(),
            settings: RouteSettings(
                name: getPersonalIdentificationRidingScreenRoute()));
      case RouteConstant.drivingVerificationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => DrivingVerificationRidingScreen(),
            settings:
                RouteSettings(name: getDrivingVerificationRidingScreenRoute()));
      case RouteConstant.vehicleImagesRidingScreen:
        return MaterialPageRoute(
            builder: (_) => VehicleImagesRidingScreen(),
            settings: RouteSettings(name: getVehicleImagesRidingScreenRoute()));
      case RouteConstant.vehicleInformationRidingScreen:
        return MaterialPageRoute(
            builder: (_) => VehicleInformationRidingScreen(
              screeName: '',
            ),
            settings:
                RouteSettings(name: getVehicleInformationRidingScreenRoute()));
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
        final RentalServiceData rentalServiceData =
            args[ApiKeys.argRentalData] as RentalServiceData;
        return MaterialPageRoute(
            builder: (_) => RentalServiceFullDetailsScreen(
                rentalServiceData: rentalServiceData),
            settings:
                RouteSettings(name: getRentalServiceFullDetailsScreenRoute()));
      // case RouteConstant.createNewAccountScreen:
      //   // final args = settings.arguments as Map<String, dynamic>;
      //   return MaterialPageRoute(
      //       builder: (_) => CreateNewAccountScreen(),
      //       settings: RouteSettings(name: getCreateNewAccountScreenRoute()));
      case RouteConstant.createBusinessAccountNewStepOne:
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepOne(),
            settings:
                RouteSettings(name: getCreateBusinessAccountNewStepOneRoute()));
      case RouteConstant.createBusinessAccountNewStepTwo:
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepTwo(),
            settings:
                RouteSettings(name: getCreateBusinessAccountNewStepTwoRoute()));
      case RouteConstant.createBusinessAccountNewStepThree:
        final args = settings.arguments as Map<String, dynamic>;
        final String? city = args[ApiKeys.city] as String?;
        return MaterialPageRoute(
            builder: (_) => CreateBusinessAccountNewStepThree(city: city),
            settings: RouteSettings(
                name: getCreateBusinessAccountNewStepThreeRoute()));
      case RouteConstant.addBusinessLivePhoto:
        return MaterialPageRoute(
            builder: (_) => AddBusinessLivePhoto(),
            settings: RouteSettings(name: getAddBusinessLivePhotoRoute()));
      case RouteConstant.personalAccountNewScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final profileType = args[ApiKeys.argProfileType] as IndividualProfileType;
        final argProfessionTagId = args[ApiKeys.argProfessionTagId] as String;
        final argProfession = args[ApiKeys.argProfession] as String;

        /// old
        // final professionTagId = args[ApiKeys.argProfessionTagId] as String;
        final professionSubCategory = args[ApiKeys.argProfessionSubCategory]
            as List<SubcategoriesFiledName>?;
        final selfEmployment = args[ApiKeys.argSelfEmployment] as String?;
        final selfEmploymentTagId =
            args[ApiKeys.argSelfEmploymentTagId] as String?;

        return MaterialPageRoute(
            builder: (_) => PersonalAccountNewScreen(
                  accountType: accountType,
                  profileType: profileType,
                  profession: argProfession,
                  professionTagId: argProfessionTagId,
                  professionSubCategory: professionSubCategory,
                  selfEmployment: selfEmployment,
                  selfEmploymentTagId: selfEmploymentTagId,
                ),
            settings: RouteSettings(
                name: RouteHelper.getPersonalAccountNewScreenRoute()));

      case RouteConstant.gstNumberScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final businessType = args[ApiKeys.argBusinessType] as BusinessType;
        final argCategorySlugId = args[ApiKeys.argCategoryId] as String;
        final argCategoryName = args[ApiKeys.argCategoryName] as String;
        final argSubCategory = args[ApiKeys.argSubCategory] as SubCategories?;
        // final categoryData = args[ApiKeys.argCategoryData] as CategoryData?;

        return MaterialPageRoute(
            builder: (_) => GstNumberScreen(
                  accountType: accountType,
                  businessType: businessType,
                  // categoryData: categoryData,
                  categorySlugId: argCategorySlugId,
                  categoryName: argCategoryName,
                  subCategory: argSubCategory,
                ),
            settings:
                RouteSettings(name: RouteHelper.getGstNumberScreenRoute()));
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
                selectedYear: selectedYear),
            settings: RouteSettings(name: getAddBioViaAiScreenRoute()));

      case RouteConstant.groceryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final bool? argFromBottomNavBar =
            args[ApiKeys.argFromBottomNavBar] as bool?;
        return MaterialPageRoute(
            builder: (_) =>
                GroceryScreen(fromBottomNavBar: argFromBottomNavBar),
            settings: RouteSettings(name: getGroceryScreenRoute()));

      case RouteConstant.groceryCategoryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final bool argMyGrocery = args[ApiKeys.argMyGrocery] as bool;
        final String argArrGroceryCatName = args[ApiKeys.argArrGroceryCatName] as String;
        final String argArrGroceryCatKey = args[ApiKeys.argArrGroceryCatKey] as String;
        final List<CollapsibleGridModel> argArrGrocerySuperCat =
            args[ApiKeys.argArrGrocerySuperCategory] as List<CollapsibleGridModel>;
        return MaterialPageRoute(
            builder: (_) => GroceryNestedCategoryScreen(
                argArrGrocerySuperCat: argArrGrocerySuperCat,
                argArrGroceryCatKey: argArrGroceryCatKey,
                argArrGroceryCatName: argArrGroceryCatName,
                isMyGrocery: argMyGrocery),
            settings: RouteSettings(name: getGroceryCategoryScreenRoute()));

      case RouteConstant.groceryNestedCategoryWithInventoryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String userId = args[ApiKeys.userId] as String;
        final List<GroceryCategoryWithInventoryModel> argGroceryCategoryWithInventory
        = args[ApiKeys.argGroceryCategoryWithInventory] as List<GroceryCategoryWithInventoryModel>;
        final String argArrGroceryCatName = args[ApiKeys.argArrGroceryCatName] as String;
        final String argArrGroceryCatKey = args[ApiKeys.argArrGroceryCatKey] as String;
        return MaterialPageRoute(
            builder: (_) => GroceryNestedCategoryWithInventoryScreen(
              userId: userId,
              argGroceryCategoryWithInventory: argGroceryCategoryWithInventory,
              argArrGroceryCatKey: argArrGroceryCatKey,
              argArrGroceryCatName: argArrGroceryCatName,
            ),
            settings: RouteSettings(name: getGroceryNestedCategoryWithInventoryScreenRoute())
        );

      case RouteConstant.groceryProductsSelectionScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<GroceryNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<GroceryNestedCategoryModel>;
        // final GroceryNestedCategoryModel argSelectedGroceryData =
        //     args[ApiKeys.argSelectedGroceryData] as GroceryNestedCategoryModel;
        return MaterialPageRoute(
            builder: (_) => GroceryProductsSelectionScreen(
                arrGroceries: argGroceries,
                // selectedGroceryData: argSelectedGroceryData
            ),
            settings: RouteSettings(name: getGroceryProductsSelectionScreenRoute()));
      case RouteConstant.addGroceryScreen:
        return MaterialPageRoute(
            builder: (_) => AddGroceryScreen(),
            settings: RouteSettings(name: getAddGroceryScreenRoute()));
      case RouteConstant.addGroceryVariantScreen:
        return MaterialPageRoute(
            builder: (_) => AddGroceryVariantScreen(),
            settings: RouteSettings(name: getAddGroceryVariantScreenRoute()));
      case RouteConstant.groceryProductsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String userId = args[ApiKeys.userId] as String;
        final List<GroceryNestedCategoryModel> argGroceries =
        args[ApiKeys.argGroceries] as List<GroceryNestedCategoryModel>;
        return MaterialPageRoute(
            builder: (_) => GroceryProductsScreen(
                  userId: userId,
                  arrGroceries: argGroceries
                ),
            settings: RouteSettings(name: getGroceryProductsScreenRoute()));
      case RouteConstant.MyGroceryVariantScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<Variants> variants =
            args[ApiKeys.argVariants] as List<Variants>;
        final bool? argIsShowInGrid = args[ApiKeys.argIsShowInGrid] as bool?;
        return MaterialPageRoute(
            builder: (_) => MyGroceryVariantScreen(
                variants: variants, isShowInGrid: argIsShowInGrid),
            settings: RouteSettings(name: getMyGroceryVariantScreenRoute()));
      case RouteConstant.groceryCustomerListingScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<GroceryNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<GroceryNestedCategoryModel>;
        // final GroceryNestedCategoryModel argSelectedGroceryData =
        //     args[ApiKeys.argSelectedGroceryData] as GroceryNestedCategoryModel;
        return MaterialPageRoute(
            builder: (_) => GroceryCustomerListingScreen(
                arrGroceries: argGroceries,
                // selectedGroceryData: argSelectedGroceryData
            ),
            settings: RouteSettings(name: getGroceryCustomerListingScreenRoute()));
      case RouteConstant.riderServiceScreen:
        // final args = settings.arguments as Map<String, dynamic>;
        // final List<CollapsibleGridModel> argGroceries = args[ApiKeys.argGroceries] as List<CollapsibleGridModel>;
        // final CollapsibleGridModel argSelectedGroceryData = args[ApiKeys.argSelectedGroceryData] as CollapsibleGridModel;
        return MaterialPageRoute(
            builder: (_) => RiderServiceScreen(
                // arrGroceries: argGroceries,
                // selectedGroceryData: argSelectedGroceryData
                ),
            settings: RouteSettings(name: getRiderServiceScreenRoute()));
      case RouteConstant.groceryCartScreen:
        return MaterialPageRoute(
            builder: (_) => GroceryCartScreen(),
            settings: RouteSettings(name: getGroceryCartScreenRoute()));

      //   case RouteConstant.RiderProfileStatusScreen:
      //     return MaterialPageRoute(
      //       builder: (_) => RiderProfileStatusScreen(screeName: '', isAllComplete: false: ''lStepsCompleted: null,),
      //      settings: RouteSettings(name: getGroceryCartScreenRoute())
      // );
      case RouteConstant.grocerySuperCategoryScreen:
      final args = settings.arguments as Map<String, dynamic>;
      final bool argBulkUpload = args[ApiKeys.argBulkUpload] as bool;

        return MaterialPageRoute(
            builder: (_) =>
                GrocerySuperCategoryScreen(
                    isAvailBulkUpload: argBulkUpload
                ),
            settings:
                RouteSettings(name: getGrocerySuperCategoryScreenRoute()));
      case RouteConstant.paymentSettingScreen:
        return MaterialPageRoute(
            builder: (_) => PaymentSettingScreen(),
            settings: RouteSettings(name: getPaymentSettingScreenRoute()));

      case RouteConstant.medicalOtcItemsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        String title = args[ApiKeys.title] as String;
        String categoryId = args[ApiKeys.category_id] as String;
        return MaterialPageRoute(
            builder: (_) => OTCItemsPage(categoryId: categoryId, title: title),
            settings: RouteSettings(name: getMedicalOtcItemsScreen()));
      case RouteConstant.riderStoreScreen:
        return MaterialPageRoute(
            builder: (_) => RiderStoreScreen(),
            settings: RouteSettings(name: getRiderStoreScreenRoute()));
      case RouteConstant.groceryConfirmScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String argOrderId = args[ApiKeys.argOrderId] as String;
        return MaterialPageRoute(
            builder: (_) => GroceryConfirmScreen(orderId: argOrderId),
            settings: RouteSettings(name: getGroceryConfirmScreenRoute()));


      case RouteConstant.addSelfServiceScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final EarnServiceTypes serviceSubType =
            args[ApiKeys.serviceSubType] as EarnServiceTypes;
        final String designation = args[ApiKeys.designation] as String;
        return MaterialPageRoute(
            builder: (_) => AddSelfServiceScreen(
                designation: designation, serviceSubType: serviceSubType),
            settings: RouteSettings(name: getAddSelfServiceRoute()));
      case RouteConstant.createAccountTypeScreen:
        return MaterialPageRoute(
            builder: (_) => CreateAccountTypeScreen(),
            settings: RouteSettings(name: getCreateAccountTypeScreenRoute()));
            // builder: (_) => CreateAccountTypeScreen(
            // ),
            // settings: RouteSettings(name: getCreateAccountTypeScreenRoute())
        // );
      case RouteConstant.earnServiceAvailableOptionsScreen:
        return MaterialPageRoute(
            builder: (_) => EarnServiceAvailableOptionsScreen(),
            settings: RouteSettings(name: getEarnServiceAvailableOptionsScreenRoute())
        );

      case RouteConstant.medicalScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final bool? argFromBottomNavBar =
        args[ApiKeys.argFromBottomNavBar] as bool?;
        return MaterialPageRoute(
            builder: (_) =>
                MedicalScreen(fromBottomNavBar: argFromBottomNavBar),
            settings: RouteSettings(name: getMedicalScreenRoute()));

      case RouteConstant.medicalCategoryScreen:
        return MaterialPageRoute(
            builder: (_) => MedicalCategoryScreen(),
            settings: RouteSettings(name: getMedicalCategoryScreenRoute()));

      case RouteConstant.medicalSubCategoryScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<MedicalNestedCategoryModel> argGroceries =
             args[ApiKeys.argGroceries] as List<MedicalNestedCategoryModel>;
        // final GroceryNestedCategoryModel argSelectedGroceryData =
        //     args[ApiKeys.argSelectedGroceryData] as GroceryNestedCategoryModel;
        return MaterialPageRoute(
            builder: (_) => MedicalSubCategoryScreen(
              arrLevel3Category: argGroceries,
            ),
            settings: RouteSettings(name: getMedicalSubCategoryScreenRoute()));

      case RouteConstant.addMedicalScreen:
        return MaterialPageRoute(
            builder: (_) => AddMedicalScreen(),
            settings: RouteSettings(name: getAddMedicalScreenRoute()));

      case RouteConstant.addMedicalVariantScreen:
        return MaterialPageRoute(
            builder: (_) => AddMedicalVariantScreen(),
            settings: RouteSettings(name: getAddMedicalVariantScreenRoute()));

      case RouteConstant.myMedicalProductsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String argCategoryId = args[ApiKeys.argCategoryId] as String;
        final String argCategoryName = args[ApiKeys.argCategoryName] as String;
        return MaterialPageRoute(
            builder: (_) => MyMedicalProductsScreen(
              categoryId: argCategoryId,
              categoryName: argCategoryName,
            ),
            settings: RouteSettings(name: getMyMedicalProductsScreenRoute()));

      case RouteConstant.myMedicalVariantScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<MedicalProductVariants> variants =
        args[ApiKeys.argVariants] as List<MedicalProductVariants>;
        final bool? argIsShowInGrid = args[ApiKeys.argIsShowInGrid] as bool?;
        return MaterialPageRoute(
            builder: (_) => MyMedicalVariantScreen(
                variants: variants,
                isShowInGrid: argIsShowInGrid
            ),
            settings: RouteSettings(name: getMyMedicalVariantScreenRoute()));

      case RouteConstant.medicalListingScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<MedicalNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<MedicalNestedCategoryModel>;
        return MaterialPageRoute(
            builder: (_) => MedicalListingScreen(
              arrLevel3Category: argGroceries,
            ),
            settings: RouteSettings(name: getMedicalListingScreenRoute()));

      case RouteConstant.medicalCartScreen:
        return MaterialPageRoute(
            builder: (_) => MedicalCartScreen(),
            settings: RouteSettings(name: getMedicalCartScreenRoute()));

      case RouteConstant.medicalConfirmScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String argOrderId = args[ApiKeys.argOrderId] as String;
        return MaterialPageRoute(
            builder: (_) => MedicalConfirmScreen(orderId: argOrderId),
            settings: RouteSettings(name: getMedicalConfirmScreenRoute())
        );

       case RouteConstant.groceryOrFoodStoresScreen:
              final args = settings.arguments as Map<String, dynamic>;
              final OnboardingCategoryModel selectedGroceryCategoryData = args[ApiKeys.argCategoryData] as OnboardingCategoryModel;
              final bool argIsGroceryStore = args[ApiKeys.argIsGroceryStore] as bool;
              return MaterialPageRoute(
                  builder: (_) => GroceryOrFoodStoresScreen(
                      selectedGroceryOrFoodCategory: selectedGroceryCategoryData,
                      isGroceryStore: argIsGroceryStore,
                  ),
                  settings: RouteSettings(name: getGroceryOrFoodStoresScreenRoute())
              );

      case RouteConstant.addGrocerySnapSearchScreen:
                return MaterialPageRoute(
                  builder: (_) => AddGrocerySnapSearchScreen(),
                  settings: RouteSettings(name: getAddGrocerySnapSearchScreenRoute())
              );

      case RouteConstant.missingGroceryItemsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final GroceryController controller = args[ApiKeys.controller] as GroceryController;
        final List<MissingProducts> argMissingProducts = args[ApiKeys.argMissingProducts] as List<MissingProducts>;
                return MaterialPageRoute(
                  builder: (_) => MissingGroceryItemsScreen(
                      controller: controller,
                      missingProducts: argMissingProducts),
                  settings: RouteSettings(name: getMissingGroceryItemsScreenRoute())
              );

      case RouteConstant.missingFoodItemsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final FoodServiceController controller = args[ApiKeys.controller] as FoodServiceController;
        final List<MissingFoodProducts> argMissingProducts = args[ApiKeys.argMissingProducts] as List<MissingFoodProducts>;
        return MaterialPageRoute(
            builder: (_) => MissingFoodItemsScreen(
                controller: controller,
                missingProducts: argMissingProducts),
            settings: RouteSettings(name: getMissingFoodItemsScreenRoute())
        );

      case RouteConstant.otherGroceryStoreScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String businessId = args[ApiKeys.businessId] as String;
        final String userId = args[ApiKeys.userId] as String;
        return MaterialPageRoute(
            builder: (_) => OtherGroceryStoreScreen(
                visitBusinessId: businessId,
                userId: userId,
            ),
            settings: RouteSettings(name: getOtherGroceryStoreScreenRoute())
        );

      case RouteConstant.otherFoodStoreDetailsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String businessId = args[ApiKeys.businessId] as String;
        return MaterialPageRoute(
            builder: (_) => OtherFoodStoreDetailsScreen(
              visitBusinessId: businessId,
            ),
            settings: RouteSettings(name: getOtherFoodStoreDetailsScreenRoute())
        );

      case RouteConstant.addFoodSnapSearchScreen:
        return MaterialPageRoute(
            builder: (_) => AddFoodSnapSearchScreen(),
            settings: RouteSettings(name: getAddFoodSnapSearchScreenRoute())
        );


      case RouteConstant.addSingleProductScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String productId = args[ApiKeys.productId] as String;
        final int? createMissingProductIndex = args[ApiKeys.argCreateMissingProductIndex] as int?;

        return MaterialPageRoute(
            builder: (_) => AddSingleProductScreen(
              foodProductId: productId,
              createMissingProductIndex: createMissingProductIndex
            ),
            settings: RouteSettings(name: getAddSingleProductScreenRoute())
        );

      case RouteConstant.productSelectionScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final FoodCategoryData foodCategoryData = args[ApiKeys.argCategoryData] as FoodCategoryData;
        return MaterialPageRoute(
            builder: (_) => FoodProductSelectionScreen(
                foodCategoryData: foodCategoryData
            ),
            settings: RouteSettings(name: getProductSelectionScreenRoute())
        );

      case RouteConstant.foodEntryAiScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final int? createMissingProductIndex = args[ApiKeys.argCreateMissingProductIndex] as int?;
        return MaterialPageRoute(
            builder: (_) => FoodEntryAiScreen(
                createMissingProductIndex: createMissingProductIndex
            ),
            settings: RouteSettings(name: getFoodEntryAiScreenRoute())
        );

        case RouteConstant.foodAiDetailScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final FoodGenAiResModel foodGenAiResModel = args[ApiKeys.argFoodGenAiResModel] as FoodGenAiResModel;
        final int? createMissingProductIndex = args[ApiKeys.argCreateMissingProductIndex] as int?;
        return MaterialPageRoute(
            builder: (_) => FoodAiDetailScreen(
                foodData: foodGenAiResModel,
                createMissingProductIndex: createMissingProductIndex
            ),
            settings: RouteSettings(name: getFoodAiDetailScreenRoute())
        );
      case RouteConstant.foodCustomerListingScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final FoodCategoryData foodCategoryData = args[ApiKeys.argCategoryData] as FoodCategoryData;
        return MaterialPageRoute(
            builder: (_) => FoodCustomerListingScreen(
                foodCategoryData: foodCategoryData
            ),
            settings: RouteSettings(name: getFoodCustomerListingScreenRoute())
        );

      case RouteConstant.foodReviewSelectionScreen:
        return MaterialPageRoute(
            builder: (_) => FoodReviewSelectionScreen(),
            settings: RouteSettings(name: getFoodReviewSelectionScreenRoute())
        );


      case RouteConstant.CallListScreen:
        return MaterialPageRoute(
          builder: (_) => const CallListScreen(),
          settings: const RouteSettings(name: '/CallListScreen'),
        );
      case RouteConstant.OutgoingCallScreen:
        return MaterialPageRoute(
          builder: (_) => const CallRoomScreen(),
          settings: const RouteSettings(name: '/OutgoingCallScreen'),
        );
      case RouteConstant.IncomingCallScreen:
        return MaterialPageRoute(
          builder: (_) => const IncomingCallScreen(),
          settings: const RouteSettings(name: '/IncomingCallScreen'),
        );
      case RouteConstant.ActiveCallScreen:
        return MaterialPageRoute(
          builder: (_) => const CallRoomScreen(),
          settings: const RouteSettings(name: '/ActiveCallScreen'),
        );
      case RouteConstant.CallRoomScreen:
        return MaterialPageRoute(
          builder: (_) => const CallRoomScreen(),
          settings: const RouteSettings(name: '/CallRoomScreen'),
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
