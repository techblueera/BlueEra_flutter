import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

enum ValidationTypeEnum {
  password,
  email,
  pNumber,
  name,
  Url,
  username,
  lNumber
}

enum IndividualProfileType {
  SOCIAL_PROFILE(
    tagId: "SOCIAL_PROFILE",
    name: "Social Profile",
  ),
  SELF_EMPLOYED(
    tagId: "SELF_EMPLOYED",
    name: "Skill Work / Self Employee",
  ),
  GIG_WORKER(
    tagId: "GIG_WORKER",
    name: "Gig Worker / Transport",
  ),
  PROFESSIONAL(
    tagId: "PROFESSIONAL",
    name: "Professional / Consultant",
  );

  final String tagId;
  final String name;

  const IndividualProfileType({
    required this.tagId,
    required this.name,
  });

  /// Helper to convert a String from API back to this Enum
  static IndividualProfileType fromString(String value) {
    return IndividualProfileType.values.firstWhere(
      (e) => e.tagId == value,
      orElse: () => IndividualProfileType.SOCIAL_PROFILE, // Default fallback
    );
  }
}

enum BusinessType {
  Food,
  Product,
  Service,
  Grocery,
  Manufacturing,
  Healthcare,
  Motel,
  Siksha,
  Automotive,
  Finance,
  Both
}
// enum BusinessType { Food, Product, Service, Grocery, Health, HotelStay, Both }

/// Modes of Communication
enum CommunicationMode { ONLINE, IN_PERSON, PHONE }

extension CommunicationModeExtension on CommunicationMode {
  String get displayName {
    switch (this) {
      case CommunicationMode.ONLINE:
        return "Online";
      case CommunicationMode.IN_PERSON:
        return "In-person";
      case CommunicationMode.PHONE:
        return "Phone";
    }
  }

  static CommunicationMode fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ONLINE':
        return CommunicationMode.ONLINE;
      case 'IN_PERSON':
        return CommunicationMode.IN_PERSON;
      case 'PHONE':
        return CommunicationMode.PHONE;
      default:
        return CommunicationMode.PHONE;
    }
  }
}

///SIZED OF BUSINESS...
enum NatureOfBusiness {
  AGENCY,
  DISTRIBUTORS,
  MANUFACTURERS,
  SHOP_STORE,
  SHOWROOM,
  WHOLESALER,
  OTHERS, // keep Others last
}

extension NatureOfBusinessExtension on NatureOfBusiness {
  String get displayName {
    switch (this) {
      case NatureOfBusiness.AGENCY:
        return "Agency";
      case NatureOfBusiness.DISTRIBUTORS:
        return "Distributors";
      case NatureOfBusiness.MANUFACTURERS:
        return "Manufacturers";
      case NatureOfBusiness.SHOP_STORE:
        return "Shop/Store";
      case NatureOfBusiness.SHOWROOM:
        return "Showroom";
      case NatureOfBusiness.WHOLESALER:
        return "Wholesaler";
      case NatureOfBusiness.OTHERS:
        return "Others";
    }
  }

  static NatureOfBusiness fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'AGENCY':
        return NatureOfBusiness.AGENCY;
      case 'DISTRIBUTORS':
        return NatureOfBusiness.DISTRIBUTORS;
      case 'MANUFACTURERS':
        return NatureOfBusiness.MANUFACTURERS;
      case 'SHOP_STORE':
        return NatureOfBusiness.SHOP_STORE;
      case 'SHOWROOM':
        return NatureOfBusiness.SHOWROOM;
      case 'WHOLESALER':
        return NatureOfBusiness.WHOLESALER;
      case 'OTHERS':
        return NatureOfBusiness.OTHERS;
      default:
        return NatureOfBusiness.OTHERS;
    }
  }
}

enum ContactType { Mobile, Landline }

extension ContactTypeExtension on ContactType {
  // Get a user-friendly display name
  String get displayName {
    switch (this) {
      case ContactType.Mobile:
        return 'Mobile';
      case ContactType.Landline:
        return 'Landline';
    }
  }

  // Static method to convert a string to ContactType
  static ContactType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mobile':
        return ContactType.Mobile;
      case 'landline':
        return ContactType.Landline;
      default:
        return ContactType.Landline;
    }
  }
}

///GENDER SELECTION...
enum GenderType {
  Male,
  Female,
  Others,
}

