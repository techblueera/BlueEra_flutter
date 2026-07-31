class RouteConstant {
  static const String inital = "/";
  static const String PermissionScreen = "/PermissionScreen";
  static const String SplashScreen = "/SplashScreen";
  static const String AudioCallScreen = "/AudioCallScreen";
  static const String MobileNumberScreen = "/MobileNumberScreen";
  static const String OnboardingStartedScreen = "/OnboardingStartedScreen";
  static const String OtpPageScreen = "/OtpPageScreen";
  // static const String SelectAccountScreen = "/SelectAccountScreen";
  // static const String CreateUserAccount = "/CreateUserAccount";
  static const String BottomNavigationBarScreen = "/BottomNavigationBarScreen";
  static const String HomeScreen = "/HomeScreen";
  // static const String BusinessAccount = "/BusinessAccount";
  // static const String AddEditVisitingCardScreen = "/AddEditVisitingCardScreen";
  static const String BusinessOwnProfileScreen = "/BusinessOwnProfileScreen";
  static const String PersonalProfileCreateScreen =
      "/PersonalProfileCreateScreen";
  static const String FeedScreen = "/FeedScreen";
  static const String SelectCompanyVerificationScreen =
      "/SelectCompanyVerificationScreen";
  static const String BusinessVerificationScreen =
      "/BusinessVerificationScreen";
  static const String OwnershipVerificationScreen =
      "/OwnershipVerificationScreen";
  static const String NotificationScreen = "/NotificationScreen";
  static const String ChannelScreen = "/ChannelScreen";
  static const String ManageChannelScreen = "/ManageChannelScreen";
  static const String ChannelSettingScreen = "/ChannelSettingScreen";
  static const String CreateReelScreen = "/CreateReelScreen";
  static const String CustomizeMapScreen = "/CustomizeMapScreen";
  static const String SearchLocationScreen = "/SearchLocationScreen";
  static const String allSongsScreen = "/GetAllSongsScreen";
  static const String addSongScreen = "/AddSongScreen";
  static const String addPlaceStepOne = "/AddPlaceStepOne";
  static const String addPlaceStepTwo = "/AddPlaceStepTwo";
  static const String categorySelectionScreen = "/CategorySelectionScreen";
  static const String JobDetailScreen = "/JobDetailScreen";
  static const String JobResumeScreen = "/JobResumeScreen";
  static const String JobQnaScreen = "/JobQueryScreen";
  static const String JobDetailsOverviewScreen = "/JobDetailsOverviewScreen";
  static const String AppliedJobsScreen = "/AppliedJobsScreen";
  static const String InterviewInvitesScreen = "/InterviewInvitesScreen";
  static const String FollowerFollowingScreen = "/FollowerFollowingScreen";
  static const String ChatContactsScreen = "/ChatContactsScreen";

  /// "Contacts on BlueEra" — contact-service matches (separate from the
  /// chat-service-backed [ChatContactsScreen]).
  static const String BlueEraContactsScreen = "/BlueEraContactsScreen";
  static const String CreateJobPostScreen = "/CreateJobPostScreen";
  static const String CreateJobPostStep2 = "/CreateJobPostStep2";
  static const String CreateJobPostStep3 = "/CreateJobPostStep3";
  static const String CreateJobPostStep4 = "/CreateJobPostStep4";
  static const String CreateJobPostStep5 = "/CreateJobPostStep5";
  static const String tagPeopleScreen = "/tagPeopleScreen";
  static const String CreateMessagePostScreen = "/CreateMessagePostScreen";
  static const String videoRecorderScreen = "/VideoRecorderScreen";
  static const String fullVideoPreview = "/FullVideoPreview";
  static const String videoTrimScreen = "/VideoTrimScreen";
  static const String PollInputScreen = "/PollInputScreen";
  static const String PollReviewScreen = "/PollReviewScreen";
  static const String PhotoPostScreen = "/PhotoPostScreen";
  static const String PhotoPostPreviewScreen = "/PhotoPostPreviewScreen";
  static const String PhotoPostReviewScreen = "/PhotoPostReviewScreen";
  static const String videoPlayerScreen = "/VideoPlayerScreen";
  static const String shortsPlayerScreen = "/ShortsPlayerScreen";
  static const String journeyPlanningScreen = "/JourneyPlanningScreen";
  static const String UpdateJourneyScreen = "/UpdateJourneyScreen";
  static const String CreateResumeScreen = "/CreateResumeScreen";
  static const String ResumeTemplateScreen = "/ResumeTemplateScreen";
  static const String ProductListingScreen = "/product-listing";
  static const String MyBookingScreen = "/MyBookingScreen";

  /// Customer's own standalone-doctor appointment requests, with Cancel.
  /// Named (rather than `Get.to`-only) so a `healthcare_booking` push can
  /// deep-link into it later.
  static const String DoctorMyAppointmentsScreen =
      "/DoctorMyAppointmentsScreen";
  static const String ReceivedBookingScreen = "/ReceivedBookingsScreen";
  static const String VideographyTutorialScreen = "/VideographyTutorialScreen";
  static const String ReceivedEnquiriesScreen = "/ReceivedEnquiriesScreen";
  static const String VideographyTutorialScreen2 =
      "/VideographyTutorialScreen2";
  static const String MyEnquiresScreen = "/MyEnquiriesPage";
  static const String addUpdateProductScreen = "/AddUpdateProductScreen";
  static const String BookingAndEnquiresScreen = "/BookingsScreen";
  static const String setAvailabilityScreen = "/SetAvailabilityScreen";
  static const String AppointmentBookingScreen = "/AppointmentBookingScreen";
  static const String EnquiryForm = "/EnquiryFormScreen";
  static const String addBankAccountScreen = "/AddBankAccountScreen";
  static const String addAccountUpiScreen = "/AddAccountUpiScreen";
  static const String walletScreen = "/WalleScreen";
  static const String allTransactionsScreen = "/allTransactionsScreen";
  static const String addDocumentScreen = "/AddDocumentScreen";
  static const String postDetailPage = "/PostDeatilPage";
  static const String moreCardsScreen = "/MoreCardsScreen";
  // static const String listingFormScreen = "/ListingFormScreen";
  static const String productScreen = "/ProductScreen";
  static const String addProductTextOrSnapSearchScreen = "/AddProductTextOrSnapSearchScreen";
  static const String addServicesScreen = "/AddServicesScreen";
  static const String addProductViaAiStep1 = "/AddProductViaAiStep1";
  static const String addProductViaAiStep2 = "/AddProductViaAiStep2";
  static const String productPreviewScreen = "/ProductPreviewScreen";
  static const String createVariantScreen = "/CreateVariantScreen";
  static const String productsStoreDetailsScreen = "/ProductsStoreDetailsScreen";
  static const String productSuperCategoryScreen = "/ProductSuperCategoryScreen";
  static const String productNestedCategoryScreen = "/ProductNestedCategoryScreen";
  static const String storeProductSelectionScreen = "/StoreProductSelectionScreen";
  static const String productCartScreen = "/ProductCartScreen";
  static const String addProductVariantScreen = "/AddProductVariantScreen";
  // static const String storeFeedScreen = "/StoreFeedScreen";
  static const String selfEmployeeScreen = "/SelfEmployeeScreen";
  static const String inventoryBusinessCardsScreen = "/InventoryBusinessCardsScreen";
  // Manufacturer fork — parallel to the product routes above. Same UI
  // shape today; expected to diverge in future.
  static const String manufacturerScreen = "/ManufacturerScreen";
  static const String manufacturerStoreDetailsScreen = "/ManufacturerStoreDetailsScreen";
  // static const String manufacturerInventoryBusinessCardsScreen = "/ManufacturerInventoryBusinessCardsScreen";
  static const String myManufacturerProductsScreen = "/MyManufacturerProductsScreen";
  // Manufacturer "Create Own" (AI) add-product flow — parallel to the product
  // AI routes above, driven by ManufacturerProductController.
  static const String manufacturerAddProductViaAiStep1 = "/ManufacturerAddProductViaAiStep1";
  static const String manufacturerAddProductViaAiStep2 = "/ManufacturerAddProductViaAiStep2";
  static const String manufacturerProductPreviewScreen = "/ManufacturerProductPreviewScreen";
  static const String manufacturerCreateVariantScreen = "/ManufacturerCreateVariantScreen";
  static const String manufacturerNestedCategoryWithInventoryScreen = "/ManufacturerNestedCategoryWithInventoryScreen";
  static const String foodUploadScreen = "/FoodUploadScreen";
  static const String addFlatRoomRentalServiceScreen = "/AddFlatRoomRentalServiceScreen";
  // static const String personalInformationRidingScreen = "/PersonalInformationRidingScreen";
  // static const String addressLocationRidingScreen = "/AddressLocationRidingScreen";
  // static const String personalIdentificationRidingScreen = "/PersonalIdentificationRidingScreen";
  // static const String drivingVerificationRidingScreen = "/DrivingVerificationRidingScreen";
  // static const String vehicleImagesRidingScreen = "/VehicleImagesRidingScreen";
  static const String vehicleInformationRidingScreen = "/VehicleInformationRidingScreen";
  static const String homeStayRentalService = "/HomeStayRentalService";
  static const String vehicleRentalService = "/VehicleRentalService";
  static const String rentalServiceScreen = "/RentalServiceScreen";
  static const String rentalServiceFullDetailsScreen = "/RentalServiceFullDetailsScreen";


  // static const String createNewAccountScreen = "/CreateNewAccountScreen";
  static const String createBusinessAccountNewStepOne = "/CreateBusinessAccountNewStepOne";
  static const String createBusinessAccountNewStepTwo = "/CreateBusinessAccountNewStepTwo";
  static const String createBusinessAccountNewStepThree = "/CreateBusinessAccountNewStepThree";
  static const String personalAccountNewScreen = "/PersonalAccountNewScreen";
  static const String gstNumberScreen = "/GstNumberScreen";
  static const String addBioViaAiScreen = "/AddBioViaAiScreen";


  static const String groceryScreen = "/GroceryScreen";
  static const String groceryNestedCategoryScreen = "/GroceryNestedCategoryScreen";
  static const String groceryProductsSelectionScreen = "/GroceryProductsSelectionScreen";
  // static const String addGroceryScreen = "/AddGroceryScreen";
  static const String addGroceryVariantScreen = "/AddGroceryVariantScreen";
  static const String myGroceryProductsScreen = "/MyGroceryProductsScreen";
  static const String visitGroceryProductsScreen = "/VisitGroceryProductsScreen";
  static const String allGroceryCategorizeProductsScreen = "/AllGroceryCategorizeProductsScreen";

  // static const String groceryCustomerListingScreen = "/GroceryCustomerListingScreen";
  static const String riderServiceScreen = "/RiderServiceScreen";
  static const String riderMeScreen = "/RiderMeScreen";
  static const String groceryCartScreen = "/GroceryCartScreen";
  // static const String yourAddToCardScreen = "/YourAddToCardScreen";
  // static const String RiderProfileStatusScreen = "/RiderProfileStatusScreen";
  static const String grocerySuperCategoryScreen = "/GrocerySuperCategoryScreen";
  static const String paymentSettingScreen = "/PaymentSettingScreen";
  // static const String medicalOtcItemsScreen = "/MedicalOtcItemsScreen";
  static const String riderStoreScreen = "/RiderStoreScreen";
  static const String groceryConfirmScreen = "/GroceryConfirmScreen";
  static const String hospitalOptCategory = "/GetHospitalOptCategory";
  static const String hospitalDoctorViewCategory = "/GetHospitalDoctorViewCategory";
  static const String hospitalWardViewCategory = "/GetHospitalWardViewCategory";
  static const String addSelfServiceScreen = "/AddSelfServiceScreen";
  static const String createAccountTypeScreen = "/CreateAccountTypeScreen";
  static const String createAccountTypeV2Screen = "/CreateAccountTypeV2Screen";
  static const String gigWorkerOptionsScreen = "/GigWorkerOptionsScreen";
  static const String groceryStoresScreen = "/GroceryStoresScreen";
  static const String addGrocerySnapSearchScreen = "/AddGrocerySnapSearchScreen";
  static const String groceryRiderSnapSearchScreen = "/GroceryRiderSnapSearchScreen";
  static const String addMedicalSnapSearchScreen = "/AddMedicalSnapSearchScreen";
  static const String missingGroceryItemsScreen = "/MissingGroceryItemsScreen";
  static const String visitGroceryStoreScreen = "/VisitGroceryStoreScreen";
  static const String visitFoodStoreDetailsScreen = "/VisitFoodStoreDetailsScreen";
  static const String groceryNestedCategoryWithInventoryScreen = "/GroceryNestedCategoryWithInventoryScreen";
  static const String addFoodSnapSearchScreen = "/AddFoodSnapSearchScreen";
  static const String missingFoodItemsScreen = "/missingFoodItemsScreen";
  static const String addSingleProductScreen = "/AddSingleProductScreen";
  static const String foodProductSelectionScreen = "/FoodProductSelectionScreen";
  static const String foodEntryAiScreen = "/FoodEntryAiScreen";
  static const String foodAiDetailScreen = "/FoodAiDetailScreen";
  static const String foodCustomerListingScreen = "/FoodCustomerListingScreen";
  static const String nearByRidersScreen = "/NearByRidersScreen";

  /// Medical
  static const String medicalScreen = "/MedicalScreen";
  static const String medicalCategoryScreen = "/MedicalCategoryScreen";
  static const String medicalSubCategoryScreen = "/MedicalSubCategoryScreen";
  static const String addMedicalScreen = "/AddMedicalScreen";
  static const String addMedicalVariantScreen = "/AddMedicalVariantScreen";
  static const String myMedicalProductsScreen = "/MyMedicalProductsScreen";
  static const String productNestedCategoryWithInventoryScreen = "/ProductNestedCategoryWithInventoryScreen";
  static const String myProductProductsScreen = "/MyProductProductsScreen";
  // ───────── AUTOMOTIVE module (parallel copy of product routes) ─────────
  static const String automotivePartsScreen = "/AutomotivePartsScreen";
  static const String automotiveAddProductTextOrSnapScreen = "/AutomotiveAddProductTextOrSnapScreen";
  static const String automotiveAddProductViaAiStep1 = "/AutomotiveAddProductViaAiStep1";
  static const String automotiveAddProductViaAiStep2 = "/AutomotiveAddProductViaAiStep2";
  static const String automotiveProductPreviewScreen = "/AutomotiveProductPreviewScreen";
  static const String automotiveCreateVariantScreen = "/AutomotiveCreateVariantScreen";
  static const String automotiveProductsStoreDetailsScreen = "/AutomotiveProductsStoreDetailsScreen";
  static const String automotiveProductSuperCategoryScreen = "/AutomotiveProductSuperCategoryScreen";
  static const String automotiveProductNestedCategoryScreen = "/AutomotiveProductNestedCategoryScreen";
  static const String automotiveStoreProductSelectionScreen = "/AutomotiveStoreProductSelectionScreen";
  static const String automotiveAddProductVariantScreen = "/AutomotiveAddProductVariantScreen";
  static const String automotiveProductNestedCategoryWithInventoryScreen = "/AutomotiveProductNestedCategoryWithInventoryScreen";
  static const String automotiveMyProductProductsScreen = "/AutomotiveMyProductProductsScreen";
  static const String myMedicalVariantScreen = "/MyMedicalVariantScreen";
  static const String medicalListingScreen = "/MedicalListingScreen";
  static const String medicalCartScreen = "/MedicalCartScreen";
  static const String medicalConfirmScreen = "/MedicalConfirmScreen";
  static const String medicalHomeScreen = "/MedicalHomeScreen";
  static const String hospitalDepartmentsScreen = "/HospitalDepartmentsScreen";

  // Cart
  static const String yourCartScreen = "/YourCartScreen";

  // Global search (Discover)
  static const String globalSearchScreen = "/GlobalSearchScreen";

  // Call screens
  static const String CallListScreen = "/CallListScreen";
  static const String OutgoingCallScreen = "/OutgoingCallScreen";
  static const String IncomingCallScreen = "/IncomingCallScreen";

  // Rider call screens
  static const String IncomingRiderOrderScreen = "/IncomingRiderOrderScreen";
  static const String RiderPickupNavigationScreen = "/RiderPickupNavigationScreen";
  static const String RiderRideNavigationScreen = "/RiderRideNavigationScreen";

  // Business onboarding (WhatsApp-style)
  static const String BusinessOnboardingCategoryScreen =
      "/BusinessOnboardingCategoryScreen";
  static const String BusinessOnboardingHoursTypeScreen =
      "/BusinessOnboardingHoursTypeScreen";
  static const String BusinessOnboardingSelectHoursScreen =
      "/BusinessOnboardingSelectHoursScreen";
  static const String BusinessOnboardingPhotoScreen =
      "/BusinessOnboardingPhotoScreen";
  static const String BusinessOnboardingAddressScreen =
      "/BusinessOnboardingAddressScreen";
  static const String BusinessOnboardingDescriptionScreen =
      "/BusinessOnboardingDescriptionScreen";


  // Vehicle service (be_vehicle_service) — see
  // lib/docs/FLUTTER_INTEGRATION_GUIDE.md.
  static const String vehicleHomeScreen = "/VehicleHomeScreen";
  static const String vehicleListingScreen = "/VehicleListingScreen";
  static const String vehicleDetailScreen = "/VehicleDetailScreen";

  // Earn Pages
  static const String chooseEarnServiceScreen = "/ChooseEarnServiceScreen";
  static const String earnServiceDashboardView = "/EarnServiceDashboardView";
}
