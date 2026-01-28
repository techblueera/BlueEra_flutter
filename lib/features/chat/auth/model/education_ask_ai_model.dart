import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import '../../../../core/api/model/school_contact_us_res_model.dart';

class EducationAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  EducationAskAiModel(
      {
        super.conversationId,
        super.role,
        super.timestamp,
        super.message,
        this.suggestions,
        this.data,
        });

  EducationAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null;
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['reply'] = this.message;
    data['conversationId'] = this.conversationId;
    data['suggestions'] = this.suggestions;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  bool? found;
  List<Institutions>? institutions;

  Data({this.found, this.institutions});

  Data.fromJson(Map<String, dynamic> json) {
    found = json['found'];
    if (json['institutions'] != null) {
      institutions = <Institutions>[];
      json['institutions'].forEach((v) {
        institutions!.add(new Institutions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['found'] = this.found;
    if (this.institutions != null) {
      data['institutions'] = this.institutions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Institutions {
  Location? location;
  String? sId;
  String? name;
  String? type;
  String? description;
  int? establishmentYear;
  String? logo;
  String? career;
  List<Contacts>? contacts;
  List<Notices>? notices;
  List<Gallery>? gallery;
  String? ownerId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;
  AboutId? aboutId;
  AcademicsId? academicsId;
  StudentCornerId? studentCornerId;
  CampusLifeId? campusLifeId;
  double? score;
  List<Courses>? courses;
  List<Faculty>? faculty;

  Institutions(
      {this.location,
        this.sId,
        this.name,
        this.type,
        this.description,
        this.establishmentYear,
        this.logo,
        this.career,
        this.contacts,
        this.notices,
        this.gallery,
        this.ownerId,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.aboutId,
        this.academicsId,
        this.studentCornerId,
        this.campusLifeId,
        this.score,
        this.courses,
        this.faculty,
       });

  Institutions.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    sId = json['_id'];
    name = json['name'];
    type = json['type'];
    description = json['description'];
    establishmentYear = json['establishmentYear'];
    logo = json['logo'];
    career = json['career'];
    if (json['contacts'] != null) {
      contacts = <Contacts>[];
      json['contacts'].forEach((v) {
        contacts!.add(new Contacts.fromJson(v));
      });
    }
    if (json['notices'] != null) {
      notices = <Notices>[];
      json['notices'].forEach((v) {
        notices!.add(new Notices.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = <Gallery>[];
      json['gallery'].forEach((v) {
        gallery!.add(new Gallery.fromJson(v));
      });
    }
    ownerId = json['ownerId'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    aboutId =
    json['aboutId'] != null ? new AboutId.fromJson(json['aboutId']) : null;
    academicsId = json['academicsId'] != null
        ? new AcademicsId.fromJson(json['academicsId'])
        : null;
    studentCornerId = json['studentCornerId'] != null
        ? new StudentCornerId.fromJson(json['studentCornerId'])
        : null;
    campusLifeId = json['campusLifeId'] != null
        ? new CampusLifeId.fromJson(json['campusLifeId'])
        : null;
    score = json['score'];
    if (json['courses'] != null) {
      courses = <Courses>[];
      json['courses'].forEach((v) {
        courses!.add(new Courses.fromJson(v));
      });
    }
    if (json['faculty'] != null) {
      faculty = <Faculty>[];
      json['faculty'].forEach((v) {
        faculty!.add(new Faculty.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['type'] = this.type;
    data['description'] = this.description;
    data['establishmentYear'] = this.establishmentYear;
    data['logo'] = this.logo;
    data['career'] = this.career;
    if (this.contacts != null) {
      data['contacts'] = this.contacts!.map((v) => v.toJson()).toList();
    }
    if (this.notices != null) {
      data['notices'] = this.notices!.map((v) => v.toJson()).toList();
    }
    if (this.gallery != null) {
      data['gallery'] = this.gallery!.map((v) => v.toJson()).toList();
    }
    data['ownerId'] = this.ownerId;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.aboutId != null) {
      data['aboutId'] = this.aboutId!.toJson();
    }
    if (this.academicsId != null) {
      data['academicsId'] = this.academicsId!.toJson();
    }
    if (this.studentCornerId != null) {
      data['studentCornerId'] = this.studentCornerId!.toJson();
    }
    if (this.campusLifeId != null) {
      data['campusLifeId'] = this.campusLifeId!.toJson();
    }
    data['score'] = this.score;
    if (this.courses != null) {
      data['courses'] = this.courses!.map((v) => v.toJson()).toList();
    }
    if (this.faculty != null) {
      data['faculty'] = this.faculty!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Location {
  String? name;
  String? type;
  List<double>? coordinates;

  Location({this.name, this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class Contacts {
  Branch? branch;
  String? sId;
  List<Departments>? departments;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Contacts(
      {this.branch,
        this.sId,
        this.departments,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Contacts.fromJson(Map<String, dynamic> json) {
    branch =
    json['branch'] != null ? new Branch.fromJson(json['branch']) : null;
    sId = json['_id'];
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.branch != null) {
      data['branch'] = this.branch!.toJson();
    }
    data['_id'] = this.sId;
    if (departments != null) {
      data['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Branch {
  Location? location;
  String? website;

  Branch({this.location, this.website});

  Branch.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['website'] = this.website;
    return data;
  }
}

class Notices {
  String? sId;
  String? uploadPhoto;
  String? title;
  String? description;
  String? date;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Notices(
      {this.sId,
        this.uploadPhoto,
        this.title,
        this.description,
        this.date,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Notices.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    uploadPhoto = json['uploadPhoto'];
    title = json['title'];
    description = json['description'];
    date = json['date'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['uploadPhoto'] = this.uploadPhoto;
    data['title'] = this.title;
    data['description'] = this.description;
    data['date'] = this.date;
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Gallery {
  String? sId;
  String? uploadPhoto;
  String? caption;
  String? category;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Gallery(
      {this.sId,
        this.uploadPhoto,
        this.caption,
        this.category,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Gallery.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    uploadPhoto = json['uploadPhoto'];
    caption = json['caption'];
    category = json['category'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['uploadPhoto'] = this.uploadPhoto;
    data['caption'] = this.caption;
    data['category'] = this.category;
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class AboutId {
  History? history;
  PrincipalMessage? principalMessage;
  String? sId;
  String? visionAndMission;
  List<Management>? management;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AboutId(
      {this.history,
        this.principalMessage,
        this.sId,
        this.visionAndMission,
        this.management,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  AboutId.fromJson(Map<String, dynamic> json) {
    history =
    json['history'] != null ? new History.fromJson(json['history']) : null;
    principalMessage = json['principalMessage'] != null
        ? new PrincipalMessage.fromJson(json['principalMessage'])
        : null;
    sId = json['_id'];
    visionAndMission = json['visionAndMission'];
    if (json['management'] != null) {
      management = <Management>[];
      json['management'].forEach((v) {
        management!.add(new Management.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.history != null) {
      data['history'] = this.history!.toJson();
    }
    if (this.principalMessage != null) {
      data['principalMessage'] = this.principalMessage!.toJson();
    }
    data['_id'] = this.sId;
    data['visionAndMission'] = this.visionAndMission;
    if (this.management != null) {
      data['management'] = this.management!.map((v) => v.toJson()).toList();
    }
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class History {
  String? message;
  String? photo;

  History({this.message, this.photo});

  History.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    photo = json['photo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['photo'] = this.photo;
    return data;
  }
}

class PrincipalMessage {
  String? name;
  String? position;
  String? photo;
  String? message;

  PrincipalMessage({this.name, this.position, this.photo, this.message});

  PrincipalMessage.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    position = json['position'];
    photo = json['photo'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['position'] = this.position;
    data['photo'] = this.photo;
    data['message'] = this.message;
    return data;
  }
}

class Management {
  String? name;
  String? position;
  String? photo;
  String? bio;
  String? sId;

  Management(
      {this.name,
        this.position,
        this.photo,
        this.bio,
        this.sId});

  Management.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    position = json['position'];
    photo = json['photo'];
    bio = json['bio'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['position'] = this.position;
    data['photo'] = this.photo;
    data['bio'] = this.bio;
    data['_id'] = this.sId;
    return data;
  }
}

class AcademicsId {
  String? sId;
  String? title;
  String? fileUrl;
  String? description;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AcademicsId(
      {this.sId,
        this.title,
        this.fileUrl,
        this.description,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  AcademicsId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    fileUrl = json['fileUrl'];
    description = json['description'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['fileUrl'] = this.fileUrl;
    data['description'] = this.description;
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class StudentCornerId {
  String? sId;
  List<TimeTable>? timeTable;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  StudentCornerId(
      {this.sId,
        this.timeTable,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  StudentCornerId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    if (json['timeTable'] != null) {
      timeTable = <TimeTable>[];
      json['timeTable'].forEach((v) {
        timeTable!.add(new TimeTable.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    if (this.timeTable != null) {
      data['timeTable'] = this.timeTable!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class TimeTable {
  String? title;
  String? fileUrl;
  String? description;
  String? sId;

  TimeTable({this.title, this.fileUrl, this.description, this.sId});

  TimeTable.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    fileUrl = json['fileUrl'];
    description = json['description'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['fileUrl'] = this.fileUrl;
    data['description'] = this.description;
    data['_id'] = this.sId;
    return data;
  }
}

class CampusLifeId {
  String? sId;
  String? category;
  String? subcategory;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  CampusLifeId(
      {this.sId,
        this.category,
        this.subcategory,
        this.schoolId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  CampusLifeId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    category = json['category'];
    subcategory = json['subcategory'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['category'] = this.category;
    data['subcategory'] = this.subcategory;
    data['schoolId'] = this.schoolId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Courses {
  CourseFees? courseFees;
  String? sId;
  String? name;
  String? admissionProcess;
  String? eligibility;
  String? duration;
  String? description;
  String? schoolId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Courses(
      {this.courseFees,
        this.sId,
        this.name,
        this.admissionProcess,
        this.eligibility,
        this.duration,
        this.description,
        this.schoolId,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Courses.fromJson(Map<String, dynamic> json) {
    courseFees = json['courseFees'] != null
        ? new CourseFees.fromJson(json['courseFees'])
        : null;
    sId = json['_id'];
    name = json['name'];
    admissionProcess = json['admissionProcess'];
    eligibility = json['eligibility'];
    duration = json['duration'];
    description = json['description'];
    schoolId = json['schoolId'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.courseFees != null) {
      data['courseFees'] = this.courseFees!.toJson();
    }
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['admissionProcess'] = this.admissionProcess;
    data['eligibility'] = this.eligibility;
    data['duration'] = this.duration;
    data['description'] = this.description;
    data['schoolId'] = this.schoolId;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class CourseFees {
  int? monthly;
  int? yearly;

  CourseFees({this.monthly, this.yearly});

  CourseFees.fromJson(Map<String, dynamic> json) {
    monthly = json['monthly'];
    yearly = json['yearly'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['monthly'] = this.monthly;
    data['yearly'] = this.yearly;
    return data;
  }
}

class Faculty {
  Experience? experience;
  String? sId;
  String? name;
  String? position;
  String? school;
  String? email;
  String? phone;
  String? photo;
  String? bio;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Faculty(
      {this.experience,
        this.sId,
        this.name,
        this.position,
        this.school,
        this.email,
        this.phone,
        this.photo,
        this.bio,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Faculty.fromJson(Map<String, dynamic> json) {
    experience = json['experience'] != null
        ? new Experience.fromJson(json['experience'])
        : null;
    sId = json['_id'];
    name = json['name'];
    position = json['position'];
    school = json['school'];
    email = json['email'];
    phone = json['phone'];
    photo = json['photo'];
    bio = json['bio'];
    isActive = json['isActive'];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.experience != null) {
      data['experience'] = this.experience!.toJson();
    }
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['position'] = this.position;
    data['school'] = this.school;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['photo'] = this.photo;
    data['bio'] = this.bio;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Experience {
  int? years;
  String? details;

  Experience({this.years, this.details});

  Experience.fromJson(Map<String, dynamic> json) {
    years = json['years'];
    details = json['details'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['years'] = this.years;
    data['details'] = this.details;
    return data;
  }
}