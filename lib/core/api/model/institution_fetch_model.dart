import 'dart:convert';
InstitutionFetchModel institutionFetchModelFromJson(String str) => InstitutionFetchModel.fromJson(json.decode(str));
String institutionFetchModelToJson(InstitutionFetchModel data) => json.encode(data.toJson());
class InstitutionFetchModel {
  InstitutionFetchModel({
      this.success, 
      this.data,});

  InstitutionFetchModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? InstitutionFetchData.fromJson(json['data']) : null;
  }
  bool? success;
  InstitutionFetchData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

InstitutionFetchData dataFromJson(String str) => InstitutionFetchData.fromJson(json.decode(str));
String dataToJson(InstitutionFetchData data) => json.encode(data.toJson());
class InstitutionFetchData {
  InstitutionFetchData({
      this.name, 
      this.type, 
      this.contactUs, 
      this.aboutUs, 
      this.academics, 
      this.campusLife, 
      this.career, 
      this.description, 
      this.establishmentYear, 
      this.gallery, 
      this.logo, 
      this.newsAndEvents, 
      this.studentCorner, 
      this.website,});

  InstitutionFetchData.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    contactUs = json['contactUs'] != null ? ContactUs.fromJson(json['contactUs']) : null;
    aboutUs = json['aboutUs'] != null ? AboutUs.fromJson(json['aboutUs']) : null;
    academics = json['academics'] != null ? Academics.fromJson(json['academics']) : null;
    campusLife = json['campusLife'] != null ? CampusLife.fromJson(json['campusLife']) : null;
    career = json['career'];
    description = json['description'];
    establishmentYear = json['establishmentYear'];
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(Gallery.fromJson(v));
      });
    }
    logo = json['logo'];
    if (json['newsAndEvents'] != null) {
      newsAndEvents = [];
      json['newsAndEvents'].forEach((v) {
        newsAndEvents?.add(NewsAndEvents.fromJson(v));
      });
    }
    studentCorner = json['studentCorner'] != null ? StudentCorner.fromJson(json['studentCorner']) : null;
    website = json['website'];
  }
  String? name;
  String? type;
  ContactUs? contactUs;
  AboutUs? aboutUs;
  Academics? academics;
  CampusLife? campusLife;
  String? career;
  String? description;
  int? establishmentYear;
  List<Gallery>? gallery;
  String? logo;
  List<NewsAndEvents>? newsAndEvents;
  StudentCorner? studentCorner;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    if (contactUs != null) {
      map['contactUs'] = contactUs?.toJson();
    }
    if (aboutUs != null) {
      map['aboutUs'] = aboutUs?.toJson();
    }
    if (academics != null) {
      map['academics'] = academics?.toJson();
    }
    if (campusLife != null) {
      map['campusLife'] = campusLife?.toJson();
    }
    map['career'] = career;
    map['description'] = description;
    map['establishmentYear'] = establishmentYear;
    if (gallery != null) {
      map['gallery'] = gallery?.map((v) => v.toJson()).toList();
    }
    map['logo'] = logo;
    if (newsAndEvents != null) {
      map['newsAndEvents'] = newsAndEvents?.map((v) => v.toJson()).toList();
    }
    if (studentCorner != null) {
      map['studentCorner'] = studentCorner?.toJson();
    }
    map['website'] = website;
    return map;
  }

}

StudentCorner studentCornerFromJson(String str) => StudentCorner.fromJson(json.decode(str));
String studentCornerToJson(StudentCorner data) => json.encode(data.toJson());
class StudentCorner {
  StudentCorner({
      this.syllabus, 
      this.timeTable,});

  StudentCorner.fromJson(dynamic json) {
    syllabus = json['syllabus'];
    timeTable = json['timeTable'];
  }
  String? syllabus;
  String? timeTable;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['syllabus'] = syllabus;
    map['timeTable'] = timeTable;
    return map;
  }

}

NewsAndEvents newsAndEventsFromJson(String str) => NewsAndEvents.fromJson(json.decode(str));
String newsAndEventsToJson(NewsAndEvents data) => json.encode(data.toJson());
class NewsAndEvents {
  NewsAndEvents({
      this.date, 
      this.description, 
      this.image, 
      this.title,});

