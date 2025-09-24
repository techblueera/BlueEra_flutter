import 'package:BlueEra/core/constants/app_constant.dart';

enum ValidationTypeEnum { password, email, pNumber, name, Url, username, lNumber }

///API TYPES
enum APIType { aPost, aGet, aDelete, aPut }

enum BusinessType { Food,Product, Service, Both }


extension BusinessTypeExtension on BusinessType {
  // Get display name
  String get displayName {
    switch (this) {
      case BusinessType.Food:
        return 'Food';
      case BusinessType.Product:
        return 'Product';
      case BusinessType.Service:
        return 'Service';
      case BusinessType.Both:
        return 'Both';
    }
  }

  // Get enum from string
  static BusinessType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'food':
        return BusinessType.Food;
      case 'product':
        return BusinessType.Product;
      case 'service':
        return BusinessType.Service;
      case 'both':
        return BusinessType.Both;
      default:
        return BusinessType.Both;

        throw ArgumentError('Invalid BusinessType value: $value');
    }
  }
}


//
// enum BusinessType { Product, Service, Both }
//
// // enum BusinessType { Product, Service, Both }
//
// extension BusinessTypeExtension on BusinessType {
//   // Get display name
//   String get displayName {
//     switch (this) {
//       case BusinessType.Product:
//         return 'Product';
//       case BusinessType.Service:
//         return 'Service';
//       case BusinessType.Both:
//         return 'Both';
//     }
//   }
//
//   // Get enum from string
//   static BusinessType fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'product':
//         return BusinessType.Product;
//       case 'service':
//         return BusinessType.Service;
//       case 'both':
//         return BusinessType.Both;
//       default:
//         return BusinessType.Both;
//
//         throw ArgumentError('Invalid BusinessType value: $value');
//     }
//   }
// }
// POLITICIANORSOCIALIST,

///FOR CREATE PERSONAL ACCOUNT...
enum ProfessionType {
  SELF_EMPLOYED,
  PRIVATE_JOB,
  GOVERNMENT_JOB,
  SKILLED_WORKER,
  CONTENT_CREATOR,
  POLITICIAN,
  GOVTPSU,
  REG_UNION,
  MEDIA,
  ARTIST,
  INDUSTRIALIST,
  SOCIALIST,
  HOMEMAKER,
  FARMER,
  SENIOR_CITIZEN_RETIRED,
  STUDENT,
  OTHERS, // keep Others last
}

extension ProfessionTypeExtension on ProfessionType {
  String get displayName {
    switch (this) {
      case ProfessionType.ARTIST:
        return "Artist";
      case ProfessionType.INDUSTRIALIST:
        return "Industrialist";
      case ProfessionType.FARMER:
        return "Farmer";
      case ProfessionType.GOVERNMENT_JOB:
        return "Government Job";
      case ProfessionType.HOMEMAKER:
        return "Homemaker";
      case ProfessionType.MEDIA:
        return "Media";
      case ProfessionType.PRIVATE_JOB:
        return "Private Job";
      case ProfessionType.POLITICIAN:
        return "Politician";
      case ProfessionType.SOCIALIST:
        return "Socialist";
      case ProfessionType.GOVTPSU:
        return "Govt. / PSU Department";
      case ProfessionType.SELF_EMPLOYED:
        return "Self Employed";
      case ProfessionType.SENIOR_CITIZEN_RETIRED:
        return "Senior Citizen / Retired";
      case ProfessionType.SKILLED_WORKER:
        return "Skilled Worker";
      case ProfessionType.STUDENT:
        return "Student";
      case ProfessionType.REG_UNION:
        return "Reg. NGO/ Union/ Society";
      case ProfessionType.CONTENT_CREATOR:
        return "Content Creator";
      case ProfessionType.OTHERS:
        return "Others";
    }
  }

