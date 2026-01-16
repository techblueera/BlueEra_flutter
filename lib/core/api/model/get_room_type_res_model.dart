import 'dart:convert';
GetRoomTypeResModel getRoomTypeResModelFromJson(String str) => GetRoomTypeResModel.fromJson(json.decode(str));
String getRoomTypeResModelToJson(GetRoomTypeResModel data) => json.encode(data.toJson());
class GetRoomTypeResModel {
  GetRoomTypeResModel({
      this.success, 
      this.data,});

  GetRoomTypeResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? GetRoomTypeData.fromJson(json['data']) : null;
  }
  bool? success;
  GetRoomTypeData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

GetRoomTypeData dataFromJson(String str) => GetRoomTypeData.fromJson(json.decode(str));
String dataToJson(GetRoomTypeData data) => json.encode(data.toJson());
class GetRoomTypeData {
  GetRoomTypeData({
      this.id, 
      this.businessId, 
      this.standardRoom, 
      this.economyRoom, 
      this.deluxeRoom, 
      this.superDeluxeRoom, 
      this.premiumRoom, 
      this.executiveRoom, 
      this.familyRoom, 
      this.suiteRoom, 
      this.luxurySuite, 
      this.studioRoom, 
      this.villaCottage, 
      this.v,});

  GetRoomTypeData.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    standardRoom = json['standardRoom'];
    economyRoom = json['economyRoom'];
    deluxeRoom = json['deluxeRoom'];
    superDeluxeRoom = json['superDeluxeRoom'];
    premiumRoom = json['premiumRoom'];
    executiveRoom = json['executiveRoom'];
    familyRoom = json['familyRoom'];
    suiteRoom = json['suiteRoom'];
    luxurySuite = json['luxurySuite'];
    studioRoom = json['studioRoom'];
    villaCottage = json['villaCottage'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  bool? standardRoom;
  bool? economyRoom;
  bool? deluxeRoom;
  bool? superDeluxeRoom;
  bool? premiumRoom;
  bool? executiveRoom;
  bool? familyRoom;
  bool? suiteRoom;
  bool? luxurySuite;
  bool? studioRoom;
  bool? villaCottage;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['standardRoom'] = standardRoom;
    map['economyRoom'] = economyRoom;
    map['deluxeRoom'] = deluxeRoom;
    map['superDeluxeRoom'] = superDeluxeRoom;
    map['premiumRoom'] = premiumRoom;
    map['executiveRoom'] = executiveRoom;
    map['familyRoom'] = familyRoom;
    map['suiteRoom'] = suiteRoom;
    map['luxurySuite'] = luxurySuite;
    map['studioRoom'] = studioRoom;
    map['villaCottage'] = villaCottage;
    map['__v'] = v;
    return map;
  }

}