  NewsAndEvents.fromJson(dynamic json) {
    date = json['date'];
    description = json['description'];
    image = json['image'];
    title = json['title'];
  }
  String? date;
  String? description;
  String? image;
  String? title;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['description'] = description;
    map['image'] = image;
    map['title'] = title;
    return map;
  }

}

Gallery galleryFromJson(String str) => Gallery.fromJson(json.decode(str));
String galleryToJson(Gallery data) => json.encode(data.toJson());
class Gallery {
  Gallery({
      this.caption, 
      this.category, 
      this.url,});

  Gallery.fromJson(dynamic json) {
    caption = json['caption'];
    category = json['category'];
    url = json['url'];
  }
  String? caption;
  String? category;
  String? url;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['caption'] = caption;
    map['category'] = category;
    map['url'] = url;
    return map;
  }

}

CampusLife campusLifeFromJson(String str) => CampusLife.fromJson(json.decode(str));
String campusLifeToJson(CampusLife data) => json.encode(data.toJson());
class CampusLife {
  CampusLife({
      this.infrastructure,});

  CampusLife.fromJson(dynamic json) {
    infrastructure = json['infrastructure'] != null ? Infrastructure.fromJson(json['infrastructure']) : null;
  }
  Infrastructure? infrastructure;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (infrastructure != null) {
      map['infrastructure'] = infrastructure?.toJson();
    }
    return map;
  }

}

Infrastructure infrastructureFromJson(String str) => Infrastructure.fromJson(json.decode(str));
String infrastructureToJson(Infrastructure data) => json.encode(data.toJson());
class Infrastructure {
  Infrastructure({
      this.auditoriums, 
      this.classrooms, 
      this.hostel, 
      this.labs, 
      this.libraries, 
      this.sportsFacilities,});

  Infrastructure.fromJson(dynamic json) {
    auditoriums = json['auditoriums'];
    classrooms = json['classrooms'];
    hostel = json['hostel'] != null ? Hostel.fromJson(json['hostel']) : null;
    labs = json['labs'];
    libraries = json['libraries'];
    sportsFacilities = json['sportsFacilities'] != null ? json['sportsFacilities'].cast<String>() : [];
  }
  int? auditoriums;
  int? classrooms;
  Hostel? hostel;
  int? labs;
  int? libraries;
  List<String>? sportsFacilities;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['auditoriums'] = auditoriums;
    map['classrooms'] = classrooms;
    if (hostel != null) {
      map['hostel'] = hostel?.toJson();
    }
    map['labs'] = labs;
    map['libraries'] = libraries;
    map['sportsFacilities'] = sportsFacilities;
    return map;
  }

}

Hostel hostelFromJson(String str) => Hostel.fromJson(json.decode(str));
String hostelToJson(Hostel data) => json.encode(data.toJson());
class Hostel {
  Hostel({
      this.available, 
      this.capacity, 
      this.facilities,});

  Hostel.fromJson(dynamic json) {
    available = json['available'];
    capacity = json['capacity'];
    facilities = json['facilities'] != null ? json['facilities'].cast<String>() : [];
  }
  bool? available;
  int? capacity;
  List<String>? facilities;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['available'] = available;
    map['capacity'] = capacity;
    map['facilities'] = facilities;
    return map;
  }

}

Academics academicsFromJson(String str) => Academics.fromJson(json.decode(str));
String academicsToJson(Academics data) => json.encode(data.toJson());
class Academics {
  Academics({
      this.academicCalendar, 
      this.courses, 
      this.departments,});

  Academics.fromJson(dynamic json) {
    academicCalendar = json['academicCalendar'];
    if (json['courses'] != null) {
      courses = [];
      json['courses'].forEach((v) {
        courses?.add(Courses.fromJson(v));
      });
    }
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
  }
  String? academicCalendar;
  List<Courses>? courses;
  List<Departments>? departments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['academicCalendar'] = academicCalendar;
    if (courses != null) {
      map['courses'] = courses?.map((v) => v.toJson()).toList();
    }
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Departments departmentsFromJson(String str) => Departments.fromJson(json.decode(str));
String departmentsToJson(Departments data) => json.encode(data.toJson());
class Departments {
  Departments({
      this.description, 
      this.hodName, 
      this.image, 
      this.name,});

