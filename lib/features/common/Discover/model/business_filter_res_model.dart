import 'dart:convert';

import 'package:BlueEra/core/api/model/school_details_res_model.dart';

/// Response model for `GET user-service/business/filter`.
///
/// Backend returns a paged list of business records (any category — schools,
/// hotels, hospitals, etc.). The shape is documented from the live response:
///
/// ```
/// {
///   "success": true,
///   "data": [ { ...business... } ],
///   "pagination": { "total": 7, "page": 1, "limit": 2, "totalPages": 4 }
/// }
/// ```
///
/// Note: `business_number.office_mob_no` and `office_landline_no` are
/// polymorphic in the wire format — they come back as either an empty
/// string `""` or an object `{pre, number}`. Parsing is defensive so we
/// don't crash on either shape.
BusinessFilterResModel businessFilterResModelFromJson(String str) =>
    BusinessFilterResModel.fromJson(json.decode(str));

String businessFilterResModelToJson(BusinessFilterResModel data) =>
    json.encode(data.toJson());

class BusinessFilterResModel {
  BusinessFilterResModel({this.success, this.data, this.pagination});

  BusinessFilterResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) => data?.add(BusinessFilterData.fromJson(v)));
    }
    pagination = json['pagination'] != null
        ? BusinessFilterPagination.fromJson(json['pagination'])
        : null;
  }

  bool? success;
  List<BusinessFilterData>? data;
  BusinessFilterPagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }
}

class BusinessFilterPagination {
  BusinessFilterPagination(
      {this.total, this.page, this.limit, this.totalPages});

  BusinessFilterPagination.fromJson(dynamic json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'limit': limit,
        'totalPages': totalPages,
      };
}

class BusinessFilterData {
  BusinessFilterData({
    this.id,
    this.userId,
    this.cityStatePincode,
    this.pincode,
    this.gst,
    this.dietaryType,
    this.isActive,
    this.businessIsVerified,
    this.businessLocation,
    this.livePhotos,
    this.avgRating,
    this.totalRatings,
    this.ownerDetails,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.businessName,
    this.categoryOfBusiness,
    this.dateOfIncorporation,
    this.logo,
    this.subCategoryOfBusiness,
    this.typeOfBusiness,
    this.businessNumber,
    this.businessDescription,
    this.categoryDetails,
    this.subCategoryDetails,
    this.departments,
    this.departmentCount,
    this.facilities,
    this.facilityCount,
    this.quickInfo,
    this.schoolTimings,
    this.distanceKm,
  });

