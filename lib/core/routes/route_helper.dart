import 'package:flutter/material.dart';
import 'package:BlueEra/core/routes/route_constant.dart';

/// Route NAME helpers. The route TABLE now lives in app_pages.dart
/// (GetPage list); this class only maps screens to their route strings.
class RouteHelper {
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  static String getMobileNumberLoginRoute() => RouteConstant.MobileNumberScreen;

  // static String getOnboardingStartedScreenRoute() =>
  // RouteConstant.OnboardingStartedScreen;

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

  static String getAddProductTextOrSnapScreenRoute() =>
      RouteConstant.addProductTextOrSnapSearchScreen;

  // static String getListingFormScreenRoute() =>
  //      RouteConstant.listingFormScreen;

  static String getProductScreenRoute() => RouteConstant.productScreen;

  static String getAddServicesScreenRoute() => RouteConstant.addServicesScreen;

  static String getAddProductViaAiStep1Route() =>
      RouteConstant.addProductViaAiStep1;

  static String getAddProductViaAiStep2Route() =>
      RouteConstant.addProductViaAiStep2;

  static String getProductPreviewScreenRoute() =>
      RouteConstant.productPreviewScreen;

  static String getCreateVariantScreenRoute() =>
      RouteConstant.createVariantScreen;

  static String getProductsStoreDetailsScreenRoute() =>
      RouteConstant.productsStoreDetailsScreen;

  static String getProductSuperCategoryScreenRoute() =>
      RouteConstant.productSuperCategoryScreen;

  static String getProductNestedCategoryScreenRoute() =>
      RouteConstant.productNestedCategoryScreen;

  static String getStoreProductSelectionScreenRoute() =>
      RouteConstant.storeProductSelectionScreen;

  static String getProductCartScreenRoute() => RouteConstant.productCartScreen;

  static String getAddProductVariantScreenRoute() =>
      RouteConstant.addProductVariantScreen;

  // ───────── AUTOMOTIVE module (parallel copy of product routes) ─────────
  static String getAutomotivePartsScreenRoute() =>
      RouteConstant.automotivePartsScreen;
  static String getAutomotiveAddProductTextOrSnapScreenRoute() =>
      RouteConstant.automotiveAddProductTextOrSnapScreen;
  static String getAutomotiveAddProductViaAiStep1Route() =>
      RouteConstant.automotiveAddProductViaAiStep1;
  static String getAutomotiveAddProductViaAiStep2Route() =>
      RouteConstant.automotiveAddProductViaAiStep2;
  static String getAutomotiveProductPreviewScreenRoute() =>
      RouteConstant.automotiveProductPreviewScreen;
  static String getAutomotiveCreateVariantScreenRoute() =>
      RouteConstant.automotiveCreateVariantScreen;
  static String getAutomotiveProductsStoreDetailsScreenRoute() =>
      RouteConstant.automotiveProductsStoreDetailsScreen;
  static String getAutomotiveProductSuperCategoryScreenRoute() =>
      RouteConstant.automotiveProductSuperCategoryScreen;
  static String getAutomotiveProductNestedCategoryScreenRoute() =>
      RouteConstant.automotiveProductNestedCategoryScreen;
  static String getAutomotiveStoreProductSelectionScreenRoute() =>
      RouteConstant.automotiveStoreProductSelectionScreen;
  static String getAutomotiveAddProductVariantScreenRoute() =>
      RouteConstant.automotiveAddProductVariantScreen;
  static String getAutomotiveProductNestedCategoryWithInventoryScreenRoute() =>
      RouteConstant.automotiveProductNestedCategoryWithInventoryScreen;
  static String getAutomotiveMyProductProductsScreenRoute() =>
      RouteConstant.automotiveMyProductProductsScreen;

  static String getSelfEmployeeScreenRoute() =>
      RouteConstant.selfEmployeeScreen;

  static String getInventoryBusinessCardsScreenRoute() =>
      RouteConstant.inventoryBusinessCardsScreen;

  // Manufacturer-fork route getters.
  static String getManufacturerScreenRoute() =>
      RouteConstant.manufacturerScreen;

  static String getManufacturerStoreDetailsScreenRoute() =>
      RouteConstant.manufacturerStoreDetailsScreen;

  // static String getManufacturerInventoryBusinessCardsScreenRoute() =>
  //     RouteConstant.manufacturerInventoryBusinessCardsScreen;

  static String getMyManufacturerProductsScreenRoute() =>
      RouteConstant.myManufacturerProductsScreen;

  static String getManufacturerAddProductViaAiStep1Route() =>
      RouteConstant.manufacturerAddProductViaAiStep1;

  static String getManufacturerAddProductViaAiStep2Route() =>
      RouteConstant.manufacturerAddProductViaAiStep2;

  static String getManufacturerProductPreviewScreenRoute() =>
      RouteConstant.manufacturerProductPreviewScreen;

  static String getManufacturerCreateVariantScreenRoute() =>
      RouteConstant.manufacturerCreateVariantScreen;

  static String getManufacturerNestedCategoryWithInventoryScreenRoute() =>
      RouteConstant.manufacturerNestedCategoryWithInventoryScreen;

