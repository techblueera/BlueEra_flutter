import 'dart:convert';
GetJourneyDetailsModel getJourneyDetailsModelFromJson(String str) => GetJourneyDetailsModel.fromJson(json.decode(str));
String getJourneyDetailsModelToJson(GetJourneyDetailsModel data) => json.encode(data.toJson());
class GetJourneyDetailsModel {
  GetJourneyDetailsModel({
      this.success, 
      this.type, 
      this.data,});

  GetJourneyDetailsModel.fromJson(dynamic json) {
    success = json['success'];
    type = json['type'];
    data = json['data'] != null ? JourneyData.fromJson(json['data']) : null;
  }
  bool? success;
  String? type;
  JourneyData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['type'] = type;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

JourneyData dataFromJson(String str) => JourneyData.fromJson(json.decode(str));
String dataToJson(JourneyData data) => json.encode(data.toJson());
class JourneyData {
  JourneyData({
      this.id, 
      this.userId, 
      this.startFrom, 
      this.stoppages, 
      this.startVia, 
      this.transportInfo, 
      this.description, 
      this.isEnded, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  JourneyData.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['user_id'];
    startFrom = json['start_from'] != null ? StartFrom.fromJson(json['start_from']) : null;
    if (json['stoppages'] != null) {
      stoppages = [];
      json['stoppages'].forEach((v) {
        stoppages?.add(Stoppages.fromJson(v));
      });
    }
    startVia = json['start_via'];
    transportInfo = json['transport_info'];
    description = json['description'];
    isEnded = json['is_ended'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  StartFrom? startFrom;
  List<Stoppages>? stoppages;
  String? startVia;
  String? transportInfo;
  String? description;
  bool? isEnded;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['user_id'] = userId;
    if (startFrom != null) {
      map['start_from'] = startFrom?.toJson();
    }
    if (stoppages != null) {
      map['stoppages'] = stoppages?.map((v) => v.toJson()).toList();
    }
    map['start_via'] = startVia;
    map['transport_info'] = transportInfo;
    map['description'] = description;
    map['is_ended'] = isEnded;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Stoppages stoppagesFromJson(String str) => Stoppages.fromJson(json.decode(str));
String stoppagesToJson(Stoppages data) => json.encode(data.toJson());
class Stoppages {
  Stoppages({
      this.location, 
      this.places,});

  Stoppages.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    places = json['places'] != null ? json['places'].cast<String>() : [];
  }
  Location? location;
  List<String>? places;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['places'] = places;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.city, 
      this.latitude, 
      this.longitude,});

  Location.fromJson(dynamic json) {
    city = json['city'];
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  String? city;
  double? latitude;
  double? longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['city'] = city;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    return map;
  }

}

StartFrom startFromFromJson(String str) => StartFrom.fromJson(json.decode(str));
String startFromToJson(StartFrom data) => json.encode(data.toJson());
class StartFrom {
  StartFrom({
      this.city, 
      this.latitude, 
      this.longitude,});

  StartFrom.fromJson(dynamic json) {
    city = json['city'];
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  String? city;
  double? latitude;
  double? longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['city'] = city;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    return map;
  }

}