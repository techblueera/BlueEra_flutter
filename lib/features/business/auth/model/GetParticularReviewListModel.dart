/// status : true
/// data : {"stringValue":"\"rating\"","valueType":"string","kind":"ObjectId","value":"rating","path":"_id","reason":{},"name":"CastError","message":"Cast to ObjectId failed for value \"rating\" (type string) at path \"_id\" for model \"Business\""}
/// relatedStores : [{"_id":"68789fc9aa4ac9bccc0aa307","user_id":null,"business_description":"We provide logistics and warehousing solutions.","avg_rating":null,"total_ratings":0,"total_views":0}]

class GetParticularReviewListModel {
  GetParticularReviewListModel({
      this.status, 
      this.data, 
      this.relatedStores,});

  GetParticularReviewListModel.fromJson(dynamic json) {
    status = json['status'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    if (json['relatedStores'] != null) {
      relatedStores = [];
      json['relatedStores'].forEach((v) {
        relatedStores?.add(RelatedStores.fromJson(v));
      });
    }
  }
  bool? status;
  Data? data;
  List<RelatedStores>? relatedStores;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    if (relatedStores != null) {
      map['relatedStores'] = relatedStores?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "68789fc9aa4ac9bccc0aa307"
/// user_id : null
/// business_description : "We provide logistics and warehousing solutions."
/// avg_rating : null
/// total_ratings : 0
/// total_views : 0

class RelatedStores {
  RelatedStores({
      this.id, 
      this.userId, 
      this.businessDescription, 
      this.avgRating, 
      this.totalRatings, 
      this.totalViews,});

  RelatedStores.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['user_id'];
    businessDescription = json['business_description'];
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
    totalViews = json['total_views'];
  }
  String? id;
  dynamic userId;
  String? businessDescription;
  dynamic avgRating;
  num? totalRatings;
  num? totalViews;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['user_id'] = userId;
    map['business_description'] = businessDescription;
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    map['total_views'] = totalViews;
    return map;
  }

}

/// stringValue : "\"rating\""
/// valueType : "string"
/// kind : "ObjectId"
/// value : "rating"
/// path : "_id"
/// reason : {}
/// name : "CastError"
/// message : "Cast to ObjectId failed for value \"rating\" (type string) at path \"_id\" for model \"Business\""

class Data {
  Data({
      this.stringValue, 
      this.valueType, 
      this.kind, 
      this.value, 
      this.path, 
      this.reason, 
      this.name, 
      this.message,});

  Data.fromJson(dynamic json) {
    stringValue = json['stringValue'];
    valueType = json['valueType'];
    kind = json['kind'];
    value = json['value'];
    path = json['path'];
    reason = json['reason'];
    name = json['name'];
    message = json['message'];
  }
  String? stringValue;
  String? valueType;
  String? kind;
  String? value;
  String? path;
  dynamic reason;
  String? name;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['stringValue'] = stringValue;
    map['valueType'] = valueType;
    map['kind'] = kind;
    map['value'] = value;
    map['path'] = path;
    map['reason'] = reason;
    map['name'] = name;
    map['message'] = message;
    return map;
  }

}