  static String getFoodUploadScreenRoute() => RouteConstant.foodUploadScreen;

  static String getAddFlatRoomRentalServiceScreenRoute() =>
      RouteConstant.addFlatRoomRentalServiceScreen;

  // static String getPersonalInformationRidingScreenRoute() =>
  //     RouteConstant.personalInformationRidingScreen;

  // static String getAddressLocationRidingScreenRoute() =>
  //     RouteConstant.addressLocationRidingScreen;

  // static String getPersonalIdentificationRidingScreenRoute() =>
  //     RouteConstant.personalIdentificationRidingScreen;

  // static String getDrivingVerificationRidingScreenRoute() =>
  //     RouteConstant.drivingVerificationRidingScreen;
  //
  // static String getVehicleImagesRidingScreenRoute() =>
  //     RouteConstant.vehicleImagesRidingScreen;

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

  // â”€â”€ be_vehicle_service routes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String getVehicleHomeScreenRoute() => RouteConstant.vehicleHomeScreen;

  static String getVehicleListingScreenRoute() =>
      RouteConstant.vehicleListingScreen;

  static String getVehicleDetailScreenRoute() =>
      RouteConstant.vehicleDetailScreen;

  // static String getCreateNewAccountScreenRoute() =>
  //     RouteConstant.createNewAccountScreen;

  static String getCreateBusinessAccountNewStepOneRoute() =>
      RouteConstant.createBusinessAccountNewStepOne;

  static String getCreateBusinessAccountNewStepTwoRoute() =>
      RouteConstant.createBusinessAccountNewStepTwo;

  static String getCreateBusinessAccountNewStepThreeRoute() =>
      RouteConstant.createBusinessAccountNewStepThree;

  static String getCreateBusinessAccountNewStepFourRoute() =>
      RouteConstant.createBusinessAccountNewStepFour;

  static String getPersonalAccountNewScreenRoute() =>
      RouteConstant.personalAccountNewScreen;

  static String getGstNumberScreenRoute() => RouteConstant.gstNumberScreen;

  static String getAddBioViaAiScreenRoute() => RouteConstant.addBioViaAiScreen;

  static String getGroceryScreenRoute() => RouteConstant.groceryScreen;

  static String getGroceryNestedCategoryScreenRoute() =>
      RouteConstant.groceryNestedCategoryScreen;

  static String getGroceryProductsSelectionScreenRoute() =>
      RouteConstant.groceryProductsSelectionScreen;

  // static String getAddGroceryScreenRoute() =>
  //     RouteConstant.addGroceryScreen;

  static String getAddGroceryVariantScreenRoute() =>
      RouteConstant.addGroceryVariantScreen;

  static String getMyGroceryProductsScreenRoute() =>
      RouteConstant.myGroceryProductsScreen;

  static String getVisitGroceryProductsScreenRoute() =>
      RouteConstant.visitGroceryProductsScreen;

  static String getAllGroceryCategorizeProductsScreenRoute() =>
      RouteConstant.allGroceryCategorizeProductsScreen;

  // static String getGroceryCustomerListingScreenRoute() =>
  //     RouteConstant.groceryCustomerListingScreen;

  static String getRiderServiceScreenRoute() =>
      RouteConstant.riderServiceScreen;

  static String getRiderMeScreenRoute() => RouteConstant.riderMeScreen;

  static String getGroceryCartScreenRoute() => RouteConstant.groceryCartScreen;

  // static String getYourAddToCardScreenRoute() =>
  //     RouteConstant.yourAddToCardScreen;

  // static String getRiderProfileStatusScreenRoute() =>
  //     RouteConstant.RiderProfileStatusScreen;

  static String getGrocerySuperCategoryScreenRoute() =>
      RouteConstant.grocerySuperCategoryScreen;

  static String getPaymentSettingScreenRoute() =>
      RouteConstant.paymentSettingScreen;

  // static String getMedicalOtcItemsScreen() =>
  //     RouteConstant.medicalOtcItemsScreen;

  static String getHospitalOptCategory() => RouteConstant.hospitalOptCategory;

  static String getHospitalDoctorViewCategory() =>
      RouteConstant.hospitalDoctorViewCategory;

  static String getHospitalWardViewCategory() =>
      RouteConstant.hospitalWardViewCategory;

  static String getRiderStoreScreenRoute() => RouteConstant.riderStoreScreen;

  static String getGroceryConfirmScreenRoute() =>
      RouteConstant.groceryConfirmScreen;

  static String getAddSelfServiceRoute() => RouteConstant.addSelfServiceScreen;

  static String getCreateAccountTypeScreenRoute() =>
      RouteConstant.createAccountTypeScreen;

  static String getCreateAccountTypeV2ScreenRoute() =>
      RouteConstant.createAccountTypeV2Screen;

  static String getGigWorkerOptionsScreenRoute() =>
      RouteConstant.gigWorkerOptionsScreen;

  static String getMedicalScreenRoute() => RouteConstant.medicalScreen;