extension GenderTypeExtension on GenderType {
  // Get display name
  String get displayName {
    switch (this) {
      case GenderType.Male:
        return 'Male';
      case GenderType.Female:
        return 'Female';
      case GenderType.Others:
        return 'Others';
    }
  }

  // Get enum from string
  static GenderType fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
        return GenderType.Male;
      case 'female':
        return GenderType.Female;
      case 'others':
        return GenderType.Others;
      default:
        return GenderType.Male;
    }
  }
}

/// FEED TYPE...
enum FeedType {
  photoPost('PHOTO_POST'),
  imagePost('IMAGE_POST'),
  messagePost('MESSAGE_POST'),
  qaPost('POLL_POST');

  final String label;

  const FeedType(this.label);

  static FeedType? fromValue(String? label) {
    if (label == null) return null;

    try {
      return FeedType.values.firstWhere(
        (e) => e.label.toUpperCase() == label.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

enum VerificationType {
  ownership('OWNERSHIP'),
  business('BUSINESS');

  final String value;

  const VerificationType(this.value);

  static VerificationType? fromValue(String? value) {
    return VerificationType.values.firstWhere(
      (e) => e.value.toUpperCase() == value?.toUpperCase(),
      orElse: () => VerificationType.ownership, // or null
    );
  }

  @override
  String toString() => value;
}

enum OwnershipDocumentType {
  aadhaarCard('Aadhaar Card'),
  voterId('Voter ID'),
  labourLicense('Labour License'),
  drivingLicense('Driving License'),
  BillOrBankPassbook('Bill / Bank Passbook');

  final String displayName;

  const OwnershipDocumentType(this.displayName);

  /// Optional: for dropdowns or displays
  static List<String> get displayNames =>
      OwnershipDocumentType.values.map((e) => e.displayName).toList();

  /// Optional: get enum from string label
  static OwnershipDocumentType? fromDisplayName(String label) {
    return OwnershipDocumentType.values.firstWhere(
      (e) => e.displayName == label,
      // orElse: () => null
    );
  }

  /// Optional: string representation for API usage
  String get value => name;
}

enum BusinessDocumentType {
  udhyamCertificate('Udhyam / MSME Certificate'),
  shopActLicense('Shop Act License'),
  laborLicense('Labor License'),
  businessPanCard('Business PAN Card'),
  fssaiLicense('FSSAI / Food License'),
  medicalLicense('Medical License'),
  otherGovtLicense('Other Government License');

  final String label;

  const BusinessDocumentType(this.label);

  /// Optional: return list of all labels
  static List<String> get labels =>
      BusinessDocumentType.values.map((e) => e.label).toList();

  /// Get enum from label (e.g., from UI selection)
  static BusinessDocumentType? fromLabel(String label) {
    return BusinessDocumentType.values.firstWhere(
      (e) => e.label == label,
      // orElse: () => null
    );
  }

  /// Optional: string value for APIs
  String get value => name;
}

enum MediaType { image, video, pdf, unknown }

enum VisitingChannelMenuAction {
  reportChannel,
  muteAccount,
  ownership,
}

enum OwnChannelMenuAction {
  channelEdit,
  channelSetting,
  addProduct,
  addService,
}

enum EditDeleteMenuAction {
  noticeEdit,
  noticeDelete,
}

/// Map Category
enum MapServiceCategory {
  services('Services'),
  homeService('Home Service'),
  foods('Foods'),
  rental('Rental');

  // stores('Stores'),
  // jobs('Jobs'),
  // places('Places');
  //TODO: remove event tab
  // events('Events');

  final String label;

  const MapServiceCategory(this.label);

  static (MapServiceCategory category, int index) fromStringWithIndex(
      String value) {
    final idx = MapServiceCategory.values.indexWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
    );

    if (idx == -1) {
      return (MapServiceCategory.services, 0); // default fallback
    }

    return (MapServiceCategory.values[idx], idx);
  }
}

extension MapCategoryExtension on String {
  MapServiceCategory? toMapCategory() {
    return MapServiceCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == this.toLowerCase(),
      // orElse: () => null,
    );
  }
}

/// Service sub category
enum ServiceCategory {
  homeServices('Home Services'),
  foods('Foods');

  final String label;

  const ServiceCategory(this.label);
}

extension ServiceCategoryExtension on String {
  ServiceCategory? toServiceCategory() {
    return ServiceCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == this.toLowerCase(),
    );
  }
}

/// Stores sub category
enum FoodCategory {
  tiffin('Tiffins'),
  bakery('Bakery'),
  sweet('Sweets'),
  others('Others');