  static ProfessionType fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ARTIST':
        return ProfessionType.ARTIST;
      case 'INDUSTRIALIST':
        return ProfessionType.INDUSTRIALIST;
      case 'FARMER':
        return ProfessionType.FARMER;
      case 'GOVERNMENT_JOB':
        return ProfessionType.GOVERNMENT_JOB;
      case 'HOMEMAKER':
        return ProfessionType.HOMEMAKER;
      case 'MEDIA':
        return ProfessionType.MEDIA;
      case 'PRIVATE_JOB':
        return ProfessionType.PRIVATE_JOB;
      case 'POLITICIAN':
        return ProfessionType.POLITICIAN;
      case 'SOCIALIST':
        return ProfessionType.SOCIALIST;
      case 'GOVTPSU':
        return ProfessionType.GOVTPSU;
      case 'SELF_EMPLOYED':
        return ProfessionType.SELF_EMPLOYED;
      case 'SENIOR_CITIZEN_RETIRED':
        return ProfessionType.SENIOR_CITIZEN_RETIRED;
      case 'SKILLED_WORKER':
        return ProfessionType.SKILLED_WORKER;
      case 'STUDENT':
        return ProfessionType.STUDENT;
      case 'REG_UNION':
        return ProfessionType.REG_UNION;
      case 'CONTENT_CREATOR':
        return ProfessionType.CONTENT_CREATOR;
      case 'OTHERS':
        return ProfessionType.OTHERS;

      default:
        return ProfessionType.OTHERS;

        // throw ArgumentError(value);
        throw ArgumentError('Invalid ProfessionType value: $value');
    }
  }
}

enum SelfEmploymentType {
  ELECTRICIAN,
  PLUMBER,
  PAINTER,
  TECHNICIAN,
  MAID_CLEANER,
  CARPENTER,
  CAR_DRIVER_TAXI,
  DELIVERY_RIDER,
  MECHANIC,
  TAILOR,
  BEAUTICIAN,
  HOME_RENOVATION,
  GARDENER, // added if required
  OTHER,
}

extension SelfEmploymentTypeExtension on SelfEmploymentType {
  String get displayName {
    switch (this) {
      case SelfEmploymentType.ELECTRICIAN:
        return "Electrician";
      case SelfEmploymentType.PLUMBER:
        return "Plumber";
      case SelfEmploymentType.TECHNICIAN:
        return "Technician";
      case SelfEmploymentType.MAID_CLEANER:
        return "Maid / Cleaner";
      case SelfEmploymentType.CARPENTER:
        return "Carpenter";
      case SelfEmploymentType.CAR_DRIVER_TAXI:
        return "Car Driver / Taxi";
      case SelfEmploymentType.DELIVERY_RIDER:
        return "Delivery / Rider";
      case SelfEmploymentType.MECHANIC:
        return "Mechanic";
      case SelfEmploymentType.TAILOR:
        return "Tailor";
      case SelfEmploymentType.BEAUTICIAN:
        return "Beautician";
      case SelfEmploymentType.HOME_RENOVATION:
        return "Home Renovation";
      case SelfEmploymentType.PAINTER:
        return "Painter";
      case SelfEmploymentType.GARDENER:
        return "Gardener";
      case SelfEmploymentType.OTHER:
        return "Other";
    }
  }

  static SelfEmploymentType fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ELECTRICIAN':
        return SelfEmploymentType.ELECTRICIAN;
      case 'PLUMBER':
        return SelfEmploymentType.PLUMBER;
      case 'TECHNICIAN':
        return SelfEmploymentType.TECHNICIAN;
      case 'MAID_CLEANER':
        return SelfEmploymentType.MAID_CLEANER;
      case 'CARPENTER':
        return SelfEmploymentType.CARPENTER;
      case 'CAR_DRIVER_TAXI':
        return SelfEmploymentType.CAR_DRIVER_TAXI;
      case 'DELIVERY_RIDER':
        return SelfEmploymentType.DELIVERY_RIDER;
      case 'MECHANIC':
        return SelfEmploymentType.MECHANIC;
      case 'TAILOR':
        return SelfEmploymentType.TAILOR;
      case 'BEAUTICIAN':
        return SelfEmploymentType.BEAUTICIAN;
      case 'HOME_RENOVATION':
        return SelfEmploymentType.HOME_RENOVATION;
      case 'PAINTER':
        return SelfEmploymentType.PAINTER;
      case 'GARDENER':
        return SelfEmploymentType.GARDENER;
      case 'OTHER':
        return SelfEmploymentType.OTHER;
      default:
        return SelfEmploymentType.OTHER;

