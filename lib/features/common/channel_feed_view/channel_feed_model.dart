import 'dart:convert';
ChannelFeedModel channelFeedModelFromJson(String str) => ChannelFeedModel.fromJson(json.decode(str));
String channelFeedModelToJson(ChannelFeedModel data) => json.encode(data.toJson());
class ChannelFeedModel {
  ChannelFeedModel({
      this.success, 
      this.message, 
      this.data, 
      this.pagination,});

  ChannelFeedModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ChannelFeedData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  String? message;
  List<ChannelFeedData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }

}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());
class Pagination {
  Pagination({
      this.page, 
      this.limit, 
      this.total, 
      this.totalPages,});

  Pagination.fromJson(dynamic json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
  }
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['page'] = page;
    map['limit'] = limit;
    map['total'] = total;
    map['totalPages'] = totalPages;
    return map;
  }

}

ChannelFeedData dataFromJson(String str) => ChannelFeedData.fromJson(json.decode(str));
String dataToJson(ChannelFeedData data) => json.encode(data.toJson());
class ChannelFeedData {
  ChannelFeedData({
      this.ownership, 
      this.id, 
      this.name,});

  ChannelFeedData.fromJson(dynamic json) {
    ownership = json['ownership'] != null ? Ownership.fromJson(json['ownership']) : null;
    id = json['_id'];
    name = json['name'];
  }
  Ownership? ownership;
  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (ownership != null) {
      map['ownership'] = ownership?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    return map;
  }

}

Ownership ownershipFromJson(String str) => Ownership.fromJson(json.decode(str));
String ownershipToJson(Ownership data) => json.encode(data.toJson());
class Ownership {
  Ownership({
      this.claimedBy, 
      this.claimedAt,});

  Ownership.fromJson(dynamic json) {
    claimedBy = json['claimedBy'];
    claimedAt = json['claimedAt'];
  }
  String? claimedBy;
  String? claimedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['claimedBy'] = claimedBy;
    map['claimedAt'] = claimedAt;
    return map;
  }

}