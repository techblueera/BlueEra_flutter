import 'dart:convert';

AiLabServiceModelRes aiLabServiceModelResFromJson(String str) =>
    AiLabServiceModelRes.fromJson(json.decode(str));

String aiLabServiceModelResToJson(AiLabServiceModelRes data) =>
    json.encode(data.toJson());

class AiLabServiceModelRes {
  AiLabServiceModelRes({
    this.success,
    this.data,
  });

  AiLabServiceModelRes.fromJson(dynamic json) {
    success = json['success'];
    data =
        json['data'] != null ? AiLabServiceData.fromJson(json['data']) : null;
  }

  bool? success;
  AiLabServiceData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

AiLabServiceData dataFromJson(String str) =>
    AiLabServiceData.fromJson(json.decode(str));

String dataToJson(AiLabServiceData data) => json.encode(data.toJson());

class AiLabServiceData {
  AiLabServiceData({
    this.aboutUs,
    this.featuredTest,
    this.popularServices,
    this.allServices,
    this.departments,
    this.packages,
    this.gallery,
    this.testimonials,
    this.contactUs,
  });

  AiLabServiceData.fromJson(dynamic json) {
    aboutUs =
        json['aboutUs'] != null ? AboutUs.fromJson(json['aboutUs']) : null;
    if (json['featuredTest'] != null) {
      featuredTest = [];
      json['featuredTest'].forEach((v) {
        featuredTest?.add(FeaturedTest.fromJson(v));
      });
    }
    if (json['popularServices'] != null) {
      popularServices = [];
      json['popularServices'].forEach((v) {
        popularServices?.add(PopularServices.fromJson(v));
      });
    }
    if (json['allServices'] != null) {
      allServices = [];
      json['allServices'].forEach((v) {
        allServices?.add(AllServices.fromJson(v));
      });
    }
    departments =
        json['departments'] != null ? json['departments'].cast<String>() : [];
    if (json['packages'] != null) {
      packages = [];
      json['packages'].forEach((v) {
        packages?.add(Packages.fromJson(v));
      });
    }
    gallery = json['gallery'] != null ? json['gallery'].cast<String>() : [];
    if (json['testimonials'] != null) {
      testimonials = [];
      json['testimonials'].forEach((v) {
        testimonials?.add(Testimonials.fromJson(v));
      });
    }
    contactUs = json['contactUs'] != null
        ? ContactUs.fromJson(json['contactUs'])
        : null;
  }

  AboutUs? aboutUs;
  List<FeaturedTest>? featuredTest;
  List<PopularServices>? popularServices;
  List<AllServices>? allServices;
  List<String>? departments;
  List<Packages>? packages;
  List<String>? gallery;
  List<Testimonials>? testimonials;
  ContactUs? contactUs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (aboutUs != null) {
      map['aboutUs'] = aboutUs?.toJson();
    }
    if (featuredTest != null) {
      map['featuredTest'] = featuredTest?.map((v) => v.toJson()).toList();
    }
    if (popularServices != null) {
      map['popularServices'] = popularServices?.map((v) => v.toJson()).toList();
    }
    if (allServices != null) {
      map['allServices'] = allServices?.map((v) => v.toJson()).toList();
    }
    map['departments'] = departments;
    if (packages != null) {
      map['packages'] = packages?.map((v) => v.toJson()).toList();
    }
    map['gallery'] = gallery;
    if (testimonials != null) {
      map['testimonials'] = testimonials?.map((v) => v.toJson()).toList();
    }
    if (contactUs != null) {
      map['contactUs'] = contactUs?.toJson();
    }
    return map;
  }
}

ContactUs contactUsFromJson(String str) => ContactUs.fromJson(json.decode(str));

String contactUsToJson(ContactUs data) => json.encode(data.toJson());

class ContactUs {
  ContactUs({
    this.reception,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.location,
  });

  ContactUs.fromJson(dynamic json) {
    reception = json['reception'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    website = json['website'];
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
  }

  String? reception;
  String? email;
  String? phone;
  String? address;
  String? website;
  Location? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['reception'] = reception;
    map['email'] = email;
    map['phone'] = phone;
    map['address'] = address;
    map['website'] = website;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    return map;
  }
}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));

String locationToJson(Location data) => json.encode(data.toJson());

class Location {
  Location({
    this.type,
    this.coordinates,
  });

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates =
        json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }

  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }
}

Testimonials testimonialsFromJson(String str) =>
    Testimonials.fromJson(json.decode(str));