        throw ArgumentError('Invalid SelfEmploymentType value: $value');
    }
  }
}

enum BankAccountType {
  SAVINGS,
  CURRENT,
}

extension AccountTypeExtension on BankAccountType {
  String get displayName {
    switch (this) {
      case BankAccountType.SAVINGS:
        return "Saving";
      case BankAccountType.CURRENT:
        return "Current";
    }
  }

  static BankAccountType fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'SAVINGS':
        return BankAccountType.SAVINGS;
      case 'CURRENT':
        return BankAccountType.CURRENT;
      default:
        throw ArgumentError('Invalid AccountType value: $value');
    }
  }
}

enum ArtistCategory {
  ACTOR_ACTRESS,
  DANCER,
  THEATRE_ARTIST,
  MIME_ARTIST,
  SINGER_VOCALIST,
  MUSICIAN_INSTRUMENTALIST,
  COMPOSER,
  DJ_MUSIC_PRODUCER,
  PHOTOGRAPHER,
  VIDEOGRAPHER,
  CINEMATOGRAPHER,
  FILM_DIRECTOR,
  FASHION_DESIGNER,
  INTERIOR_DESIGNER,
  CRAFTSPERSON,
  JEWELRY_DESIGNER,
  WRITER_AUTHOR,
  POET,
  SCREENWRITER,
  STORYTELLER,
  PAINTER,
  SCULPTOR,
  ILLUSTRATOR,
  MURAL_ARTIST,
  CALLIGRAPHER,
  DIGITAL_ARTIST,
  OTHER,
}

extension ArtistCategoryExtension on ArtistCategory {
  String get displayName {
    switch (this) {
      case ArtistCategory.PAINTER:
        return "Painter";
      case ArtistCategory.SCULPTOR:
        return "Sculptor";
      case ArtistCategory.ILLUSTRATOR:
        return "Illustrator";
      case ArtistCategory.MURAL_ARTIST:
        return "Mural Artist";
      case ArtistCategory.CALLIGRAPHER:
        return "Calligrapher";
      case ArtistCategory.DIGITAL_ARTIST:
        return "Digital Artist";
      case ArtistCategory.ACTOR_ACTRESS:
        return "Actor / Actress";
      case ArtistCategory.DANCER:
        return "Dancer";
      case ArtistCategory.THEATRE_ARTIST:
        return "Theatre Artist";
      case ArtistCategory.MIME_ARTIST:
        return "Mime Artist";
      case ArtistCategory.SINGER_VOCALIST:
        return "Singer / Vocalist";
      case ArtistCategory.MUSICIAN_INSTRUMENTALIST:
        return "Musician (Instrumentalist)";
      case ArtistCategory.COMPOSER:
        return "Composer";
      case ArtistCategory.DJ_MUSIC_PRODUCER:
        return "DJ / Music Producer";
      case ArtistCategory.PHOTOGRAPHER:
        return "Photographer";
      case ArtistCategory.VIDEOGRAPHER:
        return "Videographer";
      case ArtistCategory.CINEMATOGRAPHER:
        return "Cinematographer";
      case ArtistCategory.FILM_DIRECTOR:
        return "Film Director";
      case ArtistCategory.FASHION_DESIGNER:
        return "Fashion Designer";
      case ArtistCategory.INTERIOR_DESIGNER:
        return "Interior Designer";
      case ArtistCategory.CRAFTSPERSON:
        return "Craftsperson";
      case ArtistCategory.JEWELRY_DESIGNER:
        return "Jewelry Designer";
      case ArtistCategory.WRITER_AUTHOR:
        return "Writer / Author";
      case ArtistCategory.POET:
        return "Poet";
      case ArtistCategory.SCREENWRITER:
        return "Screenwriter";
      case ArtistCategory.STORYTELLER:
        return "Storyteller";
      case ArtistCategory.OTHER:
        return "Other";
    }
  }

