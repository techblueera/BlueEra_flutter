/// status : true
/// data : {"targetId":"68c433eefd8ad080d721818a","avg_rating":0,"total_ratings":0}

class VisitBusinessRatingSumModel {
  VisitBusinessRatingSumModel({
      this.status, 
      this.data,});

  VisitBusinessRatingSumModel.fromJson(dynamic json) {
    status = json['status'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? status;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

/// targetId : "68c433eefd8ad080d721818a"
/// avg_rating : 0
/// total_ratings : 0

class Data {
  Data({
      this.targetId, 
      this.avgRating, 
      this.totalRatings,});

  Data.fromJson(dynamic json) {
    targetId = json['targetId'];
    avgRating = (json['avg_rating']!=null)?double.parse(json['avg_rating'].toString()):0.0;
    totalRatings = json['total_ratings'];
  }
  String? targetId;
  double? avgRating;
  num? totalRatings;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['targetId'] = targetId;
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    return map;
  }

}