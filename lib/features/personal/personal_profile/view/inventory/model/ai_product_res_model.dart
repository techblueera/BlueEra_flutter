class AiProductResModel {
  bool? success;
  String? message;
  AiProductResData? data;

  AiProductResModel({this.success, this.message, this.data});

  AiProductResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new AiProductResData.fromJson(json['data']) : null;
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

class AiProductResData {
  String? name;
  String? profileName;
  String? address;
  String? websiteUrl;
  double? rating;
  String? timing;
  String? description;
  ContactInfo? contactInfo;
  AboutUs? aboutUs;
  List<Products>? products;
  List<String>? gallery;
  String? privacyPolicy;
  String? termsConditions;
  List<Careers>? careers;
  List<Announcements>? announcements;
  dynamic locationReq;


  AiProductResData(
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

  AiProductResData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    profileName = json['profileName'];
    address = json['address'];
    websiteUrl = json['websiteUrl'];
    rating = json['rating'];
    timing = json['timing'];
    description = json['description'];
    contactInfo = json['contactInfo'] != null
        ? new ContactInfo.fromJson(json['contactInfo'])
        : null;
    aboutUs =
    json['aboutUs'] != null ? new AboutUs.fromJson(json['aboutUs']) : null;
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
    gallery = json['gallery'].cast<String>();
    privacyPolicy = json['privacyPolicy'];
    termsConditions = json['termsConditions'];
    if (json['careers'] != null) {
      careers = <Careers>[];
      json['careers'].forEach((v) {
        careers!.add(new Careers.fromJson(v));
      });
    }
    if (json['announcements'] != null) {
      announcements = <Announcements>[];
      json['announcements'].forEach((v) {
        announcements!.add(new Announcements.fromJson(v));
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

class ContactInfo {
  String? phone;
  String? email;

  ContactInfo({this.phone, this.email});

  ContactInfo.fromJson(Map<String, dynamic> json) {
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

class AboutUs {
  String? organisation;
  List<Management>? management;
  List<Staffs>? staffs;
  List<String>? officeFacility;

  AboutUs(
      {this.organisation, this.management, this.staffs, this.officeFacility});

  AboutUs.fromJson(Map<String, dynamic> json) {
    organisation = json['organisation'];
    if (json['management'] != null) {
      management = <Management>[];
      json['management'].forEach((v) {
        management!.add(new Management.fromJson(v));
      });
    }
    if (json['staffs'] != null) {
      staffs = <Staffs>[];
      json['staffs'].forEach((v) {
        staffs!.add(new Staffs.fromJson(v));
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

class Management {
  String? name;
  String? designation;
  String? bio;

  Management({this.name, this.designation, this.bio});

  Management.fromJson(Map<String, dynamic> json) {
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

class Staffs {
  String? name;
  String? role;

  Staffs({this.name, this.role});

  Staffs.fromJson(Map<String, dynamic> json) {
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

class Products {
  String? title;
  String? price;
  String? description;

  Products({this.title, this.price, this.description});

  Products.fromJson(Map<String, dynamic> json) {
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

class Careers {
  String? title;
  String? type;
  String? description;

  Careers({this.title, this.type, this.description});

  Careers.fromJson(Map<String, dynamic> json) {
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

class Announcements {
  String? title;
  String? date;
  String? content;

  Announcements({this.title, this.date, this.content});

  Announcements.fromJson(Map<String, dynamic> json) {
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