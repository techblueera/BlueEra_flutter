import 'dart:convert';

import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';

SchoolDetailsResModel schoolDetailsResModelFromJson(String str) =>
    SchoolDetailsResModel.fromJson(json.decode(str));
String schoolDetailsResModelToJson(SchoolDetailsResModel data) =>
    json.encode(data.toJson());

class SchoolDetailsResModel {
  SchoolDetailsResModel({
    this.success,
    this.data,
  });

  SchoolDetailsResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      if (json['data'] is List) {
        data = (json['data'] as List).isNotEmpty
            ? SchoolDetailsData.fromJson(json['data'][0])
            : null;
      } else {
        data = SchoolDetailsData.fromJson(json['data']);
      }
    }
  }
  bool? success;
  SchoolDetailsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

SchoolDetailsData dataFromJson(String str) =>
    SchoolDetailsData.fromJson(json.decode(str));
String dataToJson(SchoolDetailsData data) => json.encode(data.toJson());

class SchoolDetailsData {
  SchoolDetailsData({
    this.id,
    this.name,
    this.type,
    this.description,
    this.establishmentYear,
    this.logo,
    this.bannerUrl,
    this.career,
    this.contacts,
    this.ownerId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.aboutId,
    this.courses,
    this.campusLife,
    this.location,
    this.galleryPhotos,
    this.availability,
    this.classRange,
    this.studentTeacherRatio,
    this.boards,
    this.mediumOfInstruction,
    this.fees,
    this.numberOfStudents,
    this.avgRating,
  });

  SchoolDetailsData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
    description = json['description'];
    establishmentYear = json['establishmentYear'];
    logo = json['logo'];
    bannerUrl = json['bannerUrl'];
    career = json['career'];
    if (json['contacts'] != null) {
      contacts = [];
      json['contacts'].forEach((v) {
        contacts?.add(Contacts.fromJson(v));
      });
    }

    ownerId = json['ownerId'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    aboutId =
        json['aboutId'] != null ? AboutId.fromJson(json['aboutId']) : null;
    if (json['courses'] != null) {
      courses = [];
      json['courses'].forEach((v) {
        courses?.add(Courses.fromJson(v));
      });
    }
    if (json['campusLife'] != null) {
      campusLife = [];
      json['campusLife'].forEach((v) {
        campusLife?.add(CampusLife.fromJson(v));
      });
    }
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    if (json['gallery'] != null) {
      galleryPhotos = <String>[];
      json['gallery'].forEach((v) {
        final url = v['uploadPhoto']?.toString().trim() ?? '';
        if (url.isNotEmpty) galleryPhotos!.add(url);
      });
    }
    // Accept both legacy `availability` and new `schoolTimings` keys
    final timings = json['schoolTimings'] ?? json['availability'];
    if (timings is List) {
      availability = timings.map((v) => Availability.fromJson(v)).toList();
    }

    // Quick info can live at top-level (legacy) or nested under `quickInfo`
    final quickInfo = json['quickInfo'];
    final cr = quickInfo is Map ? quickInfo['classRange'] : json['classRange'];
    final str = quickInfo is Map
        ? quickInfo['studentTeacherRatio']
        : json['studentTeacherRatio'];
    final boardVal = quickInfo is Map ? quickInfo['board'] : json['board'];
    final medium = quickInfo is Map
        ? quickInfo['mediumOfInstruction']
        : json['mediumOfInstruction'];
    final feesVal = quickInfo is Map ? quickInfo['fees'] : json['fees'];
    final studentsVal = quickInfo is Map
        ? quickInfo['numberOfStudents']
        : json['numberOfStudents'];

    classRange = cr?.toString();
    studentTeacherRatio = str?.toString();
    if (boardVal is List) {
      boards = boardVal.map((e) => e.toString()).toList();
    } else if (boardVal is String && boardVal.isNotEmpty) {
      boards = [boardVal];
    }
    if (medium is List) {
      mediumOfInstruction = medium.map((e) => e.toString()).toList();
    } else if (medium is String && medium.isNotEmpty) {
      mediumOfInstruction = [medium];
    }
    fees = feesVal is num ? feesVal.toInt() : null;
    numberOfStudents = studentsVal is num ? studentsVal.toInt() : null;

    final ratingVal = json['avg_rating'] ?? json['avgRating'];
    avgRating = ratingVal is num ? ratingVal.toDouble() : null;
  }
  String? id;
  String? name;
  String? type;
  String? description;
  int? establishmentYear;
  String? logo;
  String? bannerUrl;
  String? career;
  List<Contacts>? contacts;
  String? ownerId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;
  AboutId? aboutId;
  List<Courses>? courses;
  List<CampusLife>? campusLife;
  Location? location;
  List<String>? galleryPhotos;
  List<Availability>? availability;
  String? classRange;
  String? studentTeacherRatio;
  List<String>? boards;
  List<String>? mediumOfInstruction;
  int? fees;
  int? numberOfStudents;
  double? avgRating;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    map['description'] = description;
    map['establishmentYear'] = establishmentYear;
    map['logo'] = logo;
    map['bannerUrl'] = bannerUrl;
    map['career'] = career;
    if (contacts != null) {
      map['contacts'] = contacts?.map((v) => v.toJson()).toList();
    }

