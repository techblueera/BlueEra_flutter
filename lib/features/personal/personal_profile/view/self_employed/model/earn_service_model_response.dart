// Schedule + FeeDetails are shared with the booking-availability model
// — the backend uses identical JSON shapes for them on both endpoints,
// so reusing the parsers keeps round-trip behaviour consistent and
// avoids drift between the two screens that consume them.
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';

class EarnServiceModelResponse {
  String? sId;
  ServiceProvider? serviceProvider;
  String? type;
  String? subType;
  bool? earnService;
  String? category;
  String? title;
  String? description;
  List<String>? photos;
  List<String>? expertise;
  String? experienceStartDate;
  List<String>? serviceOffered;
  List<String>? typesOfWork;
  List<String>? workCategories;
  List<String>? whyChooseMe;
  List<String>? serviceType;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;
  ProviderDetails? providerDetails;

  /// Min/max/feeType triple persisted alongside the service. Drives the
  /// price hero on the section card and seeds the price-update sheet.
  FeeDetails? feeDetails;

  /// Weekly working-hours schedule persisted alongside the service.
  /// Drives the schedule card on the section card and seeds the
  /// working-hours editor on the update sheet.
  List<Schedule>? schedule;

  EarnServiceModelResponse(
      {this.sId,
        this.serviceProvider,
        this.type,
        this.subType,
        this.earnService,
        this.category,
        this.title,
        this.description,
        this.photos,
        this.expertise,
        this.experienceStartDate,
        this.serviceOffered,
        this.typesOfWork,
        this.workCategories,
        this.whyChooseMe,
        this.serviceType,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.providerDetails,
        this.feeDetails,
        this.schedule});