  static ArtistCategory fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PAINTER':
        return ArtistCategory.PAINTER;
      case 'SCULPTOR':
        return ArtistCategory.SCULPTOR;
      case 'ILLUSTRATOR':
        return ArtistCategory.ILLUSTRATOR;
      case 'MURAL_ARTIST':
        return ArtistCategory.MURAL_ARTIST;
      case 'CALLIGRAPHER':
        return ArtistCategory.CALLIGRAPHER;
      case 'DIGITAL_ARTIST':
        return ArtistCategory.DIGITAL_ARTIST;
      case 'ACTOR_ACTRESS':
        return ArtistCategory.ACTOR_ACTRESS;
      case 'DANCER':
        return ArtistCategory.DANCER;
      case 'THEATRE_ARTIST':
        return ArtistCategory.THEATRE_ARTIST;
      case 'MIME_ARTIST':
        return ArtistCategory.MIME_ARTIST;
      case 'SINGER_VOCALIST':
        return ArtistCategory.SINGER_VOCALIST;
      case 'MUSICIAN_INSTRUMENTALIST':
        return ArtistCategory.MUSICIAN_INSTRUMENTALIST;
      case 'COMPOSER':
        return ArtistCategory.COMPOSER;
      case 'DJ_MUSIC_PRODUCER':
        return ArtistCategory.DJ_MUSIC_PRODUCER;
      case 'PHOTOGRAPHER':
        return ArtistCategory.PHOTOGRAPHER;
      case 'VIDEOGRAPHER':
        return ArtistCategory.VIDEOGRAPHER;
      case 'CINEMATOGRAPHER':
        return ArtistCategory.CINEMATOGRAPHER;
      case 'FILM_DIRECTOR':
        return ArtistCategory.FILM_DIRECTOR;
      case 'FASHION_DESIGNER':
        return ArtistCategory.FASHION_DESIGNER;
      case 'INTERIOR_DESIGNER':
        return ArtistCategory.INTERIOR_DESIGNER;
      case 'CRAFTSPERSON':
        return ArtistCategory.CRAFTSPERSON;
      case 'JEWELRY_DESIGNER':
        return ArtistCategory.JEWELRY_DESIGNER;
      case 'WRITER_AUTHOR':
        return ArtistCategory.WRITER_AUTHOR;
      case 'POET':
        return ArtistCategory.POET;
      case 'SCREENWRITER':
        return ArtistCategory.SCREENWRITER;
      case 'STORYTELLER':
        return ArtistCategory.STORYTELLER;
      case 'OTHER':
        return ArtistCategory.OTHER;
      default:
        return ArtistCategory.OTHER;

        throw ArgumentError('Invalid ArtistCategory value: $value');
    }
  }
}

/// Types of Business
enum TypesOfBusiness { SELL_PRODUCTS, PROVIDE_SERVICE, BOTH_SEEL_AND_PRODUCT }

extension TypesOfBusinessExtension on TypesOfBusiness {
  String get displayName {
    switch (this) {
      case TypesOfBusiness.SELL_PRODUCTS:
        return "Sell Products (e.g. Clothes, General Store) ";
      case TypesOfBusiness.PROVIDE_SERVICE:
        return "Provide Services (e.g. Teacher, Doctor)";
      case TypesOfBusiness.BOTH_SEEL_AND_PRODUCT:
        return "Both Sell & Provide Services (e.g. Clinic with Doctor and Medicines)";
    }
  }

  static TypesOfBusiness fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'SELL_PRODUCTS':
        return TypesOfBusiness.SELL_PRODUCTS;
      case 'PROVIDE_SERVICE':
        return TypesOfBusiness.PROVIDE_SERVICE;
      case 'BOTH_SELL_AND_PRODUCT':
        return TypesOfBusiness.BOTH_SEEL_AND_PRODUCT;
      default:
        return TypesOfBusiness.BOTH_SEEL_AND_PRODUCT;

        throw ArgumentError('Invalid ContactType value: $value');
    }
  }
}

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

        throw ArgumentError('Invalid CommunicationMode value: $value');
    }
  }
}

