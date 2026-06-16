class AutomotiveAiProductResModel {
  bool? success;
  String? message;
  AutomotiveAiProductResData? data;

  AutomotiveAiProductResModel({this.success, this.message, this.data});

  AutomotiveAiProductResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new AutomotiveAiProductResData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class AutomotiveAiProductResData {
  String? name;
  String? profileName;
  String? address;
  String? websiteUrl;
  double? rating;
  String? timing;
  String? description;
  AutomotiveContactInfo? contactInfo;
  AutomotiveAboutUs? aboutUs;
  List<AutomotiveProducts>? products;
  List<String>? gallery;
  String? privacyPolicy;
  String? termsConditions;
  List<AutomotiveCareers>? careers;
  List<AutomotiveAnnouncements>? announcements;
  dynamic locationReq;


  AutomotiveAiProductResData(
      {this.name,
        this.profileName,
        this.address,
        this.websiteUrl,
        this.rating,
        this.timing,
        this.description,
        this.contactInfo,
        this.aboutUs,
        this.products,
        this.gallery,
        this.privacyPolicy,
        this.termsConditions,
        this.careers,
        this.announcements,
        this.locationReq,
      });

  AutomotiveAiProductResData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    profileName = json['profileName'];
    address = json['address'];
    websiteUrl = json['websiteUrl'];
    rating = json['rating'];
    timing = json['timing'];
    description = json['description'];
    contactInfo = json['contactInfo'] != null
        ? new AutomotiveContactInfo.fromJson(json['contactInfo'])
        : null;
    aboutUs =
    json['aboutUs'] != null ? new AutomotiveAboutUs.fromJson(json['aboutUs']) : null;
    if (json['products'] != null) {
      products = <AutomotiveProducts>[];
      json['products'].forEach((v) {
        products!.add(new AutomotiveProducts.fromJson(v));
      });
    }
    gallery = json['gallery'].cast<String>();
    privacyPolicy = json['privacyPolicy'];
    termsConditions = json['termsConditions'];
    if (json['careers'] != null) {
      careers = <AutomotiveCareers>[];
      json['careers'].forEach((v) {
        careers!.add(new AutomotiveCareers.fromJson(v));
      });
    }
    if (json['announcements'] != null) {
      announcements = <AutomotiveAnnouncements>[];
      json['announcements'].forEach((v) {
        announcements!.add(new AutomotiveAnnouncements.fromJson(v));
      });
    }
    locationReq = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['profileName'] = profileName;
    data['address'] = this.address;
    data['websiteUrl'] = this.websiteUrl;
    data['rating'] = this.rating;
    data['timing'] = this.timing;
    data['description'] = this.description;
    if (this.contactInfo != null) {
      data['contactInfo'] = this.contactInfo!.toJson();
    }
    if (this.aboutUs != null) {
      data['aboutUs'] = this.aboutUs!.toJson();
    }
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    data['gallery'] = this.gallery;
    data['privacyPolicy'] = this.privacyPolicy;
    data['termsConditions'] = this.termsConditions;
    if (this.careers != null) {
      data['careers'] = this.careers!.map((v) => v.toJson()).toList();
    }
    if (this.announcements != null) {
      data['announcements'] =
          this.announcements!.map((v) => v.toJson()).toList();
    }
    data['location'] = locationReq;
    return data;
  }
}

class AutomotiveContactInfo {
  String? phone;
  String? email;

  AutomotiveContactInfo({this.phone, this.email});

  AutomotiveContactInfo.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['phone'] = this.phone;
    data['email'] = this.email;
    return data;
  }
}

class AutomotiveAboutUs {
  String? organisation;
  List<AutomotiveManagement>? management;
  List<AutomotiveStaffs>? staffs;
  List<String>? officeFacility;

  AutomotiveAboutUs(
      {this.organisation, this.management, this.staffs, this.officeFacility});

  AutomotiveAboutUs.fromJson(Map<String, dynamic> json) {
    organisation = json['organisation'];
    if (json['management'] != null) {
      management = <AutomotiveManagement>[];
      json['management'].forEach((v) {
        management!.add(new AutomotiveManagement.fromJson(v));
      });
    }
    if (json['staffs'] != null) {
      staffs = <AutomotiveStaffs>[];
      json['staffs'].forEach((v) {
        staffs!.add(new AutomotiveStaffs.fromJson(v));
      });
    }
    officeFacility = json['officeFacility'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['organisation'] = this.organisation;
    if (this.management != null) {
      data['management'] = this.management!.map((v) => v.toJson()).toList();
    }
    if (this.staffs != null) {
      data['staffs'] = this.staffs!.map((v) => v.toJson()).toList();
    }
    data['officeFacility'] = this.officeFacility;
    return data;
  }
}

class AutomotiveManagement {
  String? name;
  String? designation;
  String? bio;

  AutomotiveManagement({this.name, this.designation, this.bio});

  AutomotiveManagement.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    designation = json['designation'];
    bio = json['bio'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['designation'] = this.designation;
    data['bio'] = this.bio;
    return data;
  }
}

class AutomotiveStaffs {
  String? name;
  String? role;

  AutomotiveStaffs({this.name, this.role});

  AutomotiveStaffs.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['role'] = this.role;
    return data;
  }
}

class AutomotiveProducts {
  String? title;
  String? price;
  String? description;

  AutomotiveProducts({this.title, this.price, this.description});

  AutomotiveProducts.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    price = json['price'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['price'] = this.price;
    data['description'] = this.description;
    return data;
  }
}

class AutomotiveCareers {
  String? title;
  String? type;
  String? description;

  AutomotiveCareers({this.title, this.type, this.description});

  AutomotiveCareers.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    type = json['type'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['type'] = this.type;
    data['description'] = this.description;
    return data;
  }
}

class AutomotiveAnnouncements {
  String? title;
  String? date;
  String? content;

  AutomotiveAnnouncements({this.title, this.date, this.content});

  AutomotiveAnnouncements.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    date = json['date'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['date'] = this.date;
    data['content'] = this.content;
    return data;
  }
}