  EarnServiceModelResponse.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceProvider = json['serviceProvider'] != null
        ? new ServiceProvider.fromJson(json['serviceProvider'])
        : null;
    type = json['type'];
    subType = json['subType'];
    earnService = json['earnService'];
    category = json['category'];
    title = json['title'];
    description = json['description'];
    photos = json['photos']?.cast<String>();
    expertise = json['expertise']?.cast<String>();
    experienceStartDate = json['experienceStartDate'];
    // Backend ships the up-to-date list under the plural `servicesOffered`
    // key (the singular `serviceOffered` is a legacy/stale field still
    // present in some responses). Prefer the plural; fall back so older
    // payloads keep working.
    serviceOffered = (json['servicesOffered'] ?? json['serviceOffered'])
        ?.cast<String>();
    typesOfWork = json['typesOfWork']?.cast<String>();
    workCategories = json['workCategories']?.cast<String>();
    whyChooseMe = json['whyChooseMe']?.cast<String>();
    serviceType = json['serviceType']?.cast<String>();
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    providerDetails = json['providerDetails'] != null
        ? new ProviderDetails.fromJson(json['providerDetails'])
        : null;
    // The backend migrated the price payload from a nested `feeDetails`
    // object to a top-level `priceRange:{min,max}` + sibling `feeType`.
    // We keep `FeeDetails` as the in-memory aggregate so every UI
    // consumer (`_priceHero`, `seedPriceInputsFromProfession`, etc.)
    // keeps reading the same fields — only the parsing changes here.
    // Prefer the new shape; fall back to legacy `feeDetails` for any
    // older payloads still in flight.
    if (json['priceRange'] != null || json['feeType'] != null) {
      final priceRange = json['priceRange'] as Map<String, dynamic>?;
      feeDetails = FeeDetails(
        minFee: (priceRange?['min'] as num?)?.toInt(),
        maxFee: (priceRange?['max'] as num?)?.toInt(),
        feeType: json['feeType'] as String?,
      );
    } else if (json['feeDetails'] != null) {
      feeDetails = FeeDetails.fromJson(json['feeDetails']);
    } else {
      feeDetails = null;
    }
    // Backend nests the weekly schedule under an `availability` object
    // (alongside bookingType / timezone / durationInMinutes) — kept
    // outside the model on purpose because nothing else on the
    // self-employed screen needs them yet. Fall back to a top-level
    // `schedule` for older payloads still in flight.
    final availability = json['availability'] as Map<String, dynamic>?;
    final rawSchedule = availability?['schedule'] ?? json['schedule'];
    if (rawSchedule is List) {
      schedule = <Schedule>[];
      for (final v in rawSchedule) {
        schedule!.add(Schedule.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    if (this.serviceProvider != null) {
      data['serviceProvider'] = this.serviceProvider!.toJson();
    }
    data['type'] = this.type;
    data['subType'] = this.subType;
    data['earnService'] = this.earnService;
    data['category'] = this.category;
    data['title'] = this.title;
    data['description'] = this.description;
    data['photos'] = this.photos;
    data['expertise'] = this.expertise;
    data['experienceStartDate'] = this.experienceStartDate;
    // Write the plural key so toJson round-trips back into a payload
    // the update endpoint understands.
    data['servicesOffered'] = this.serviceOffered;
    data['typesOfWork'] = this.typesOfWork;
    data['workCategories'] = this.workCategories;
    data['whyChooseMe'] = this.whyChooseMe;
    data['serviceType'] = this.serviceType;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.providerDetails != null) {
      data['providerDetails'] = this.providerDetails!.toJson();
    }
    if (this.feeDetails != null) {
      data['feeDetails'] = this.feeDetails!.toJson();
    }
    if (this.schedule != null) {
      data['schedule'] = this.schedule!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceProvider {
  String? id;
  String? type;

  ServiceProvider({this.id, this.type});

  ServiceProvider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    return data;
  }
}

class ProviderDetails {
  String? id;
  String? name;
  String? gender;
  String? pre;
  String? contactNo;
  String? profession;
  String? designation;
  String? profileImage;
  bool? isEnded;
  String? username;
  DateOfBirth? dateOfBirth;
  String? deletedAt;
  String? accountType;
  String? language;
  int? referralPoints;
  String? referralCode;
  String? referredBy;
  String? deviceToken;
  String? lastSeen;
  String? location;
  String? email;
  String? highestEducation;
  String? role;
  String? password;
  String? currentOrganisation;
  String? bio;
  String? address;
  String? introVideo;
  SocialLinks? socialLinks;
  String? createdAt;
  String? updatedAt;
  String? specialization;
  String? department;
  String? subDivision;
  Null art;
  String? schoolOrCollegeName;
  String? sector;
  String? qrUrl;
  UserLocation? userLocation;
  bool? emailVerified;
  String? objective;

  ProviderDetails(
      {this.id,
        this.name,
        this.gender,
        this.pre,
        this.contactNo,
        this.profession,
        this.designation,
        this.profileImage,
        this.isEnded,
        this.username,
        this.dateOfBirth,
        this.deletedAt,
        this.accountType,
        this.language,
        this.referralPoints,
        this.referralCode,
        this.referredBy,
        this.deviceToken,
        this.lastSeen,
        this.location,
        this.email,
        this.highestEducation,
        this.role,
        this.password,
        this.currentOrganisation,
        this.bio,
        this.address,
        this.introVideo,
        this.socialLinks,
        this.createdAt,
        this.updatedAt,
        this.specialization,
        this.department,
        this.subDivision,
        this.art,
        this.schoolOrCollegeName,
        this.sector,
        this.qrUrl,
        this.userLocation,
        this.emailVerified,
        this.objective});

  ProviderDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    gender = json['gender'];
    pre = json['pre'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    profileImage = json['profile_image'];
    isEnded = json['is_ended'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null
        ? new DateOfBirth.fromJson(json['date_of_birth'])
        : null;
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    language = json['language'];
    referralPoints = json['referral_points'];
    referralCode = json['referral_code'];
    referredBy = json['referred_by'];
    deviceToken = json['device_token'];
    lastSeen = json['last_seen'];
    location = json['location'];
    email = json['email'];
    highestEducation = json['highest_education'];
    role = json['role'];
    password = json['password'];
    currentOrganisation = json['current_organisation'];
    bio = json['bio'];
    address = json['address'];
    introVideo = json['introVideo'];
    socialLinks = json['social_links'] != null
        ? new SocialLinks.fromJson(json['social_links'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    specialization = json['specialization'];
    department = json['department'];
    subDivision = json['sub_division'];
    art = json['art'];
    schoolOrCollegeName = json['school_or_college_name'];
    sector = json['sector'];
    qrUrl = json['qr_url'];
    userLocation = json['user_location'] != null
        ? new UserLocation.fromJson(json['user_location'])
        : null;
    emailVerified = json['email_verified'];
    objective = json['objective'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['gender'] = this.gender;
    data['pre'] = this.pre;
    data['contact_no'] = this.contactNo;
    data['profession'] = this.profession;
    data['designation'] = this.designation;
    data['profile_image'] = this.profileImage;
    data['is_ended'] = this.isEnded;
    data['username'] = this.username;
    if (this.dateOfBirth != null) {
      data['date_of_birth'] = this.dateOfBirth!.toJson();
    }
    data['deleted_at'] = this.deletedAt;
    data['account_type'] = this.accountType;
    data['language'] = this.language;
    data['referral_points'] = this.referralPoints;
    data['referral_code'] = this.referralCode;
    data['referred_by'] = this.referredBy;
    data['device_token'] = this.deviceToken;
    data['last_seen'] = this.lastSeen;
    data['location'] = this.location;
    data['email'] = this.email;
    data['highest_education'] = this.highestEducation;
    data['role'] = this.role;
    data['password'] = this.password;
    data['current_organisation'] = this.currentOrganisation;
    data['bio'] = this.bio;
    data['address'] = this.address;
    data['introVideo'] = this.introVideo;
    if (this.socialLinks != null) {
      data['social_links'] = this.socialLinks!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['specialization'] = this.specialization;
    data['department'] = this.department;
    data['sub_division'] = this.subDivision;
    data['art'] = this.art;
    data['school_or_college_name'] = this.schoolOrCollegeName;
    data['sector'] = this.sector;
    data['qr_url'] = this.qrUrl;
    if (this.userLocation != null) {
      data['user_location'] = this.userLocation!.toJson();
    }
    data['email_verified'] = this.emailVerified;
    data['objective'] = this.objective;
    return data;
  }
}

class DateOfBirth {
  int? date;
  int? month;
  int? year;

  DateOfBirth({this.date, this.month, this.year});

  DateOfBirth.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['month'] = this.month;
    data['year'] = this.year;
    return data;
  }
}

class SocialLinks {
  String? youtube;
  String? twitter;
  String? linkedin;
  String? instagram;
  String? website;

  SocialLinks(
      {this.youtube,
        this.twitter,
        this.linkedin,
        this.instagram,
        this.website});

  SocialLinks.fromJson(Map<String, dynamic> json) {
    youtube = json['youtube'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    instagram = json['instagram'];
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['youtube'] = this.youtube;
    data['twitter'] = this.twitter;
    data['linkedin'] = this.linkedin;
    data['instagram'] = this.instagram;
    data['website'] = this.website;
    return data;
  }
}

/// Security-deposit go-live status for a selfWork service. Mirrors the backend
/// `securityDeposit` object 1:1 (see
/// docs/backend/SELF_WORK_GO_LIVE_FRONTEND_INTEGRATION.md).
///
/// Fail-open by construction: [paid] defaults to `true`, so a missing/partial
/// object never traps a provider offline.
class SecurityDepositStatus {
  /// `false` → this profession owes no deposit; never gate.
  final bool required;

  /// The gate. `true` → allow go-live; `false` → block + show the deposit CTA.
  final bool paid;

  /// Raw UserSecurityDeposit.status (created / held / refund_requested / …).
  final String? paymentStatus;

  /// The user's deposit id (deep-link into the deposit/refund screen).
  final String? depositId;

  /// ISO date the deposit becomes refundable once `held`.
  final DateTime? refundEligibleAt;

  SecurityDepositStatus({
    this.required = false,
    this.paid = true,
    this.paymentStatus,
    this.depositId,
    this.refundEligibleAt,
  });

  factory SecurityDepositStatus.fromJson(Map<String, dynamic> j) {
    return SecurityDepositStatus(
      required: j['required'] ?? false,
      paid: j['paid'] ?? true, // default true = fail-open
      paymentStatus: j['paymentStatus'] as String?,
      depositId: j['depositId'] as String?,
      refundEligibleAt: j['refundEligibleAt'] != null
          ? DateTime.tryParse(j['refundEligibleAt'].toString())
          : null,
    );
  }

  /// Block go-live ONLY when the deposit is required and unpaid.
  bool get canGoLive => !required || paid;
}

class UserLocation {
  double? lat;
  double? lon;

  UserLocation({this.lat, this.lon});

  UserLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    return data;
  }
}