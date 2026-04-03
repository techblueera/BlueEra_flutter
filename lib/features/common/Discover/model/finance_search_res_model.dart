class FinanceSearchResModel {
  bool? success;
  List<FinanceBusinessItem>? data;

  FinanceSearchResModel({this.success, this.data});

  FinanceSearchResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <FinanceBusinessItem>[];
      json['data'].forEach((v) {
        data!.add(FinanceBusinessItem.fromJson(v));
      });
    }
  }
}

class FinanceBusinessItem {
  String? id;
  String? userId;
  String? profileName;
  String? description;
  String? logoUrl;
  String? coverUrl;
  String? type;
  String? category;
  FinanceLocation? location;
  List<FinanceContactUs>? contactUs;
  List<FinanceAboutOrganisation>? aboutOrganisation;
  List<FinanceStaff>? staff;
  List<FinanceBlog>? blogs;
  List<FinanceGallery>? gallery;
  String? createdAt;
  String? updatedAt;

  FinanceBusinessItem({
    this.id,
    this.userId,
    this.profileName,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.type,
    this.category,
    this.location,
    this.contactUs,
    this.aboutOrganisation,
    this.staff,
    this.blogs,
    this.gallery,
    this.createdAt,
    this.updatedAt,
  });

  FinanceBusinessItem.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    userId = json['userId'];
    profileName = json['profileName'];
    description = json['description'];
    logoUrl = json['logoUrl']?.toString().trim();
    coverUrl = json['coverUrl']?.toString().trim();
    type = json['type'];
    category = json['category'];
    location = json['location'] != null
        ? FinanceLocation.fromJson(json['location'])
        : null;
    if (json['contactUs'] != null) {
      contactUs = <FinanceContactUs>[];
      json['contactUs'].forEach((v) {
        contactUs!.add(FinanceContactUs.fromJson(v));
      });
    }
    if (json['aboutOrganisation'] != null) {
      aboutOrganisation = <FinanceAboutOrganisation>[];
      json['aboutOrganisation'].forEach((v) {
        aboutOrganisation!.add(FinanceAboutOrganisation.fromJson(v));
      });
    }
    if (json['staff'] != null) {
      staff = <FinanceStaff>[];
      json['staff'].forEach((v) {
        staff!.add(FinanceStaff.fromJson(v));
      });
    }
    if (json['blogs'] != null) {
      blogs = <FinanceBlog>[];
      json['blogs'].forEach((v) {
        blogs!.add(FinanceBlog.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = <FinanceGallery>[];
      json['gallery'].forEach((v) {
        gallery!.add(FinanceGallery.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}

class FinanceLocation {
  String? name;
  String? address;
  List<double>? coordinates;

  FinanceLocation({this.name, this.address, this.coordinates});

  FinanceLocation.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    if (json['coordinates'] != null) {
      coordinates = List<double>.from(
          json['coordinates'].map((x) => (x as num).toDouble()));
    }
  }
}

class FinanceContactUs {
  String? id;
  FinanceBranch? branch;
  List<FinanceDepartment>? departments;

  FinanceContactUs({this.id, this.branch, this.departments});

  FinanceContactUs.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    branch = json['branch'] != null
        ? FinanceBranch.fromJson(json['branch'])
        : null;
    if (json['departments'] != null) {
      departments = <FinanceDepartment>[];
      json['departments'].forEach((v) {
        departments!.add(FinanceDepartment.fromJson(v));
      });
    }
  }
}

class FinanceBranch {
  FinanceLocation? location;
  String? name;
  String? website;

  FinanceBranch({this.location, this.name, this.website});

  FinanceBranch.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? FinanceLocation.fromJson(json['location'])
        : null;
    name = json['name'];
    website = json['website'];
  }
}

class FinanceDepartment {
  String? id;
  String? department;
  String? role;
  String? email;
  String? phone;

  FinanceDepartment({this.id, this.department, this.role, this.email, this.phone});

  FinanceDepartment.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    department = json['department'];
    role = json['role'];
    email = json['email'];
    phone = json['phone'];
  }
}

class FinanceAboutOrganisation {
  String? id;
  String? imageUrl;
  String? title;
  String? description;

  FinanceAboutOrganisation({this.id, this.imageUrl, this.title, this.description});

  FinanceAboutOrganisation.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    imageUrl = json['imageUrl']?.toString().trim();
    title = json['title'];
    description = json['description'];
  }
}

class FinanceStaff {
  String? id;
  String? name;
  String? position;
  String? qualification;
  String? imageUrl;

  FinanceStaff({this.id, this.name, this.position, this.qualification, this.imageUrl});

  FinanceStaff.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    imageUrl = json['imageUrl']?.toString().trim();
  }
}

class FinanceBlog {
  String? id;
  String? imageUrl;
  String? title;
  String? blog;

  FinanceBlog({this.id, this.imageUrl, this.title, this.blog});

  FinanceBlog.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    imageUrl = json['imageUrl']?.toString().trim();
    title = json['title'];
    blog = json['blog'];
  }
}

class FinanceGallery {
  String? id;
  String? title;
  List<String>? imageUrls;

  FinanceGallery({this.id, this.title, this.imageUrls});

  FinanceGallery.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    title = json['title'];
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(
          json['imageUrls'].map((x) => x.toString().trim()));
    }
  }
}
