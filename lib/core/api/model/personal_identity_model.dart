class PersonalIdentityModel {
  bool? success;
  PersonalIdentityData? data;

  PersonalIdentityModel({this.success, this.data});

  PersonalIdentityModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? PersonalIdentityData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class PersonalIdentityData {
  IdentityLocation? location;
  String? sId;
  String? userId;
  int? iV;
  String? bio;
  String? createdAt;
  String? journey;
  String? updatedAt;
  String? familyBackground;

  PersonalIdentityData(
      {this.location,
      this.sId,
      this.userId,
      this.iV,
      this.bio,
      this.createdAt,
      this.journey,
      this.familyBackground,
      this.updatedAt});

  PersonalIdentityData.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? IdentityLocation.fromJson(json['location'])
        : null;
    sId = json['_id'];
    userId = json['userId'];
    iV = json['__v'];
    bio = json['bio'];
    createdAt = json['createdAt'];
    familyBackground = json['familyBackground'];
    journey = json['journey'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['_id'] = sId;
    data['userId'] = userId;
    data['__v'] = iV;
    data['bio'] = bio;
    data['createdAt'] = createdAt;
    data['journey'] = journey;
    data['updatedAt'] = updatedAt;
    data['familyBackground'] = familyBackground;
    return data;
  }
}

class IdentityLocation {
  String? name;
  String? type;
  List<double>? coordinates;

  IdentityLocation({this.name,this.type, this.coordinates});

  IdentityLocation.fromJson(Map<String, dynamic> json) {
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