// enum CategoryOfBusiness {
//   FOOD,
//   RESTAURANT,
//   FASHIONORCLOTHES,
// }

// extension CategoryOfBusinessExtension on CategoryOfBusiness {
//   String get displayName {
//     switch (this) {
//       case CategoryOfBusiness.FOOD:
//         return "Food";
//       case CategoryOfBusiness.RESTAURANT:
//         return "Restaurant";
//       case CategoryOfBusiness.FASHIONORCLOTHES:
//         return "Fashion & Clothes";
//     }
//   }

//   static CategoryOfBusiness fromString(String value) {
//     switch (value.trim().toUpperCase()) {
//       case 'FOOD':
//         return CategoryOfBusiness.FOOD;
//       case 'RESTAURANT':
//         return CategoryOfBusiness.RESTAURANT;
//       case 'FASHIONORCLOTHES':
//         return CategoryOfBusiness.FASHIONORCLOTHES;
//       default:
//         throw ArgumentError('Invalid CategoryOfBusiness value: $value');
//     }
//   }
// }

///SIZED OF BUSINESS...
enum SizeOfBusiness {
  AGENCY,
  DISTRIBUTORS,
  MANUFACTURERS,
  SHOP_STORE,
  SHOWROOM,
  WHOLESALER,
  OTHERS, // keep Others last
}

extension SizeOfBusinessExtension on SizeOfBusiness {
  String get displayName {
    switch (this) {
      case SizeOfBusiness.AGENCY:
        return "Agency";
      case SizeOfBusiness.DISTRIBUTORS:
        return "Distributors";
      case SizeOfBusiness.MANUFACTURERS:
        return "Manufacturers";
      case SizeOfBusiness.SHOP_STORE:
        return "Shop/Store";
      case SizeOfBusiness.SHOWROOM:
        return "Showroom";
      case SizeOfBusiness.WHOLESALER:
        return "Wholesaler";
      case SizeOfBusiness.OTHERS:
        return "Others";
    }
  }

  static SizeOfBusiness fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'AGENCY':
        return SizeOfBusiness.AGENCY;
      case 'DISTRIBUTORS':
        return SizeOfBusiness.DISTRIBUTORS;
      case 'MANUFACTURERS':
        return SizeOfBusiness.MANUFACTURERS;
      case 'SHOP_STORE':
        return SizeOfBusiness.SHOP_STORE;
      case 'SHOWROOM':
        return SizeOfBusiness.SHOWROOM;
      case 'WHOLESALER':
        return SizeOfBusiness.WHOLESALER;
      case 'OTHERS':
        return SizeOfBusiness.OTHERS;
      default:
        return SizeOfBusiness.OTHERS;

        throw ArgumentError('Invalid SizeOfBusiness value: $value');
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

        throw ArgumentError('Invalid ContactType value: $value');
    }
  }
}

///GENDER SELECTION...
enum GenderType {
  Male,
  Female,
  Transgender,
}

extension GenderTypeExtension on GenderType {
  // Get display name
  String get displayName {
    switch (this) {
      case GenderType.Male:
        return 'Male';
      case GenderType.Female:
        return 'Female';
      case GenderType.Transgender:
        return 'Transgender';
    }
  }

  // Get enum from string
  static GenderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return GenderType.Male;
      case 'female':
        return GenderType.Female;
      case 'transgender':
        return GenderType.Transgender;
      default:
        return GenderType.Male;

        throw ArgumentError('Invalid Gender value: $value');
    }
  }
}
/// FEED TYPE...
enum FeedType {
  photoPost('PHOTO_POST'),
  imagePost('IMAGE_POST'),
  messagePost('MESSAGE_POST'),
  qaPost('POLL_POST'),
  shorts('SHORTS');


  final String label;

  const FeedType(this.label);

  static FeedType? fromValue(String? label) {
    return FeedType.values.firstWhere(
      (e) => e.label.toUpperCase() == label?.toUpperCase(),
      // orElse: () => null, // or null
    );
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
  // blockUser,
  muteAccount,
  ownership,
}

enum OwnChannelMenuAction {
  channelEdit,
  chennelSetting,
  addVideo,
  addProduct,
}

/// Map Category
enum MapCategory {
  services('Services'),
  stores('Stores'),
  jobs('Jobs'),
  places('Places');
  //TODO: remove event tab
  // events('Events');

