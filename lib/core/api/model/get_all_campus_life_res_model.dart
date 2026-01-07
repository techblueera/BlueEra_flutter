import 'dart:convert';
GetAllCampusLifeResModel getAllCampusLifeResModelFromJson(String str) => GetAllCampusLifeResModel.fromJson(json.decode(str));
String getAllCampusLifeResModelToJson(GetAllCampusLifeResModel data) => json.encode(data.toJson());
class GetAllCampusLifeResModel {
  GetAllCampusLifeResModel({
      this.success,
      this.data,
      this.count,});

  GetAllCampusLifeResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(GetAllCampusLifeData.fromJson(v));
      });
    }
    count = json['count'];
  }
  bool? success;
  List<GetAllCampusLifeData>? data;
  int? count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['count'] = count;
    return map;
  }

}

class GetAllCampusLifeData {
  String? id;
  String? name;
  List<Subcategories>? subcategories;

  GetAllCampusLifeData({this.id, this.name, this.subcategories});

  GetAllCampusLifeData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    if (json['subcategories'] != null) {
      subcategories = [];
      json['subcategories'].forEach((v) {
        subcategories?.add(Subcategories.fromJson(v));
      });
    }
  }

  // Add this method to fix the error
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    if (subcategories != null) {
      map['subcategories'] = subcategories?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Subcategories {
  String? id;
  String? name;
  String? type;
  List<Entries>? entries;

  Subcategories({this.id, this.name, this.type, this.entries});

  Subcategories.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
    if (json['entries'] != null) {
      entries = [];
      json['entries'].forEach((v) {
        entries?.add(Entries.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    if (entries != null) {
      map['entries'] = entries?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Entries {
  String? id;
  List<Images>? images;

  Entries({this.id, this.images});

  Entries.fromJson(dynamic json) {
    id = json['_id'];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Images {
  String? url;
  String? caption;
  String? id;

  Images({this.id,this.url, this.caption});

  Images.fromJson(dynamic json) {
    id = json['_id'];
    url = json['url'];
    caption = json['caption'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['url'] = url;
    map['caption'] = caption;
    return map;
  }
}
/*class GetAllCampusLifeData {
  String? id;
  String? name;
  List<Subcategory>? subcategories;

  GetAllCampusLifeData({this.id, this.name, this.subcategories});

  factory GetAllCampusLifeData.fromJson(Map<String, dynamic> json) {
    return GetAllCampusLifeData(
      id: json['_id'],
      name: json['name'],
      subcategories: (json['subcategories'] as List?)
          ?.map((e) => Subcategory.fromJson(e))
          .toList(),
    );
  }
}

class Subcategory {
  String? id;
  String? name;
  List<Entry>? entries;

  Subcategory({this.id, this.name, this.entries});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['_id'],
      name: json['name'],
      entries: (json['entries'] as List?)
          ?.map((e) => Entry.fromJson(e))
          .toList(),
    );
  }

  // Helper to get the very first image URL found in any entry
  String get firstImageUrl {
    if (entries != null && entries!.isNotEmpty) {
      for (var entry in entries!) {
        if (entry.images != null && entry.images!.isNotEmpty) {
          return entry.images!.first.url ?? "";
        }
      }
    }
    return "";
  }
}

class Entry {
  String? id;
  List<CampusImage>? images;

  Entry({this.id, this.images});

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['_id'],
      images: (json['images'] as List?)
          ?.map((e) => CampusImage.fromJson(e))
          .toList(),
    );
  }
}

class CampusImage {
  String? url;
  String? caption;

  CampusImage({this.url, this.caption});

  factory CampusImage.fromJson(Map<String, dynamic> json) {
    return CampusImage(
      url: json['url'],
      caption: json['caption'],
    );
  }
}*/

/*
GetAllCampusLifeData dataFromJson(String str) => GetAllCampusLifeData.fromJson(json.decode(str));
String dataToJson(GetAllCampusLifeData data) => json.encode(data.toJson());
class GetAllCampusLifeData {
  GetAllCampusLifeData({
      this.id, 
      this.name, 
      this.subcategories,});

  GetAllCampusLifeData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    if (json['subcategories'] != null) {
      subcategories = [];
      json['subcategories'].forEach((v) {
        subcategories?.add(Subcategories.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  List<Subcategories>? subcategories;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    if (subcategories != null) {
      map['subcategories'] = subcategories?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Subcategories subcategoriesFromJson(String str) => Subcategories.fromJson(json.decode(str));
String subcategoriesToJson(Subcategories data) => json.encode(data.toJson());
class Subcategories {
  Subcategories({
      this.id, 
      this.name, 
      this.type, 
      this.entries,});

  Subcategories.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
    if (json['entries'] != null) {
      entries = [];
      json['entries'].forEach((v) {
        entries?.add(Entries.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? type;
  List<Entries>? entries;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    if (entries != null) {
      map['entries'] = entries?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Entries entriesFromJson(String str) => Entries.fromJson(json.decode(str));
String entriesToJson(Entries data) => json.encode(data.toJson());
class Entries {
  Entries({
      this.id, 
      this.images,});

  Entries.fromJson(dynamic json) {
    id = json['_id'];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(Images.fromJson(v));
      });
    }
  }
  String? id;
  List<Images>? images;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
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
      this.createdAt,});

  Images.fromJson(dynamic json) {
    url = json['url'];
    caption = json['caption'];
    id = json['_id'];
    createdAt = json['createdAt'];
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

}*/