  final String label;

  const FoodCategory(this.label);
}

/// Stores sub category
enum StoresCategory {
  clothing('Clothing'),
  footwear('Footwear'),
  giftShops('Gift Shops');

  final String label;

  const StoresCategory(this.label);
}

/// Map Category
enum PlaceCategory {
  overview('Overview'),
  posts('Posts'),
  reviews('Reviews');

  final String label;

  const PlaceCategory(this.label);
}

enum FilterInputType {
  singleSelect,
  multiSelect,
  textInput,
}

enum JobFilteredCategory {
  postedIn(label: 'Posted In'),
  salary(label: 'Salary'),
  workMode(label: 'Work Mode'),
  jobType(label: 'Job Type'),
  workShift(label: 'Work Shift'),
  department(label: 'Department');

  final String label;

  const JobFilteredCategory({required this.label});
}

enum JobIndividualCategory {
  all(label: AppStrings.all, labelId: AppConstants.All),
  applied(label: AppStrings.applied, labelId: AppConstants.Applied),
  schedules(
    label: AppStrings.schedules,
    labelId: AppConstants.SCHEDULES,
  ),
  saved(label: AppStrings.tab_saved, labelId: AppConstants.Saved);

  final String label;
  final String labelId;

  const JobIndividualCategory({required this.label, required this.labelId});
}

enum JobAppliedCategoryTab {
  all(label: AppStrings.all, labelId: AppConstants.All),
  applied(
      label: AppStrings.jobStatusInProgress, labelId: AppConstants.IN_PROGRESS),
  schedules(
      label: AppStrings.jobStatusInterview, labelId: AppConstants.INTERVIEW),
  saved(label: AppStrings.jobStatusClosed, labelId: AppConstants.CLOSED);

  final String label;
  final String labelId;

  const JobAppliedCategoryTab({required this.label, required this.labelId});
}

enum JobBusinessCategory {
  myPosts(label: AppStrings.myPosts, labelId: 'My Posts'),
  schedules(label: AppStrings.schedules, labelId: "Schedules"),
  saved(label: AppStrings.tab_saved, labelId: "Saved");

  final String label;
  final String labelId;

  const JobBusinessCategory({required this.label, required this.labelId});
}

/// Job Status
enum JobStatus {
  appliedJob('Applied Job'),
  interviewInvites('Interview Invites');

  final String label;

  const JobStatus(this.label);
}

enum ApplicationJobCategory {
  all(label: AppStrings.all, labelId: 'All'),
  shortlisted(label: AppStrings.shortlisted, labelId: 'Shortlisted'),
  interview(label: AppStrings.interview, labelId: 'Interview'),
  hired(label: AppStrings.hired, labelId: 'Hired');

  final String label;
  final String labelId;

  const ApplicationJobCategory({required this.label, required this.labelId});
}

/// Eduction Type
enum EducationType {
  graduation('Graduation / Post Graduation'),
  seniorSecondary('Add Senior Secondary (XII)'),
  secondary('Add Secondary (X)'),
  diploma('Add Diploma'),
  phd('Add PhD'),
  distributors('Distributors');

  final String label;

  const EducationType(this.label);
}

/// Work Type
enum WorkType {
  fullTime('Full Time'),
  partTime('Part Time'),
  internship('Internship'),
  freelance('Freelance'),
  contract('Contract'),
  temporary('Temporary'),
  volunteer('Volunteer');

  final String label;

  const WorkType(this.label);
}

/// Work Mode
enum WorkMode {
  remote('Remote'),
  wfo('Work From Office'),
  hybrid('Hybrid');

  final String label;

  const WorkMode(this.label);
}

/// Skill Type
enum SkillType {
  uiDesign('UI Design'),
  uxDesign('UX Design'),
  websiteDesign('Website Design'),
  productDesign('Product Design'),
  softwareDesign('Software Design'),
  graphicDesign('Graphic Design'),
  animation('Animation'),
  flutter('Flutter'),
  dart('Dart');

  final String label;