  final String label;

  const MapCategory(this.label);
}

extension MapCategoryExtension on String {
  MapCategory? toMapCategory() {
    return MapCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == this.toLowerCase(),
      // orElse: () => null,
    );
  }
}

/// Service sub category
enum ServiceCategory {
  homeServices('Home Services'),
  foods('Foods');
  // stay('Stay');

  final String label;

  const ServiceCategory(this.label);
}

extension ServiceCategoryExtension on String {
  ServiceCategory? toServiceCategory() {
    return ServiceCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == this.toLowerCase(),
      // orElse: () => null,
    );
  }
}

/// Stores sub category
enum StoresCategory {
  clothing('Clothing'),
  footwear('Footwear'),
  giftShops('Gift Shops');

  final String label;

  const StoresCategory(this.label);
}

extension StoresCategoryExtension on String {
  StoresCategory? toStoresCategory() {
    return StoresCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == this.toLowerCase(),
      // orElse: () => null,
    );
  }
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
  all(label: 'All'),
  applied(label: 'Applied'),
  schedules(label: 'Schedules'),
  saved(label: 'Saved');

  final String label;

  const JobIndividualCategory({required this.label});
}

enum JobAppliedCategoryTab {
  all(label: 'All', labelId: AppConstants.All),
  applied(label: 'In Progress', labelId: AppConstants.IN_PROGRESS),
  schedules(label: 'Interview', labelId: AppConstants.INTERVIEW),
  saved(label: 'Closed', labelId: AppConstants.CLOSED);

  final String label;
  final String labelId;

  const JobAppliedCategoryTab({required this.label, required this.labelId});
}

enum JobBusinessCategory {
  myPosts(label: 'My Posts'),
  schedules(label: 'Schedules'),
  saved(label: 'Saved');

  final String label;

  const JobBusinessCategory({required this.label});
}

/// Job Status
enum JobStatus {
  appliedJob('Applied Job'),
  interviewInvites('Interview Invites');

  final String label;

  const JobStatus(this.label);
}

enum ApplicationJobCategory {
  all(label: 'All'),
  shortlisted(label: 'Shortlisted'),
  interview(label: 'Interview'),
  // connect(label: 'Connect'),
  hired(label: 'Hired');

  final String label;

  const ApplicationJobCategory({required this.label});
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

enum VideoCategoryType { Entertainment, Education, Other }

extension VideoCategoryTypeExtension on VideoCategoryType {
  /// Get display name for each enum
  String get displayName {
    switch (this) {
      case VideoCategoryType.Entertainment:
        return 'Entertainment';
      case VideoCategoryType.Education:
        return 'Education';
      case VideoCategoryType.Other:
        return 'Other';
    }
  }

  /// Parse enum from string (case-insensitive, trimmed)
  static VideoCategoryType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'entertainment':
        return VideoCategoryType.Entertainment;
      case 'education':
        return VideoCategoryType.Education;
      case 'other':
        return VideoCategoryType.Other;
      default:
        return VideoCategoryType.Other;

        throw ArgumentError('Invalid Video Category value: $value');
    }
  }
}

enum BlockedType {
  full('FULL'),
  partial('PARTIAL');

  final String label;

  const BlockedType(this.label);
}

enum Shorts { trending, nearBy, personalized, saved, latest, popular, oldest, underProgress, draft }

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
  oldest

  // ownChannelPosts,
  // visitingChannelPosts
}

enum PaymentMethod { upi, card }

enum PostSortBy {
  Latest('Latest', 'latest'),
  Popular('Popular', 'popular'),
  Oldest('Oldest', 'oldest');

  final String label;
  final String queryValue;

  const PostSortBy(this.label, this.queryValue);
}

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
  poll,
  photos,
  videos,
  jobPost,
  place,
  travel;
}

enum PostVia { profile, channel }
