import 'dart:convert';
RatingDetailsResModel ratingDetailsResModelFromJson(String str) => RatingDetailsResModel.fromJson(json.decode(str));
String ratingDetailsResModelToJson(RatingDetailsResModel data) => json.encode(data.toJson());
class RatingDetailsResModel {
  RatingDetailsResModel({
      this.status, 
      this.data,});

  RatingDetailsResModel.fromJson(dynamic json) {
    status = json['status'];
    data = json['data'] != null ? RatingDetailsData.fromJson(json['data']) : null;
  }
  bool? status;
  RatingDetailsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

RatingDetailsData dataFromJson(String str) => RatingDetailsData.fromJson(json.decode(str));
String dataToJson(RatingDetailsData data) => json.encode(data.toJson());
class RatingDetailsData {
  RatingDetailsData({
      this.avgRating, 
      this.totalRatings, 
      this.ratingCounts,});

  RatingDetailsData.fromJson(dynamic json) {
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
    if (json['ratingCounts'] != null) {
      ratingCounts = [];
      json['ratingCounts'].forEach((v) {
        ratingCounts?.add(RatingCounts.fromJson(v));
      });
    }
  }
  int? avgRating;
  int? totalRatings;
  List<RatingCounts>? ratingCounts;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    if (ratingCounts != null) {
      map['ratingCounts'] = ratingCounts?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

RatingCounts ratingCountsFromJson(String str) => RatingCounts.fromJson(json.decode(str));
String ratingCountsToJson(RatingCounts data) => json.encode(data.toJson());
class RatingCounts {
  RatingCounts({
      this.rating, 
      this.count,});

  RatingCounts.fromJson(dynamic json) {
    rating = json['rating'];
    count = json['count'];
  }
  int? rating;
  int? count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['rating'] = rating;
    map['count'] = count;
    return map;
  }

}