  const SkillType(this.label);
}

///Languages
enum LanguageType {
  english('English'),
  hindi('Hindi'),
  bengali('Bengali'),
  tamil('Tamil'),
  marathi('Marathi'),
  gujarati('Gujarati'),
  telugu('Telugu'),
  kannada('Kannada'),
  urdu('Urdu'),
  malayalam('Malayalam'),
  punjabi('Punjabi'),
  odia('Odia');

  final String label;

  const LanguageType(this.label);
}

/// Hobbies
enum HobbyType {
  reading('Reading'),
  traveling('Traveling'),
  photography('Photography'),
  painting('Painting'),
  music('Music'),
  gardening('Gardening'),
  gaming('Gaming'),
  yoga('Yoga'),
  cooking('Cooking');

  final String label;

  const HobbyType(this.label);
}

enum BlockedType {
  full('FULL'),
  partial('PARTIAL');

  final String label;

  const BlockedType(this.label);
}

enum Shorts {
  trending,
  nearBy,
  personalized,
  saved,
  latest,
  popular,
  oldest,
  underProgress,
  draft,

  /// Home-feed tap buckets: opening a `short_video` / `long_video` card from the
  /// home feed seeds one of these with the tapped video, then infinite-scrolls
  /// via `/videos/hot/short` and `/videos/hot/long` respectively. Kept separate
  /// from [trending] so the Reels tab's list/scroll position is never clobbered.
  homeShort,
  homeLong,
}

extension ShortsX on Shorts {
  /// Label for UI display
  String get label {
    switch (this) {
      case Shorts.trending:
        return 'Trending';
      case Shorts.nearBy:
        return 'Near By';
      case Shorts.personalized:
        return 'Personalized';
      case Shorts.saved:
        return 'Saved';
      case Shorts.latest:
        return 'Latest';
      case Shorts.popular:
        return 'Popular';
      case Shorts.oldest:
        return 'Oldest';
      case Shorts.underProgress:
        return 'Under Progress';
      case Shorts.draft:
        return 'Draft';
      case Shorts.homeShort:
        return 'Short';
      case Shorts.homeLong:
        return 'Video';
    }
  }

  /// Query value for API
  String get queryValue {
    switch (this) {
      case Shorts.trending:
        return 'trending';
      case Shorts.nearBy:
        return 'near_by';
      case Shorts.personalized:
        return 'personalized';
      case Shorts.saved:
        return 'saved';
      case Shorts.latest:
        return 'latest';
      case Shorts.popular:
        return 'popular';
      case Shorts.oldest:
        return 'oldest';
      case Shorts.underProgress:
        return 'under_progress';
      case Shorts.draft:
        return 'draft';
      case Shorts.homeShort:
        return 'short';
      case Shorts.homeLong:
        return 'long';
    }
  }
}

enum VideoType {
  videoFeed,
  saved,
  latest,
  popular,
  oldest,
  underProgress,
  draft,
}

extension VideosX on VideoType {
  /// Label for UI display
  String get label {
    switch (this) {
      case VideoType.videoFeed:
        return 'Video Feed';
      case VideoType.saved:
        return 'Saved';
      case VideoType.latest:
        return 'Latest';
      case VideoType.popular:
        return 'Popular';
      case VideoType.oldest:
        return 'Oldest';
      case VideoType.underProgress:
        return 'Under Progress';
      case VideoType.draft:
        return 'Draft';
    }
  }

  /// Query value for API
  String get queryValue {
    switch (this) {
      case VideoType.videoFeed:
        return 'video_feed';
      case VideoType.saved:
        return 'saved';
      case VideoType.latest:
        return 'latest';
      case VideoType.popular:
        return 'popular';
      case VideoType.oldest:
        return 'oldest';
      case VideoType.underProgress:
        return 'under_progress';
      case VideoType.draft:
        return 'draft';
    }
  }
}

enum PostType {
  all,
  myPosts,
  otherPosts,
  saved,
  latest,
  popular,
  oldest,
  otherChannelPosts

  // ownChannelPosts,
  // visitingChannelPosts
}

enum SymbolPostType { image, video, text, link }

enum PaymentMethod { upi, card }

enum SortBy {
  Latest('Latest', 'latest'),
  Popular('Popular', 'popular'),
  Oldest('Oldest', 'oldest'),
  UnderProgress('Under Progress', 'under_progress');

  final String label;
  final String queryValue;

  const SortBy(this.label, this.queryValue);
}

enum VideoStatus {
  draft('Draft', 'draft'),
  processing('Processing', 'processing'),
  published('Published', 'published'),
  failed('Failed', 'failed'),
  all('All', 'all');

