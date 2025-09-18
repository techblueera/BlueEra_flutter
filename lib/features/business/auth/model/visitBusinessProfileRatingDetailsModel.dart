/// status : true
/// data : {"avg_rating":0,"total_ratings":0,"ratingCounts":[{"rating":5,"count":0},{"rating":4,"count":0},{"rating":3,"count":0},{"rating":2,"count":0},{"rating":1,"count":0}]}

class VisitBusinessProfileRatingDetailsModel {
  VisitBusinessProfileRatingDetailsModel({
      this.status, 
      this.data,});

  VisitBusinessProfileRatingDetailsModel.fromJson(dynamic json) {
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

/// avg_rating : 0
/// total_ratings : 0
/// ratingCounts : [{"rating":5,"count":0},{"rating":4,"count":0},{"rating":3,"count":0},{"rating":2,"count":0},{"rating":1,"count":0}]

class Data {
  Data({
      this.avgRating, 
      this.totalRatings, 
      this.ratingCounts,});

  Data.fromJson(dynamic json) {
    avgRating = (json['avg_rating']!=null)?double.parse(json['avg_rating'].toString()):0.0;
    totalRatings = json['total_ratings'];
    if (json['ratingCounts'] != null) {
      ratingCounts = [];
      json['ratingCounts'].forEach((v) {
        ratingCounts?.add(RatingCounts.fromJson(v));
      });
    }
  }
  double? avgRating;
  num? totalRatings;
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

/// rating : 5
/// count : 0

class RatingCounts {
  RatingCounts({
      this.rating, 
      this.count,});

  RatingCounts.fromJson(dynamic json) {
    rating = (json['rating']!=null)?int.parse( json['rating'].toString()):0;
    count =( json['count']!=null)?double.parse( json['count'].toString()):0.0;
  }
  int? rating;
  double? count;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['rating'] = rating;
    map['count'] = count;
    return map;
  }

}