  Departments.fromJson(dynamic json) {
    description = json['description'];
    hodName = json['hodName'];
    image = json['image'];
    name = json['name'];
  }
  String? description;
  String? hodName;
  String? image;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['hodName'] = hodName;
    map['image'] = image;
    map['name'] = name;
    return map;
  }

}

Courses coursesFromJson(String str) => Courses.fromJson(json.decode(str));
String coursesToJson(Courses data) => json.encode(data.toJson());
class Courses {
  Courses({
      this.duration, 
      this.eligibility, 
      this.fees, 
      this.name,});

  Courses.fromJson(dynamic json) {
    duration = json['duration'];
    eligibility = json['eligibility'];
    fees = json['fees'];
    name = json['name'];
  }
  String? duration;
  String? eligibility;
  String? fees;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['duration'] = duration;
    map['eligibility'] = eligibility;
    map['fees'] = fees;
    map['name'] = name;
    return map;
  }

}

AboutUs aboutUsFromJson(String str) => AboutUs.fromJson(json.decode(str));
String aboutUsToJson(AboutUs data) => json.encode(data.toJson());
class AboutUs {
  AboutUs({
      this.history, 
      this.management, 
      this.principalMessage, 
      this.visionAndMission,});

  AboutUs.fromJson(dynamic json) {
    history = json['history'];
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(Management.fromJson(v));
      });
    }
    principalMessage = json['principalMessage'] != null ? PrincipalMessage.fromJson(json['principalMessage']) : null;
    visionAndMission = json['visionAndMission'];
  }
  String? history;
  List<Management>? management;
  PrincipalMessage? principalMessage;
  String? visionAndMission;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['history'] = history;
    if (management != null) {
      map['management'] = management?.map((v) => v.toJson()).toList();
    }
    if (principalMessage != null) {
      map['principalMessage'] = principalMessage?.toJson();
    }
    map['visionAndMission'] = visionAndMission;
    return map;
  }

}

PrincipalMessage principalMessageFromJson(String str) => PrincipalMessage.fromJson(json.decode(str));
String principalMessageToJson(PrincipalMessage data) => json.encode(data.toJson());
class PrincipalMessage {
  PrincipalMessage({
      this.message, 
      this.name, 
      this.photo, 
      this.position,});

  PrincipalMessage.fromJson(dynamic json) {
    message = json['message'];
    name = json['name'];
    photo = json['photo'];
    position = json['position'];
  }
  String? message;
  String? name;
  String? photo;
  String? position;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['name'] = name;
    map['photo'] = photo;
    map['position'] = position;
    return map;
  }

}

Management managementFromJson(String str) => Management.fromJson(json.decode(str));
String managementToJson(Management data) => json.encode(data.toJson());
class Management {
  Management({
      this.bio, 
      this.name, 
      this.photo, 
      this.position,});

  Management.fromJson(dynamic json) {
    bio = json['bio'];
    name = json['name'];
    photo = json['photo'];
    position = json['position'];
  }
  String? bio;
  String? name;
  String? photo;
  String? position;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bio'] = bio;
    map['name'] = name;
    map['photo'] = photo;
    map['position'] = position;
    return map;
  }

}

ContactUs contactUsFromJson(String str) => ContactUs.fromJson(json.decode(str));
String contactUsToJson(ContactUs data) => json.encode(data.toJson());
class ContactUs {
  ContactUs({
      this.address, 
      this.email, 
      this.location, 
      this.phone,});

  ContactUs.fromJson(dynamic json) {
    address = json['address'];
    email = json['email'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    phone = json['phone'];
  }
  String? address;
  String? email;
  Location? location;
  String? phone;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = address;
    map['email'] = email;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['phone'] = phone;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.coordinates, 
      this.type,});

  Location.fromJson(dynamic json) {
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
    type = json['type'];
  }
  List<double>? coordinates;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['coordinates'] = coordinates;
    map['type'] = type;
    return map;
  }

}