    map['ownerId'] = ownerId;
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (aboutId != null) {
      map['aboutId'] = aboutId?.toJson();
    }

    if (courses != null) {
      map['courses'] = courses?.map((v) => v.toJson()).toList();
    }
    if (campusLife != null) {
      map['campusLife'] = campusLife?.map((v) => v.toJson()).toList();
    }
    if (this.location != null) {
      map['location'] = this.location!.toJson();
    }
    if (availability != null) {
      map['availability'] = availability?.map((v) => v.toJson()).toList();
    }
    map['classRange'] = classRange;
    map['studentTeacherRatio'] = studentTeacherRatio;
    map['board'] = boards;
    map['mediumOfInstruction'] = mediumOfInstruction;
    map['fees'] = fees;
    map['numberOfStudents'] = numberOfStudents;
    map['avg_rating'] = avgRating;
    return map;
  }
}

class Availability {
  Availability({
    this.day,
    this.isOpen,
    this.openTime,
    this.closeTime,
  });

  Availability.fromJson(dynamic json) {
    day = json['day'];
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }

  String? day;
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() => {
        'day': day,
        'isOpen': isOpen,
        'openTime': openTime,
        'closeTime': closeTime,
      };
}

Courses coursesFromJson(String str) => Courses.fromJson(json.decode(str));
String coursesToJson(Courses data) => json.encode(data.toJson());