  final String label;
  final String queryValue;

  const VideoStatus(this.label, this.queryValue);
}

enum PostCreationMenu {
  message,
  symbol,
  poll,
  // photos,
  reel,
  jobPost;
  // travel;
}

enum PostVia { profile, channel }

enum StoreType {
  inventory,
  service,
  food,
  business,
}

extension StoreTypeExtension on StoreType {
  String get value {
    switch (this) {
      case StoreType.inventory:
        return 'product';
      case StoreType.service:
        return 'service';
      case StoreType.food:
        return 'food';
      case StoreType.business:
        return 'business';
    }
  }

  static StoreType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'product':
        return StoreType.inventory;
      case 'service':
        return StoreType.service;
      case 'food':
        return StoreType.food;
      case 'business':
        return StoreType.business;
      default:
        return StoreType.inventory;
    }
  }
}

enum ProviderType {
  user,
  business,
  channel;

  String get title => name[0].toUpperCase() + name.substring(1);
}

enum ChargesTypes {
  Hourly('Hourly'),
  Daily('Daily'),
  Weekly('Weekly'),
  Monthly('Monthly'),
  Yearly('Yearly'),
  KM('KM');

  final String label;

  const ChargesTypes(this.label);
}

enum VehicleRegistrationType { Personal, Commercial }

extension VehicleRegistrationTypeExtension on VehicleRegistrationType {
  // Get display name
  String get displayName {
    switch (this) {
      case VehicleRegistrationType.Personal:
        return 'Personal';
      case VehicleRegistrationType.Commercial:
        return 'Commercial';
    }
  }

  // Get enum from string
  static VehicleRegistrationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'personal':
        return VehicleRegistrationType.Personal;
      case 'commercial':
        return VehicleRegistrationType.Commercial;
      default:
        return VehicleRegistrationType.Personal;
    }
  }
}

enum RentalVehicleRegistrationType {
  Personal,
  Commercial,
  CommercialGoods,
}

extension RentalRegistrationTypeExtension on RentalVehicleRegistrationType {
  // Get display name
  String get displayName {
    switch (this) {
      case RentalVehicleRegistrationType.Personal:
        return 'Personal';
      case RentalVehicleRegistrationType.Commercial:
        return 'Commercial';
      case RentalVehicleRegistrationType.CommercialGoods:
        return 'Commercial Goods';
    }
  }

  // Get enum from string
  static VehicleRegistrationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'personal':
        return VehicleRegistrationType.Personal;
      case 'commercial':
        return VehicleRegistrationType.Commercial;
      default:
        return VehicleRegistrationType.Personal;
    }
  }
}

enum VehicleType {
  TwoWheeler,
  ThreeWheeler,
  FourWheeler,
  HeavyVehicle,
}

extension VehicleTypeExtension on VehicleType {
  // Get display name
  String get displayName {
    switch (this) {
      case VehicleType.TwoWheeler:
        return 'Two Wheeler';
      case VehicleType.ThreeWheeler:
        return 'Three Wheeler';
      case VehicleType.FourWheeler:
        return 'Four Wheeler';
      case VehicleType.HeavyVehicle:
        return 'Heavy Vehicle';
    }
  }

  // Get enum from string
  static VehicleType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'twowheeler':
      case 'two_wheeler':
        return VehicleType.TwoWheeler;
      case 'threewheeler':
      case 'three_wheeler':
        return VehicleType.ThreeWheeler;
      case 'fourwheeler':
      case 'four_wheeler':
        return VehicleType.FourWheeler;
      case 'heavyvehicle':
      case 'heavy_vehicle':
        return VehicleType.HeavyVehicle;
      default:
        return VehicleType.FourWheeler; // default fallback
    }
  }
}

enum FuelType {
  Petrol,
  Diesel,
  Electric,
  Hybrid,
  CNG,
  LPG,
}

extension FuelTypeExtension on FuelType {
  // Get display name
  String get displayName {
    switch (this) {
      case FuelType.Petrol:
        return 'Petrol';
      case FuelType.Diesel:
        return 'Diesel';
      case FuelType.Electric:
        return 'Electric';
      case FuelType.Hybrid:
        return 'Hybrid';
      case FuelType.CNG:
        return 'CNG';
      case FuelType.LPG:
        return 'LPG';
    }
  }