  static String getMedicalCategoryScreenRoute() =>
      RouteConstant.medicalCategoryScreen;

  static String getMedicalSubCategoryScreenRoute() =>
      RouteConstant.medicalSubCategoryScreen;

  // Retired with the grocery-style flow: the selection screen's floating cart
  // now goes straight to the variant screen, so the AddMedicalScreen review
  // grid has no entry point. Mirrors getAddGroceryScreenRoute above.
  // static String getAddMedicalScreenRoute() =>
  //     RouteConstant.addMedicalScreen;

  static String getAddMedicalVariantScreenRoute() =>
      RouteConstant.addMedicalVariantScreen;

  static String getMyMedicalProductsScreenRoute() =>
      RouteConstant.myMedicalProductsScreen;

  static String getMyMedicalVariantScreenRoute() =>
      RouteConstant.myMedicalVariantScreen;

  static String getMedicalListingScreenRoute() =>
      RouteConstant.medicalListingScreen;

  static String getMedicalCartScreenRoute() => RouteConstant.medicalCartScreen;

  static String getMedicalConfirmScreenRoute() =>
      RouteConstant.medicalConfirmScreen;

  static String getMedicalHomeScreenRoute() => RouteConstant.medicalHomeScreen;

  static String getHospitalDepartmentsScreenRoute() =>
      RouteConstant.hospitalDepartmentsScreen;

  static String getGroceryStoresScreenRoute() =>
      RouteConstant.groceryStoresScreen;

  static String getAddGrocerySnapSearchScreenRoute() =>
      RouteConstant.addGrocerySnapSearchScreen;

  static String getGroceryRiderSnapSearchScreenRoute() =>
      RouteConstant.groceryRiderSnapSearchScreen;

  static String getAddMedicalSnapSearchScreenRoute() =>
      RouteConstant.addMedicalSnapSearchScreen;

  static String getMissingGroceryItemsScreenRoute() =>
      RouteConstant.missingGroceryItemsScreen;

  static String getMissingFoodItemsScreenRoute() =>
      RouteConstant.missingFoodItemsScreen;

  static String getVisitGroceryStoreScreenRoute() =>
      RouteConstant.visitGroceryStoreScreen;

  static String getOtherFoodStoreDetailsScreenRoute() =>
      RouteConstant.visitFoodStoreDetailsScreen;

  static String getAddFoodSnapSearchScreenRoute() =>
      RouteConstant.addFoodSnapSearchScreen;

  static String getGroceryNestedCategoryWithInventoryScreenRoute() =>
      RouteConstant.groceryNestedCategoryWithInventoryScreen;

  static String getAddSingleProductScreenRoute() =>
      RouteConstant.addSingleProductScreen;

  static String getFoodProductSelectionScreenRoute() =>
      RouteConstant.foodProductSelectionScreen;

  static String getProductNestedCategoryWithInventoryScreenRoute() =>
      RouteConstant.productNestedCategoryWithInventoryScreen;

  static String getMyProductProductsScreenRoute() =>
      RouteConstant.myProductProductsScreen;

  static String getFoodEntryAiScreenRoute() => RouteConstant.foodEntryAiScreen;

  static String getFoodAiDetailScreenRoute() =>
      RouteConstant.foodAiDetailScreen;

  static String getFoodCustomerListingScreenRoute() =>
      RouteConstant.foodCustomerListingScreen;

  static String getNearByRidersScreenRoute() =>
      RouteConstant.nearByRidersScreen;

  static String getYourCartScreenRoute() => RouteConstant.yourCartScreen;

  static String getGlobalSearchScreenRoute() =>
      RouteConstant.globalSearchScreen;

  // Business onboarding (WhatsApp-style) routes
  static String getBusinessOnboardingCategoryScreenRoute() =>
      RouteConstant.BusinessOnboardingCategoryScreen;

  static String getBusinessOnboardingHoursTypeScreenRoute() =>
      RouteConstant.BusinessOnboardingHoursTypeScreen;

  static String getBusinessOnboardingSelectHoursScreenRoute() =>
      RouteConstant.BusinessOnboardingSelectHoursScreen;

  static String getBusinessOnboardingPhotoScreenRoute() =>
      RouteConstant.BusinessOnboardingPhotoScreen;

  static String getBusinessOnboardingAddressScreenRoute() =>
      RouteConstant.BusinessOnboardingAddressScreen;

  static String getBusinessOnboardingDescriptionScreenRoute() =>
      RouteConstant.BusinessOnboardingDescriptionScreen;

  static String getChooseEarnServiceScreenRoute() =>
      RouteConstant.chooseEarnServiceScreen;

  static String getEarnServiceDashboardViewRoute() =>
      RouteConstant.earnServiceDashboardView;

  static String getSavedAddressListScreenRoute() =>
      RouteConstant.savedAddressListScreen;

  static String getAddEditAddressScreenRoute() =>
      RouteConstant.addEditAddressScreen;

  static String getOrderStepsScreenRoute() => RouteConstant.orderStepsScreen;

  static String getMySelfPickupOrdersScreenRoute() =>
      RouteConstant.mySelfPickupOrdersScreen;
}