class Courses {
  Courses({
    this.courseFees,
    this.id,
    this.name,
    this.admissionProcess,
    this.eligibility,
    this.duration,
    this.description,
    this.image,
    this.schoolId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Courses.fromJson(dynamic json) {
    courseFees = json['courseFees'] != null
        ? CourseFees.fromJson(json['courseFees'])
        : null;
    id = json['_id'];
    name = json['name'];
    admissionProcess = json['admissionProcess'];
    eligibility = json['eligibility'];
    duration = json['duration'];
    description = json['description'];
    image = json['image']?.toString();
    schoolId = json['schoolId'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  CourseFees? courseFees;
  String? id;
  String? name;
  String? admissionProcess;
  String? eligibility;
  String? duration;
  String? description;
  String? image;
  String? schoolId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (courseFees != null) {
      map['courseFees'] = courseFees?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['admissionProcess'] = admissionProcess;
    map['eligibility'] = eligibility;
    map['duration'] = duration;
    map['description'] = description;
    map['image'] = image;
    map['schoolId'] = schoolId;
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}

CourseFees courseFeesFromJson(String str) =>
    CourseFees.fromJson(json.decode(str));
String courseFeesToJson(CourseFees data) => json.encode(data.toJson());

class CourseFees {
  CourseFees({
    this.monthly,
    this.yearly,
  });

  CourseFees.fromJson(dynamic json) {
    monthly = json['monthly'];
    yearly = json['yearly'];
  }
  int? monthly;
  int? yearly;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['monthly'] = monthly;
    map['yearly'] = yearly;
    return map;
  }
}

AboutId aboutIdFromJson(String str) => AboutId.fromJson(json.decode(str));
String aboutIdToJson(AboutId data) => json.encode(data.toJson());

class AboutId {
  AboutId({
    this.history,
    this.principalMessage,
    this.id,
    this.visionAndMission,
    this.management,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  AboutId.fromJson(dynamic json) {
    history =
        json['history'] != null ? History.fromJson(json['history']) : null;
    principalMessage = json['principalMessage'] != null
        ? PrincipalMessage.fromJson(json['principalMessage'])
        : null;
    id = json['_id'];
    visionAndMission = json['visionAndMission'];
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(Management.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  History? history;
  PrincipalMessage? principalMessage;
  String? id;
  String? visionAndMission;
  List<Management>? management;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (history != null) {
      map['history'] = history?.toJson();
    }
    if (principalMessage != null) {
      map['principalMessage'] = principalMessage?.toJson();
    }
    map['_id'] = id;
    map['visionAndMission'] = visionAndMission;
    if (management != null) {
      map['management'] = management?.map((v) => v.toJson()).toList();
    }
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}

PrincipalMessage principalMessageFromJson(String str) =>
    PrincipalMessage.fromJson(json.decode(str));
String principalMessageToJson(PrincipalMessage data) =>
    json.encode(data.toJson());

class PrincipalMessage {
  PrincipalMessage({
    this.name,
    this.position,
    this.photo,
    this.message,
  });

  PrincipalMessage.fromJson(dynamic json) {
    name = json['name'];
    position = json['position'];
    photo = json['photo'];
    message = json['message'];
  }
  String? name;
  String? position;
  String? photo;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['position'] = position;
    map['photo'] = photo;
    map['message'] = message;
    return map;
  }
}

History historyFromJson(String str) => History.fromJson(json.decode(str));
String historyToJson(History data) => json.encode(data.toJson());

class History {
  History({
    this.message,
    this.photo,
  });

  History.fromJson(dynamic json) {
    message = json['message'];
    photo = json['photo'];
  }
  String? message;
  dynamic photo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['photo'] = photo;
    return map;
  }
}

Contacts contactsFromJson(String str) => Contacts.fromJson(json.decode(str));
String contactsToJson(Contacts data) => json.encode(data.toJson());

class Contacts {
  Contacts({
    this.branch,
    this.id,
    this.departments,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Contacts.fromJson(dynamic json) {
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
    id = json['_id'];
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Branch? branch;
  String? id;
  List<Departments>? departments;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (branch != null) {
      map['branch'] = branch?.toJson();
    }
    map['_id'] = id;
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());

class Location {
  Location({
    this.name,
    this.type,
    this.coordinates,
  });

  Location.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    coordinates =
        json['coordinates'] != null ? json['coordinates'].cast<num>() : [];
  }
  String? name;
  String? type;
  List<num>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }
}

CampusLife campusLifeFromJson(String str) =>
    CampusLife.fromJson(json.decode(str));
String campusLifeToJson(CampusLife data) => json.encode(data.toJson());

class CampusLife {
  CampusLife({
    this.id,
    this.category,
    this.subcategory,
    this.images,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.subcategoryData,
  });

  CampusLife.fromJson(dynamic json) {
    id = json['_id'];
    category =
        json['category'] != null ? Category.fromJson(json['category']) : null;
    subcategory = json['subcategory'];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(Images.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    subcategoryData = json['subcategoryData'] != null
        ? SubcategoryData.fromJson(json['subcategoryData'])
        : null;
  }
  String? id;
  Category? category;
  String? subcategory;
  List<Images>? images;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;
  SubcategoryData? subcategoryData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (category != null) {
      map['category'] = category?.toJson();
    }
    map['subcategory'] = subcategory;
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (subcategoryData != null) {
      map['subcategoryData'] = subcategoryData?.toJson();
    }
    return map;
  }
}

SubcategoryData subcategoryDataFromJson(String str) =>
    SubcategoryData.fromJson(json.decode(str));
String subcategoryDataToJson(SubcategoryData data) =>
    json.encode(data.toJson());

class SubcategoryData {
  SubcategoryData({
    this.name,
    this.type,
    this.active,
    this.deletedAt,
    this.createdBy,
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  SubcategoryData.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    active = json['active'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    id = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? name;
  String? type;
  bool? active;
  dynamic deletedAt;
  dynamic createdBy;
  String? id;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['active'] = active;
    map['deleted_at'] = deletedAt;
    map['created_by'] = createdBy;
    map['_id'] = id;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }
}

Images imagesFromJson(String str) => Images.fromJson(json.decode(str));
String imagesToJson(Images data) => json.encode(data.toJson());

class Images {
  Images({
    this.url,
    this.caption,
    this.id,
    this.createdAt,
  });

  Images.fromJson(dynamic json) {
    if (json is String) {
      url = json;
    } else if (json is Map) {
      url = json['url'];
      caption = json['caption'];
      id = json['_id'];
      createdAt = json['createdAt'];
    }
  }
  String? url;
  String? caption;
  String? id;
  String? createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['caption'] = caption;
    map['_id'] = id;
    map['createdAt'] = createdAt;
    return map;
  }
}

Category categoryFromJson(String str) => Category.fromJson(json.decode(str));
String categoryToJson(Category data) => json.encode(data.toJson());

class Category {
  Category({
    this.id,
    this.name,
    this.type,
  });

  Category.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
  }
  String? id;
  String? name;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    return map;
  }
}