  // Get enum from string
  static FuelType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'petrol':
        return FuelType.Petrol;
      case 'diesel':
        return FuelType.Diesel;
      case 'electric':
        return FuelType.Electric;
      case 'hybrid':
        return FuelType.Hybrid;
      case 'cng':
        return FuelType.CNG;
      case 'lpg':
        return FuelType.LPG;
      default:
        return FuelType.Petrol; // default fallback
    }
  }
}

enum DeliveryPartnerOrdersTab {
  pickUp(AppStrings.pickUp),
  grocery(AppStrings.grocery),
  parcel(AppStrings.parcel),
  income(AppStrings.income);

  final String label;

  const DeliveryPartnerOrdersTab(this.label);
}

enum PickUpTab {
  newOrder(AppStrings.newOrder),
  onGoing(AppStrings.onGoing),
  orders(AppStrings.pickUpOrders),
  completed(AppStrings.completed),
  cancel(AppStrings.cancel),
  rejected(AppStrings.rejected);

  final String label;

  const PickUpTab(this.label);
}

enum ChannelTab {
  posts,
  saved,
  statistics,
  product,
  Service;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChannelTab.posts:
        return AppStrings.post; // Example localized string

      case ChannelTab.saved:
        return AppStrings.tab_saved;
      case ChannelTab.statistics:
        return AppStrings.tab_statistics;
      case ChannelTab.product:
        return AppStrings.tab_product;
      case ChannelTab.Service:
        return AppStrings.tab_service;
    }
  }
}

enum InventoryMenuItem {
  addProduct,
  addService,
  addFood,
}

extension InventoryMenuItemExt on InventoryMenuItem {
  String get title {
    switch (this) {
      case InventoryMenuItem.addProduct:
        return AppStrings.addProduct;
      case InventoryMenuItem.addService:
        return AppStrings.addService;
      case InventoryMenuItem.addFood:
        return AppStrings.addFood;
    }
  }
}

enum RentalServiceType {
  homeStay(AppStrings.homeStay),
  flatRoom(AppStrings.flatRoom),
  vehicle(AppStrings.vehicle);

  final String label;

  const RentalServiceType(this.label);
}

extension RentalServiceTabApi on RentalServiceType {
  String get apiValue {
    switch (this) {
      case RentalServiceType.homeStay:
        return AppConstants.property; // <--- API string
      case RentalServiceType.flatRoom:
        return AppConstants.flat; // <--- API string
      case RentalServiceType.vehicle:
        return AppConstants.vehicle; // <--- API string
    }
  }
}

extension RentalServiceTypeParser on String {
  RentalServiceType toRentalServiceType() {
    switch (this) {
      case AppConstants.property:
        return RentalServiceType.homeStay;
      case AppConstants.flat:
        return RentalServiceType.flatRoom;
      case AppConstants.vehicle:
        return RentalServiceType.vehicle;
      default:
        throw Exception("Unknown RentalServiceType: $this");
    }
  }
}

enum RiderVerificationState { completed, rejected, pending }

enum EarnServiceOrdersStatus {
  newAndOnGoingOrder('New'),
  // onGoing('On-Going'),
  completed('Completed'),
  cancelled("Cancelled");

  final String label;

  const EarnServiceOrdersStatus(this.label);
}

enum BankAccountType {
  savings('Saving'),
  current('Current');
  // overdraft('Overdraft'),
  // salary('Salary'),
  // fixedDeposit('FixedDeposit'),
  // recurringDeposit('RecurringDeposit');

  final String displayName;

  const BankAccountType(this.displayName);
}

extension BankAccountTypeExtension on BankAccountType {
  /// Converts a dynamic string from an API to a [BankAccountType]
  static BankAccountType fromString(String? value) {
    if (value == null) return BankAccountType.savings; // Default fallback

    // Normalizing the string to lowercase and removing spaces/underscores
    // to match enum values robustly
    final normalizedValue =
        value.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

    return BankAccountType.values.firstWhere(
      (type) => type.name.toLowerCase() == normalizedValue,
      orElse: () => BankAccountType.savings, // Fallback if no match found
    );
  }
}

enum BedType {
  singleBed("Single Bed"),
  twinBed("Twin Bed"),
  doubleBed("Double Bed"),
  queenBed("Queen Bed"),
  kingBed("King Bed"),
  superKingBed("Super King Bed"),
  extraBed("Extra Bed"),
  sofaBed("Sofa Bed"),
  bunkBed("Bunk Bed"),
  murphyBed("Murphy Bed");

