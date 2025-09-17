/// status : true
/// data : [{"rating":1,"count":0},{"rating":2,"count":0},{"rating":3,"count":0},{"rating":4,"count":0},{"rating":5,"count":0}]

class VisitBusinessDetailedRatingModel {
  VisitBusinessDetailedRatingModel({
      this.status, 
      this.data,});

  VisitBusinessDetailedRatingModel.fromJson(dynamic json) {
    status = json['status'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(RatingCountsListModel.fromJson(v));
      });
    }
  }
  bool? status;
  List<RatingCountsListModel>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// rating : 1
/// count : 0

class RatingCountsListModel {
  RatingCountsListModel({
      this.rating, 
      this.count,});

  RatingCountsListModel.fromJson(dynamic json) {
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