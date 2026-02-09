class SocialActivityResModel {
  bool? success;
  List<SocialActivityData>? data;

  SocialActivityResModel({this.success, this.data});

  SocialActivityResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <SocialActivityData>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(SocialActivityData.fromJson(v));
        });
      } else if (json['data'] is Map<String, dynamic>) {
        data!.add(SocialActivityData.fromJson(json['data']));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SocialActivityData {
  Location? location;
  String? sId;
  String? userId;
  String? title;
  String? description;
  String? mediaType;
  String? mediaUrl;
  String? activityType;
  String? date;
  String? role;
  String? organisationName;
  String? impact;
  String? createdAt;
  String? updatedAt;
  int? iV;

  SocialActivityData(
      {this.location,
      this.sId,
      this.userId,
      this.title,
      this.description,
      this.mediaType,
      this.mediaUrl,
      this.activityType,
      this.date,
      this.role,
      this.organisationName,
      this.impact,
      this.createdAt,
      this.updatedAt,
      this.iV});

  SocialActivityData.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    sId = json['_id'];
    userId = json['userId'];
    title = json['title'];
    description = json['description'];
    mediaType = json['mediaType'];
    mediaUrl = json['mediaUrl'];
    activityType = json['activityType'];
    date = json['date'];
    role = json['role'];
    organisationName = json['organisationName'];
    impact = json['impact'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['_id'] = sId;
    data['userId'] = userId;
    data['title'] = title;
    data['description'] = description;
    data['mediaType'] = mediaType;
    data['mediaUrl'] = mediaUrl;
    data['activityType'] = activityType;
    data['date'] = date;
    data['role'] = role;
    data['organisationName'] = organisationName;
    data['impact'] = impact;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }
}