  BusinessFilterData.fromJson(dynamic json) {
    id = json['_id']?.toString();
    userId = json['user_id']?.toString();
    cityStatePincode = json['city_state_pincode']?.toString();
    pincode = _asInt(json['pincode']);
    gst = json['gst'] is Map ? BusinessGst.fromJson(json['gst']) : null;
    dietaryType = json['dietaryType']?.toString();
    isActive = json['isActive'] as bool?;
    businessIsVerified = json['business_isVerified'] as bool?;
    businessLocation = json['business_location'] is Map
        ? BusinessLocation.fromJson(json['business_location'])
        : null;
    if (json['live_photos'] is List) {
      livePhotos = (json['live_photos'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    avgRating = json['avg_rating'] is num ? json['avg_rating'] as num : null;
    totalRatings = _asInt(json['total_ratings']);
    if (json['owner_details'] is List) {
      ownerDetails = (json['owner_details'] as List)
          .whereType<Map>()
          .map((e) => OwnerDetail.fromJson(e))
          .toList();
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    address = json['address']?.toString();
    businessName = json['business_name']?.toString();
    categoryOfBusiness = json['category_Of_Business']?.toString();
    dateOfIncorporation = json['date_of_incorporation'] is Map
        ? DateOfIncorporation.fromJson(json['date_of_incorporation'])
        : null;
    logo = json['logo']?.toString();
    subCategoryOfBusiness = json['sub_category_Of_Business'] is Map
        ? BusinessNamedRef.fromJson(json['sub_category_Of_Business'])
        : null;
    typeOfBusiness = json['type_of_business']?.toString();
    businessNumber = json['business_number'] is Map
        ? BusinessNumber.fromJson(json['business_number'])
        : null;
    businessDescription = json['business_description']?.toString();
    categoryDetails = json['category_details'] is Map
        ? BusinessCategoryDetails.fromJson(json['category_details'])
        : null;
    subCategoryDetails = json['sub_category_details'] is Map
        ? BusinessNamedRef.fromJson(json['sub_category_details'])
        : null;
    if (json['departments'] is List) {
      departments = (json['departments'] as List)
          .whereType<Map>()
          .map((e) => BusinessFilterDepartment.fromJson(e))
          .toList();
    }
    departmentCount = _asInt(json['department_count']);
    // `facilities` is polymorphic — either null, a list of plain strings, or
    // a list of `{name, ...}` objects. Reduce every shape to a name list so
    // the UI can render chips uniformly.
    if (json['facilities'] is List) {
      facilities = (json['facilities'] as List)
          .map((e) => e is Map
              ? (e['name']?.toString() ?? '')
              : (e?.toString() ?? ''))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    facilityCount = _asInt(json['facility_count']);
    quickInfo = json['quickInfo'] is Map
        ? QuickInfo.fromJson(json['quickInfo'])
        : null;
    if (json['schoolTimings'] is List) {
      schoolTimings = (json['schoolTimings'] as List)
          .whereType<Map>()
          .map((e) => Availability.fromJson(e))
          .toList();
    }
    distanceKm = json['distance_km'] is num ? json['distance_km'] as num : null;
  }

  String? id;
  String? userId;
  String? cityStatePincode;
  int? pincode;
  BusinessGst? gst;
  String? dietaryType;
  bool? isActive;
  bool? businessIsVerified;
  BusinessLocation? businessLocation;
  List<String>? livePhotos;
  num? avgRating;
  int? totalRatings;
  List<OwnerDetail>? ownerDetails;
  String? createdAt;
  String? updatedAt;
  String? address;
  String? businessName;
  String? categoryOfBusiness;
  DateOfIncorporation? dateOfIncorporation;
  String? logo;
  BusinessNamedRef? subCategoryOfBusiness;
  String? typeOfBusiness;
  BusinessNumber? businessNumber;
  String? businessDescription;
  BusinessCategoryDetails? categoryDetails;
  BusinessNamedRef? subCategoryDetails;
  List<BusinessFilterDepartment>? departments;
  int? departmentCount;
  List<String>? facilities;
  int? facilityCount;
  QuickInfo? quickInfo;
  List<Availability>? schoolTimings;
  num? distanceKm;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'city_state_pincode': cityStatePincode,
        'pincode': pincode,
        'gst': gst?.toJson(),
        'dietaryType': dietaryType,
        'isActive': isActive,
        'business_isVerified': businessIsVerified,
        'business_location': businessLocation?.toJson(),
        'live_photos': livePhotos,
        'avg_rating': avgRating,
        'total_ratings': totalRatings,
        'owner_details': ownerDetails?.map((e) => e.toJson()).toList(),
        'created_at': createdAt,
        'updated_at': updatedAt,
        'address': address,
        'business_name': businessName,
        'category_Of_Business': categoryOfBusiness,
        'date_of_incorporation': dateOfIncorporation?.toJson(),
        'logo': logo,
        'sub_category_Of_Business': subCategoryOfBusiness?.toJson(),
        'type_of_business': typeOfBusiness,
        'business_number': businessNumber?.toJson(),
        'business_description': businessDescription,
        'category_details': categoryDetails?.toJson(),
        'sub_category_details': subCategoryDetails?.toJson(),
        'departments': departments?.map((e) => e.toJson()).toList(),
        'department_count': departmentCount,
        'facilities': facilities,
        'facility_count': facilityCount,
        'quickInfo': quickInfo?.toJson(),
        'schoolTimings':
            schoolTimings?.map((e) => e.toJson()).toList(),
        'distance_km': distanceKm,
      };
}

class QuickInfo {
  QuickInfo({
    this.classRange,
    this.studentTeacherRatio,
    this.mediumOfInstruction,
    this.fees,
  });

  QuickInfo.fromJson(dynamic json) {
    classRange = json['classRange']?.toString();
    studentTeacherRatio = json['studentTeacherRatio']?.toString();
    final medium = json['mediumOfInstruction'];
    if (medium is List) {
      mediumOfInstruction = medium.map((e) => e.toString()).toList();
    } else if (medium is String && medium.isNotEmpty) {
      mediumOfInstruction = [medium];
    }
    final feesVal = json['fees'];
    fees = feesVal is num ? feesVal.toInt() : null;
  }

  String? classRange;
  String? studentTeacherRatio;
  List<String>? mediumOfInstruction;
  int? fees;

  Map<String, dynamic> toJson() => {
        'classRange': classRange,
        'studentTeacherRatio': studentTeacherRatio,
        'mediumOfInstruction': mediumOfInstruction,
        'fees': fees,
      };
}

/// Lightweight department descriptor from `business/filter`. Only the fields
/// the listing card needs (name/type/key) are kept — full OPD/IPD detail is
/// fetched separately when a hospital is opened.
class BusinessFilterDepartment {
  BusinessFilterDepartment({this.id, this.name, this.key, this.type});

  BusinessFilterDepartment.fromJson(dynamic json) {
    id = json['_id']?.toString();
    name = json['name']?.toString();
    key = json['key']?.toString();
    type = json['type']?.toString();
  }

  String? id;
  String? name;
  String? key;
  String? type;

  Map<String, dynamic> toJson() =>
      {'_id': id, 'name': name, 'key': key, 'type': type};
}

class BusinessGst {
  BusinessGst({this.have, this.gstVerification});

  BusinessGst.fromJson(dynamic json) {
    have = json['have'] as bool?;
    gstVerification = json['gst_verification'] as bool?;
  }

  bool? have;
  bool? gstVerification;

  Map<String, dynamic> toJson() =>
      {'have': have, 'gst_verification': gstVerification};
}

class BusinessLocation {
  BusinessLocation({this.lat, this.lon});

  BusinessLocation.fromJson(dynamic json) {
    lat = json['lat'] is num ? json['lat'] as num : null;
    lon = json['lon'] is num ? json['lon'] as num : null;
  }

  num? lat;
  num? lon;

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};
}

class OwnerDetail {
  OwnerDetail({this.name, this.roleInBusiness, this.email, this.id});

  OwnerDetail.fromJson(dynamic json) {
    name = json['name']?.toString();
    roleInBusiness = json['role_in_business']?.toString();
    email = json['email']?.toString();
    id = json['_id']?.toString();
  }

  String? name;
  String? roleInBusiness;
  String? email;
  String? id;

  Map<String, dynamic> toJson() => {
        'name': name,
        'role_in_business': roleInBusiness,
        'email': email,
        '_id': id,
      };
}

class DateOfIncorporation {
  DateOfIncorporation({this.date, this.month, this.year});

  DateOfIncorporation.fromJson(dynamic json) {
    date = _asInt(json['date']);
    month = _asInt(json['month']);
    year = _asInt(json['year']);
  }

  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() =>
      {'date': date, 'month': month, 'year': year};
}

class BusinessNamedRef {
  BusinessNamedRef({this.id, this.name, this.tagId});

  BusinessNamedRef.fromJson(dynamic json) {
    id = json['_id']?.toString();
    name = json['name']?.toString();
    tagId = json['tag_id']?.toString();
  }

  String? id;
  String? name;
  String? tagId;

  Map<String, dynamic> toJson() => {'_id': id, 'name': name, 'tag_id': tagId};
}

class BusinessCategoryDetails {
  BusinessCategoryDetails({this.id, this.name, this.tagId});

  BusinessCategoryDetails.fromJson(dynamic json) {
    id = json['_id']?.toString();
    name = json['name']?.toString();
    tagId = json['tag_id']?.toString();
  }

  String? id;
  String? name;
  String? tagId;

  Map<String, dynamic> toJson() =>
      {'_id': id, 'name': name, 'tag_id': tagId};
}

/// Phone wrapper. The wire format for each subfield is polymorphic:
/// either `""` (empty string) or `{pre, number}`.
class BusinessNumber {
  BusinessNumber({this.officeMobNo, this.officeLandlineNo});

  BusinessNumber.fromJson(dynamic json) {
    officeMobNo = _parsePhone(json['office_mob_no']);
    officeLandlineNo = _parsePhone(json['office_landline_no']);
  }

  BusinessPhone? officeMobNo;
  BusinessPhone? officeLandlineNo;

  Map<String, dynamic> toJson() => {
        'office_mob_no': officeMobNo?.toJson(),
        'office_landline_no': officeLandlineNo?.toJson(),
      };

  static BusinessPhone? _parsePhone(dynamic v) {
    if (v is Map) return BusinessPhone.fromJson(v);
    return null;
  }
}

class BusinessPhone {
  BusinessPhone({this.pre, this.number});

  BusinessPhone.fromJson(dynamic json) {
    pre = _asInt(json['pre']);
    number = json['number'] is num
        ? (json['number'] as num).toString()
        : json['number']?.toString();
  }

  int? pre;
  String? number;

  Map<String, dynamic> toJson() => {'pre': pre, 'number': number};
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// Adapts a `business/filter` record into the legacy [SchoolDetailsData]
/// shape consumed by the education listing UI. Lives here (not in the
/// controller) so that `Location` resolves unambiguously to the school
/// model's `Location` — the controller imports six libraries that each
/// export a `Location` class.
///
/// Only fields the UI actually reads (logo, name, type, gallery, banner,
/// address, since-year) are mapped; everything else stays null and the
/// existing UI null-checks handle it.
extension BusinessFilterDataMappers on BusinessFilterData {
  SchoolDetailsData toSchoolDetail() {
    final lat = businessLocation?.lat;
    final lon = businessLocation?.lon;
    // GeoJSON convention: [lng, lat]. Empty list when coords unavailable.
    final coords = (lat != null && lon != null) ? <num>[lon, lat] : <num>[];

    final firstNonEmpty = <String?>[
      subCategoryDetails?.name,
      categoryDetails?.name,
      typeOfBusiness,
    ].firstWhere(
      (s) => s != null && s.isNotEmpty,
      orElse: () => null,
    );

    return SchoolDetailsData(
      id: id,
      name: businessName,
      type: firstNonEmpty,
      description: businessDescription,
      establishmentYear: dateOfIncorporation?.year,
      logo: logo,
      // First live photo doubles as a banner when no dedicated banner exists.
      bannerUrl: (livePhotos != null && livePhotos!.isNotEmpty)
          ? livePhotos!.first
          : null,
      galleryPhotos: livePhotos,
      ownerId: userId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      location: Location(
        name: address,
        type: 'Point',
        coordinates: coords,
      ),
      classRange: quickInfo?.classRange,
      studentTeacherRatio: quickInfo?.studentTeacherRatio,
      mediumOfInstruction: quickInfo?.mediumOfInstruction,
      fees: quickInfo?.fees,
      availability: schoolTimings,
      avgRating: avgRating?.toDouble(),
    );
  }
}
