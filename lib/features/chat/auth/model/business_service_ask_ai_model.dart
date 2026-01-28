import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_main_page_model.dart';

class BusinessServicesAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  BusinessServicesAskAiModel({
    super.conversationId,
    super.role,
    super.timestamp,
    super.message,
    this.suggestions,
    this.data,
   });

  BusinessServicesAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null;    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    timestamp = json['timestamp'];
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
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Data {
  bool? success;
  List<ServiceData>? data;

  Data({this.success, this.data});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <ServiceData>[];
      json['data'].forEach((v) {
        data!.add(new ServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceData {
  Profile? profile;
  List<AboutOrganisation>? aboutOrganisation;
  List<Management>? management;
  List<Staff>? staff;
  List<Blogs>? blogs;
  List<News>? news;
  List<Gallery>? gallery;
  Timings? timings;
  List<ContactUs>? contactUs;

  ServiceData({this.profile,
    this.aboutOrganisation,
    this.management,
    this.staff,
    this.blogs,
    this.news,
    this.gallery,
    this.timings,
    this.contactUs,
    });

  ServiceData.fromJson(Map<String, dynamic> json) {
    profile =
    json['profile'] != null ? new Profile.fromJson(json['profile']) : null;
    if (json['aboutOrganisation'] != null) {
      aboutOrganisation = <AboutOrganisation>[];
      json['aboutOrganisation'].forEach((v) {
        aboutOrganisation!.add(new AboutOrganisation.fromJson(v));
      });
    }
    if (json['management'] != null) {
      management = <Management>[];
      json['management'].forEach((v) {
        management!.add(new Management.fromJson(v));
      });
    }
    if (json['staff'] != null) {
      staff = <Staff>[];
      json['staff'].forEach((v) {
        staff!.add(new Staff.fromJson(v));
      });
    }
    if (json['blogs'] != null) {
      blogs = <Blogs>[];
      json['blogs'].forEach((v) {
        blogs!.add(new Blogs.fromJson(v));
      });
    }
    if (json['news'] != null) {
      news = <News>[];
      json['news'].forEach((v) {
        news!.add(new News.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = <Gallery>[];
      json['gallery'].forEach((v) {
        gallery!.add(new Gallery.fromJson(v));
      });
    }
    timings =
    json['timings'] != null ? new Timings.fromJson(json['timings']) : null;
    if (json['contactUs'] != null) {
      contactUs = <ContactUs>[];
      json['contactUs'].forEach((v) {
        contactUs!.add(new ContactUs.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.profile != null) {
      data['profile'] = this.profile!.toJson();
    }
    if (this.aboutOrganisation != null) {
      data['aboutOrganisation'] =
          this.aboutOrganisation!.map((v) => v.toJson()).toList();
    }
    if (this.management != null) {
      data['management'] = this.management!.map((v) => v.toJson()).toList();
    }
    if (this.staff != null) {
      data['staff'] = this.staff!.map((v) => v.toJson()).toList();
    }
    if (this.blogs != null) {
      data['blogs'] = this.blogs!.map((v) => v.toJson()).toList();
    }
    if (this.news != null) {
      data['news'] = this.news!.map((v) => v.toJson()).toList();
    }
    if (this.gallery != null) {
      data['gallery'] = this.gallery!.map((v) => v.toJson()).toList();
    }
    if (this.timings != null) {
      data['timings'] = this.timings!.toJson();
    }
    if (this.contactUs != null) {
      data['contactUs'] = this.contactUs!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Profile {
  Location? location;
  String? sId;
  String? userId;
  int? iV;
  String? coverUrl;
  String? createdAt;
  String? description;
  String? logoUrl;
  String? profileName;
  String? updatedAt;

  Profile({this.location,
    this.sId,
    this.userId,
    this.iV,
    this.coverUrl,
    this.createdAt,
    this.description,
    this.logoUrl,
    this.profileName,
    this.updatedAt});

  Profile.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    sId = json['_id'];
    userId = json['userId'];
    iV = json['__v'];
    coverUrl = json['coverUrl'];
    createdAt = json['createdAt'];
    description = json['description'];
    logoUrl = json['logoUrl'];
    profileName = json['profileName'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['__v'] = this.iV;
    data['coverUrl'] = this.coverUrl;
    data['createdAt'] = this.createdAt;
    data['description'] = this.description;
    data['logoUrl'] = this.logoUrl;
    data['profileName'] = this.profileName;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class Location {
  String? address;
  List<double>? coordinates;

  Location({this.address, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    coordinates = json['coordinates'] != null
        ? List<double>.from(json['coordinates'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address'] = this.address;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class AboutOrganisation {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? imageUrl;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AboutOrganisation({this.sId,
    this.userId,
    this.businessProfileId,
    this.imageUrl,
    this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.iV});

  AboutOrganisation.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrl = json['imageUrl'];
    title = json['title'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['imageUrl'] = this.imageUrl;
    data['title'] = this.title;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Management {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? name;
  String? position;
  String? qualification;
  String? message;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Management({this.sId,
    this.userId,
    this.businessProfileId,
    this.name,
    this.position,
    this.qualification,
    this.message,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.iV});

  Management.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    message = json['message'];
    imageUrl = json['imageUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['name'] = this.name;
    data['position'] = this.position;
    data['qualification'] = this.qualification;
    data['message'] = this.message;
    data['imageUrl'] = this.imageUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Staff {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? name;
  String? position;
  String? qualification;
  String? joinedFrom;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? joinedTo;

  Staff({this.sId,
    this.userId,
    this.businessProfileId,
    this.name,
    this.position,
    this.qualification,
    this.joinedFrom,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.joinedTo});

  Staff.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    joinedFrom = json['joinedFrom'];
    imageUrl = json['imageUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    joinedTo = json['joinedTo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['name'] = this.name;
    data['position'] = this.position;
    data['qualification'] = this.qualification;
    data['joinedFrom'] = this.joinedFrom;
    data['imageUrl'] = this.imageUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['joinedTo'] = this.joinedTo;
    return data;
  }
}

class Blogs {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? imageUrl;
  String? title;
  String? blog;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Blogs({this.sId,
    this.userId,
    this.businessProfileId,
    this.imageUrl,
    this.title,
    this.blog,
    this.createdAt,
    this.updatedAt,
    this.iV});

  Blogs.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrl = json['imageUrl'];
    title = json['title'];
    blog = json['blog'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['imageUrl'] = this.imageUrl;
    data['title'] = this.title;
    data['blog'] = this.blog;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class News {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? imageUrl;
  String? title;
  String? news;
  String? createdAt;
  String? updatedAt;
  int? iV;

  News({this.sId,
    this.userId,
    this.businessProfileId,
    this.imageUrl,
    this.title,
    this.news,
    this.createdAt,
    this.updatedAt,
    this.iV});

  News.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrl = json['imageUrl'];
    title = json['title'];
    news = json['news'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['imageUrl'] = this.imageUrl;
    data['title'] = this.title;
    data['news'] = this.news;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Gallery {
  String? sId;
  String? userId;
  String? businessProfileId;
  List<String>? imageUrls;
  String? title;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Gallery({this.sId,
    this.userId,
    this.businessProfileId,
    this.imageUrls,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.iV});

  Gallery.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrls = json['imageUrls'].cast<String>();
    title = json['title'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['imageUrls'] = this.imageUrls;
    data['title'] = this.title;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Timings {
  String? sId;
  String? userId;
  int? iV;
  String? businessProfileId;
  String? createdAt;
  Friday? friday;
  Friday? monday;
  Friday? saturday;
  Friday? sunday;
  Friday? thursday;
  Friday? tuesday;
  String? updatedAt;
  Friday? wednesday;

  Timings({this.sId,
    this.userId,
    this.iV,
    this.businessProfileId,
    this.createdAt,
    this.friday,
    this.monday,
    this.saturday,
    this.sunday,
    this.thursday,
    this.tuesday,
    this.updatedAt,
    this.wednesday});

  Timings.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    iV = json['__v'];
    businessProfileId = json['businessProfileId'];
    createdAt = json['createdAt'];
    friday =
    json['friday'] != null ? new Friday.fromJson(json['friday']) : null;
    monday =
    json['monday'] != null ? new Friday.fromJson(json['monday']) : null;
    saturday =
    json['saturday'] != null ? new Friday.fromJson(json['saturday']) : null;
    sunday =
    json['sunday'] != null ? new Friday.fromJson(json['sunday']) : null;
    thursday =
    json['thursday'] != null ? new Friday.fromJson(json['thursday']) : null;
    tuesday =
    json['tuesday'] != null ? new Friday.fromJson(json['tuesday']) : null;
    updatedAt = json['updatedAt'];
    wednesday = json['wednesday'] != null
        ? new Friday.fromJson(json['wednesday'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['__v'] = this.iV;
    data['businessProfileId'] = this.businessProfileId;
    data['createdAt'] = this.createdAt;
    if (this.friday != null) {
      data['friday'] = this.friday!.toJson();
    }
    if (this.monday != null) {
      data['monday'] = this.monday!.toJson();
    }
    if (this.saturday != null) {
      data['saturday'] = this.saturday!.toJson();
    }
    if (this.sunday != null) {
      data['sunday'] = this.sunday!.toJson();
    }
    if (this.thursday != null) {
      data['thursday'] = this.thursday!.toJson();
    }
    if (this.tuesday != null) {
      data['tuesday'] = this.tuesday!.toJson();
    }
    data['updatedAt'] = this.updatedAt;
    if (this.wednesday != null) {
      data['wednesday'] = this.wednesday!.toJson();
    }
    return data;
  }
}

class Friday {
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Friday({this.isOpen, this.openTime, this.closeTime});

  Friday.fromJson(Map<String, dynamic> json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isOpen'] = this.isOpen;
    data['openTime'] = this.openTime;
    data['closeTime'] = this.closeTime;
    return data;
  }
}

class ContactUs {
  Branch? branch;
  String? sId;
  String? userId;
  String? businessProfileId;
  String? name;
  String? websiteUrl;
  Location? location;
  String? department;
  String? email;
  String? contactNumber;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<Department>? departments;

  ContactUs({this.branch,
    this.sId,
    this.userId,
    this.businessProfileId,
    this.name,
    this.websiteUrl,
    this.location,
    this.department,
    this.email,
    this.contactNumber,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.departments});

  ContactUs.fromJson(Map<String, dynamic> json) {
    branch =
    json['branch'] != null ? new Branch.fromJson(json['branch']) : null;
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    name = json['name'];
    websiteUrl = json['websiteUrl'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    department = json['department'];
    email = json['email'];
    contactNumber = json['contactNumber'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    if (json['departments'] != null) {
      departments = <Department>[];
      json['departments'].forEach((v) {
        departments!.add(new Department.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.branch != null) {
      data['branch'] = this.branch!.toJson();
    }
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['name'] = this.name;
    data['websiteUrl'] = this.websiteUrl;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['department'] = this.department;
    data['email'] = this.email;
    data['contactNumber'] = this.contactNumber;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.departments != null) {
      data['departments'] = this.departments!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Branch {
  Location? location;

  Branch({this.location});

  Branch.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    return data;
  }
}