String testimonialsToJson(Testimonials data) => json.encode(data.toJson());

class Testimonials {
  Testimonials({
    this.content,
    this.author,
    this.designation,
  });

  Testimonials.fromJson(dynamic json) {
    content = json['content'];
    author = json['author'];
    designation = json['designation'];
  }

  String? content;
  String? author;
  String? designation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = content;
    map['author'] = author;
    map['designation'] = designation;
    return map;
  }
}

Packages packagesFromJson(String str) => Packages.fromJson(json.decode(str));

String packagesToJson(Packages data) => json.encode(data.toJson());

class Packages {
  Packages({
    this.title,
    this.price,
  });

  Packages.fromJson(dynamic json) {
    title = json['title'];
    price = json['price'];
  }

  String? title;
  String? price;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['price'] = price;
    return map;
  }
}

AllServices allServicesFromJson(String str) =>
    AllServices.fromJson(json.decode(str));

String allServicesToJson(AllServices data) => json.encode(data.toJson());

class AllServices {
  AllServices({
    this.title,
    this.icon,
    this.price,
    this.reportTime,
  });

  AllServices.fromJson(dynamic json) {
    title = json['title'];
    icon = json['icon'];
    price = json['price'];
    reportTime = json['reportTime'];
  }

  String? title;
  String? icon;
  String? price;
  String? reportTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['icon'] = icon;
    map['price'] = price;
    map['reportTime'] = reportTime;
    return map;
  }
}

PopularServices popularServicesFromJson(String str) =>
    PopularServices.fromJson(json.decode(str));

String popularServicesToJson(PopularServices data) =>
    json.encode(data.toJson());

class PopularServices {
  PopularServices({
    this.title,
    this.image,
  });

  PopularServices.fromJson(dynamic json) {
    title = json['title'];
    image = json['image'];
  }

  String? title;
  String? image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['image'] = image;
    return map;
  }
}

FeaturedTest featuredTestFromJson(String str) =>
    FeaturedTest.fromJson(json.decode(str));

String featuredTestToJson(FeaturedTest data) => json.encode(data.toJson());

class FeaturedTest {
  FeaturedTest({
    this.title,
    this.parameters,
    this.reportTime,
    this.price,
    this.discountPrice,
    this.homeSampleCollection,
  });

  FeaturedTest.fromJson(dynamic json) {
    title = json['title'];
    parameters = json['parameters'];
    reportTime = json['reportTime'];
    price = json['price'];
    discountPrice = json['discountPrice'];
    homeSampleCollection = json['homeSampleCollection'];
  }

  String? title;
  String? parameters;
  String? reportTime;
  String? price;
  String? discountPrice;
  bool? homeSampleCollection;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['parameters'] = parameters;
    map['reportTime'] = reportTime;
    map['price'] = price;
    map['discountPrice'] = discountPrice;
    map['homeSampleCollection'] = homeSampleCollection;
    return map;
  }
}

AboutUs aboutUsFromJson(String str) => AboutUs.fromJson(json.decode(str));

String aboutUsToJson(AboutUs data) => json.encode(data.toJson());

class AboutUs {
  AboutUs({
    this.name,
    this.rating,
    this.description,
    this.timing,
    this.coverImage,
    this.history,
    this.mission,
    this.team,
  });

  AboutUs.fromJson(dynamic json) {
    name = json['name'];
    rating = json['rating'];
    description = json['description'];
    timing = json['timing'];
    coverImage = json['coverImage'];
    history = json['history'];
    mission = json['mission'];
    if (json['team'] != null) {
      team = [];
      json['team'].forEach((v) {
        team?.add(Team.fromJson(v));
      });
    }
  }

  String? name;
  double? rating;
  String? description;
  String? timing;
  String? coverImage;
  String? history;
  String? mission;
  List<Team>? team;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['rating'] = rating;
    map['description'] = description;
    map['timing'] = timing;
    map['coverImage'] = coverImage;
    map['history'] = history;
    map['mission'] = mission;
    if (team != null) {
      map['team'] = team?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Team teamFromJson(String str) => Team.fromJson(json.decode(str));

String teamToJson(Team data) => json.encode(data.toJson());

class Team {
  Team({
    this.name,
    this.designation,
    this.photo,
  });

  Team.fromJson(dynamic json) {
    name = json['name'];
    designation = json['designation'];
    photo = json['photo'];
  }

  String? name;
  String? designation;
  String? photo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['designation'] = designation;
    map['photo'] = photo;
    return map;
  }
}