  final String name;
  const BedType(this.name);
}

enum OccupancyType {
  single("Single Occupancy"),
  double("Double Occupancy"),
  triple("Triple Occupancy"),
  quad("Quad Occupancy"),
  twinSharing("Twin Sharing"),
  doubleSharing("Double Sharing"),
  family("Family Occupancy"),
  group("Group Occupancy");

  final String name;
  const OccupancyType(this.name);
}

enum MyGroceryOrdersTab {
  pending(AppStrings.pending),
  completed(AppStrings.completed),
  cancelled(AppStrings.canceled),
  payment(AppStrings.payment);

  final String label;

  const MyGroceryOrdersTab(this.label);
}

enum GroceryPaymentMode {
  cash('Cash', 'cash'),
  upi('UPI', 'upi'),
  pending('Pending', 'pending');

  final String label;
  final String apiValue;

  // Constructor
  const GroceryPaymentMode(this.label, this.apiValue);
}

enum ServiceType {
  residential('Residential', 'residential'),
  commercial('Commercial', 'commercial'),
  industrial('Industrial', 'industrial'),
  maintenance('Maintenance & Repair', 'maintenance'),
  emergency('Emergency Service', 'emergency');

  // Properties
  final String label; // What the user sees (e.g., "Residential")
  final String apiValue; // What you send to the server (e.g., "residential")

  // Constructor
  const ServiceType(this.label, this.apiValue);

  // Helper: Get just the labels for Dropdowns
  static List<String> get labels => values.map((e) => e.label).toList();
}

enum Qualification {
  below10('BELOW_10', 'Below 10th'),
  pass10('10_PASS', '10th Pass'),
  pass12('12_PASS', '12th Pass'),
  graduate('GRADUATE', 'Graduate / Degree'),
  postGraduate('POST_GRADUATE', 'Post Graduate');

  final String value;
  final String displayName;

  const Qualification(this.value, this.displayName);
}

// meal_type.dart
enum MealType {
  morningTiffin,
  breakfast,
  eveningDinner;

  static MealType fromKey(String? key) {
    switch (key) {
      case 'morningTiffin':
        return MealType.morningTiffin;
      case 'breakfast':
        return MealType.breakfast;
      case 'eveningDinner':
        return MealType.eveningDinner;
      default:
        return MealType.morningTiffin;
    }
  }
}

enum FoodCategoryType {
  bakery,
  namkeens,
  sweets,
  pickles;

  static FoodCategoryType fromKey(String? key) {
    switch (key) {
      case 'bakery':
        return FoodCategoryType.bakery;
      case 'namkeens':
        return FoodCategoryType.namkeens;
      case 'sweets':
        return FoodCategoryType.sweets;
      case 'pickles':
        return FoodCategoryType.pickles;
      default:
        return FoodCategoryType.bakery;
    }
  }
}

// // ✅ only needed when saving credentials (password fields)
// TextInput.finishAutofillContext();

enum AutoFillType {
  email,
  username,
  password,
  newPassword,
  phone,
  name,
  firstName,
  lastName,
  address,
  postalCode,
  creditCard,
  oneTimeCode,
  none,
}

extension AutoFillTypeExtension on AutoFillType {
  Iterable<String>? get hints {
    switch (this) {
      case AutoFillType.email:
        return [AutofillHints.email];
      case AutoFillType.username:
        return [AutofillHints.username];
      case AutoFillType.password:
        return [AutofillHints.password];
      case AutoFillType.newPassword:
        return [AutofillHints.newPassword];
      case AutoFillType.phone:
        return [AutofillHints.telephoneNumber];
      case AutoFillType.name:
        return [AutofillHints.name];
      case AutoFillType.firstName:
        return [AutofillHints.givenName];
      case AutoFillType.lastName:
        return [AutofillHints.familyName];
      case AutoFillType.address:
        return [AutofillHints.fullStreetAddress];
      case AutoFillType.postalCode:
        return [AutofillHints.postalCode];
      case AutoFillType.creditCard:
        return [AutofillHints.creditCardNumber];
      case AutoFillType.oneTimeCode:
        return [AutofillHints.oneTimeCode];
      case AutoFillType.none:
        return null;
    }
  }
}
