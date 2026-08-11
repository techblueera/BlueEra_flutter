class RiderOnboardingStatusResponse {
  RiderOnboardingStatusData? data;

  RiderOnboardingStatusResponse({this.data});

  RiderOnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new RiderOnboardingStatusData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class RiderOnboardingStatusData {
  RiderOnboardingStatusData({
    this.personalInformation,
    this.address,
    this.personalIdentification,
    this.drivingVerification,
    this.vehicleImages,
    this.vehicleInformation,
    this.isOnboardingComplete,
    this.verificationStatus,
    this.aadhar,
    this.pan,
    this.rc,
    this.dl,
    this.aadharNo,
    this.panNo,
    this.rcNo,
    this.vehicleNo,
    this.vehicleName,
    this.vehicleModelYear,
    this.vehicleType,
    this.vehicleUsesType,
    this.dlNo,
    this.aadharImage,
    this.aadharImageBack,
    this.panImage,
    this.dlImage,
    this.dlImageBack,
    this.rcImage,
    this.rcImageBack,
    this.vehicleImageUrls = const [],
    this.securityDepositPaid,
    this.securityDepositPaymentStatus,
  });

  RiderOnboardingStatusData.fromJson(dynamic json) {
    personalInformation = json['personalInformation'];
    address = json['address'];
    personalIdentification = json['personalIdentification'];
    drivingVerification = json['drivingVerification'];
    vehicleImages = json['vehicleImages'];
    vehicleInformation = json['vehicleInformation'];
    isOnboardingComplete = json['isOnboardingComplete'];
    verificationStatus = json['verificationStatus'];
    // Two different things can mean "we know who this rider is":
    //   `aadhar`         — the onboarding STEP flag, set by the
    //                      personal-identification PUT.
    //   `aadharVerified` — the user-level OKYC result, carried on this same
    //                      response.
    // They can disagree. Someone who verified through `/user/aadhaar/*`
    // without that PUT — a Gig Work signup, say — has the second and not the
    // first, and only `aadhar` was ever read here, so the rider flow asked
    // them for the same Aadhaar again. Either flag now satisfies the step.
    //
    // Null is preserved when BOTH keys are absent, so a response shape that
    // omits them still reads as "unknown" rather than a hard false.
    final aadhaarStepFlag = json['aadhar'];
    aadhar = (aadhaarStepFlag == true || json['aadharVerified'] == true)
        ? true
        : (aadhaarStepFlag as bool?);
    pan = json['pan'];
    rc = json['rc'];
    dl = json['dl'];
    aadharNo = json['aadharNo'];
    panNo = json['panNo'];
    rcNo = json['rcNo'];
    dlNo = json['dlNo'];
    final vehicleData = json['vehicleInformationData'];
    vehicleNo = (vehicleData is Map ? vehicleData['registrationNo'] : null) ?? '';
    vehicleName = vehicleData is Map ? vehicleData['vehicleName'] as String? : null;
    vehicleModelYear =
        vehicleData is Map ? vehicleData['vehicleModelYear']?.toString() : null;
    vehicleType = vehicleData is Map ? vehicleData['vehicleType'] as String? : null;
    // The rider's service preference — the field the nearby-rider filter
    // keys off (see docs/backend/RIDER_PREFERENCE_FILTER.md). Surfaced so the
    // Set Preference card can pre-select the rider's saved choice.
    vehicleUsesType =
        vehicleData is Map ? vehicleData['vehicleUsesType'] as String? : null;
    // Document image URLs — the rider screen renders a thumbnail +
    // pinch-zoom view dialog when these are present. The keys here
    // accept any of: a flat top-level field (e.g. `aadharImage`), the
    // nested `{front, back}` shape the upload payload uses, or the
    // `documents.<doc>.files.{front, back}` shape the onboarding status
    // API now returns. The front image is preferred when both sides are
    // available.
    aadharImage = (json['aadharImageFront'] as String?) ??
        (json['aadharImages'] is Map
            ? (json['aadharImages']['front'] as String?)
            : null) ??
        _documentFile(json, 'aadhar', 'front') ??
        (json['aadharImage'] as String?);
    aadharImageBack = (json['aadharImageBack'] as String?) ??
        (json['aadharImages'] is Map
            ? (json['aadharImages']['back'] as String?)
            : null) ??
        _documentFile(json, 'aadhar', 'back');
    panImage = (json['panImageFront'] as String?) ??
        (json['panImages'] is Map
            ? (json['panImages']['front'] as String?)
            : null) ??
        _documentFile(json, 'pan', 'front') ??
        (json['panImage'] as String?);
    dlImage = (json['dlImageFront'] as String?) ??
        (json['dlImages'] is Map
            ? (json['dlImages']['front'] as String?)
            : null) ??
        _documentFile(json, 'dl', 'front') ??
        (json['dlImage'] as String?);
    dlImageBack = (json['dlImageBack'] as String?) ??
        (json['dlImages'] is Map
            ? (json['dlImages']['back'] as String?)
            : null) ??
        _documentFile(json, 'dl', 'back');
    rcImage = (json['rcImageFront'] as String?) ??
        (json['rcImages'] is Map
            ? (json['rcImages']['front'] as String?)
            : null) ??
        _documentFile(json, 'rc', 'front') ??
        (json['rcImage'] as String?);
    rcImageBack = (json['rcImageBack'] as String?) ??
        (json['rcImages'] is Map
            ? (json['rcImages']['back'] as String?)
            : null) ??
        _documentFile(json, 'rc', 'back');
    vehicleImageUrls = _parseVehicleImages(json);
    // Security deposit — the rider must have paid this before they can go
    // online. The API returns a nested `securityDeposit` object; we surface
    // just the `paid` flag and its `paymentStatus` string.
    final deposit = json['securityDeposit'];
    if (deposit is Map) {
      securityDepositPaid = deposit['paid'] as bool?;
      securityDepositPaymentStatus = deposit['paymentStatus'] as String?;
    }
    // `freeRideUsed` was parsed here for the first-ride-free waiver. That
    // concept is gone — the deposit is the only gate — so the field is ignored
    // even if the backend keeps sending it.
  }

  // Pulls a single side ('front'/'back') out of the nested
  // `documents.<docKey>.files` object the onboarding status API
  // returns. Returns null (rather than an empty string) when the path
  // is missing or the value is blank, so the `??` fallback chains above
  // skip empty backend values cleanly.
  static String? _documentFile(dynamic json, String docKey, String side) {
    final documents = json['documents'];
    if (documents is! Map) return null;
    final doc = documents[docKey];
    if (doc is! Map) return null;
    final files = doc['files'];
    if (files is! Map) return null;
    final url = files[side];
    return (url is String && url.isNotEmpty) ? url : null;
  }

  // Collects the uploaded vehicle photos for the view gallery.
  //
  // NOTE: the onboarding status API does not yet return vehicle image
  // URLs (only a `vehicleImages: true/false` flag). This parser looks in
  // two plausible places so the gallery lights up automatically once the
  // backend starts returning them — confirm the exact shape with backend:
  //   1. `vehicleImagesData`: a flat map keyed by the same field names
  //      the upload payload uses (vehicleNoPlateImg, vehicleFrontImage…).
  //   2. `documents.vehicleImages.files`: the same nested `documents`
  //      envelope the ID documents use.
  static List<RiderVehicleImage> _parseVehicleImages(dynamic json) {
    final result = <RiderVehicleImage>[];
    Map? source;
    if (json['vehicleImagesData'] is Map) {
      source = json['vehicleImagesData'] as Map;
    } else if (json['documents'] is Map &&
        json['documents']['vehicleImages'] is Map &&
        json['documents']['vehicleImages']['files'] is Map) {
      source = json['documents']['vehicleImages']['files'] as Map;
    }
    if (source == null) return result;
    // Ordered slot → candidate JSON keys. The slot key drives the
    // caption in the view (mapped to a localized label there).
    const slots = <String, List<String>>{
      'numberPlate': ['vehicleNoPlateImg', 'numberPlate'],
      'front': ['vehicleFrontImage', 'front'],
      'back': ['vehicleBackImage', 'back'],
      'side': ['vehicleRightHandSideImage', 'rightSide', 'side'],
    };
    slots.forEach((slot, keys) {
      for (final key in keys) {
        final url = _firstUrl(source![key]);
        if (url != null) {
          result.add(RiderVehicleImage(slot: slot, url: url));
          break;
        }
      }
    });
    return result;
  }

  // A vehicle image field may be a single URL string or a list of URLs
  // (e.g. right-side images are uploaded as a list); take the first
  // non-empty entry.
  static String? _firstUrl(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is List) {
      for (final v in value) {
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  bool? personalInformation;
  bool? address;
  bool? personalIdentification;
  bool? drivingVerification;
  bool? vehicleImages;
  bool? vehicleInformation;
  bool? isOnboardingComplete;
  String? verificationStatus;
  bool? aadhar;
  bool? pan;
  bool? rc;
  bool? dl;
  String? aadharNo;
  String? panNo;
  String? rcNo;
  String? dlNo;
  String? vehicleNo;
  // Vehicle Information text fields, surfaced in the vehicle-info view
  // dialog (pulled from `vehicleInformationData`).
  String? vehicleName;
  String? vehicleModelYear;
  String? vehicleType;
  // Rider service preference (passenger | delivery | passenger&delivery |
  // goodsTransport) — drives the nearby-rider filter.
  String? vehicleUsesType;
  // Front-side image URLs for the ID documents that have an image
  // preview slot, plus back-side URLs for the two-sided ones (Aadhar,
  // DL, RC). PAN is single-sided so it only has a front.
  String? aadharImage;
  String? aadharImageBack;
  String? panImage;
  String? dlImage;
  String? dlImageBack;
  String? rcImage;
  String? rcImageBack;
  // Uploaded vehicle photos for the view gallery (see [_parseVehicleImages]).
  List<RiderVehicleImage> vehicleImageUrls = const [];
  // Security-deposit payment state. `securityDepositPaid` gates going online;
  // `securityDepositPaymentStatus` carries the raw backend status (e.g.
  // "unknown", "paid", "pending").
  bool? securityDepositPaid;
  String? securityDepositPaymentStatus;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['personalInformation'] = personalInformation;
    map['address'] = address;
    map['personalIdentification'] = personalIdentification;
    map['drivingVerification'] = drivingVerification;
    map['vehicleImages'] = vehicleImages;
    map['vehicleInformation'] = vehicleInformation;
    map['isOnboardingComplete'] = isOnboardingComplete;
    map['verificationStatus'] = verificationStatus;
    map['aadhar'] = aadhar;
    map['pan'] = pan;
    map['rc'] = rc;
    map['dl'] = dl;
    map['aadharNo'] = aadharNo;
    map['panNo'] = panNo;
    map['rcNo'] = rcNo;
    map['dlNo'] = dlNo;
    map['vehicleName'] = vehicleName;
    map['vehicleModelYear'] = vehicleModelYear;
    map['vehicleType'] = vehicleType;
    map['vehicleUsesType'] = vehicleUsesType;
    map['aadharImage'] = aadharImage;
    map['aadharImageBack'] = aadharImageBack;
    map['panImage'] = panImage;
    map['dlImage'] = dlImage;
    map['dlImageBack'] = dlImageBack;
    map['rcImage'] = rcImage;
    map['rcImageBack'] = rcImageBack;
    map['vehicleImageUrls'] =
        vehicleImageUrls.map((e) => e.toJson()).toList();
    // Round-trip the deposit fields under the same nested shape the API uses
    // so the cached copy re-parses identically.
    map['securityDeposit'] = {
      'paid': securityDepositPaid,
      'paymentStatus': securityDepositPaymentStatus,
    };
    return map;
  }

}

/// A single uploaded vehicle photo and which slot it belongs to.
/// [slot] is one of 'numberPlate' | 'front' | 'back' | 'side' and is
/// mapped to a localized caption by the view layer.
class RiderVehicleImage {
  final String slot;
  final String url;

  RiderVehicleImage({required this.slot, required this.url});

  Map<String, dynamic> toJson() => {'slot': slot, 'url': url};
}
