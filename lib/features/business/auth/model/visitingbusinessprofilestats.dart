class VisitBusinessProfileStatsModel {
  final bool success;
  final BusinessData data;

  VisitBusinessProfileStatsModel({
    required this.success,
    required this.data,
  });

  factory VisitBusinessProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return VisitBusinessProfileStatsModel(
      success: json['success'] as bool,
      data: BusinessData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class BusinessData {
  final String businessId;
  final String avgRating;
  final int totalRatings;
  final int count;
  final int totalUniqueViews;
  final int inquiries;

  BusinessData({
    required this.businessId,
    required this.avgRating,
    required this.totalRatings,
    required this.count,
    required this.totalUniqueViews,
    required this.inquiries,
  });

  factory BusinessData.fromJson(Map<String, dynamic> json) {
    return BusinessData(
      businessId: json['businessId'] as String,
      avgRating: json['avg_rating'] as String,
      totalRatings: json['total_ratings'] as int,
      count: json['count'] as int,
      totalUniqueViews: json['totalUniqueViews'] as int,
      inquiries: json['inquiries'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'avg_rating': avgRating,
      'total_ratings': totalRatings,
      'count': count,
      'totalUniqueViews': totalUniqueViews,
      'inquiries': inquiries,
    };
  }
}