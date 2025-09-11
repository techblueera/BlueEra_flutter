class RatingSummaryResponse {
  final bool success;
  final RatingData data;

  RatingSummaryResponse({
    this.success = false,
    RatingData? data,
  }) : data = data ?? RatingData.empty();

  // Default constructor
  RatingSummaryResponse.empty() : this(success: false, data: RatingData.empty());

  // CopyWith constructor
  RatingSummaryResponse copyWith({
    bool? success,
    RatingData? data,
  }) {
    return RatingSummaryResponse(
      success: success ?? this.success,
      data: data ?? this.data,
    );
  }

  factory RatingSummaryResponse.fromJson(Map<String, dynamic> json) {
    return RatingSummaryResponse(
      success: json['success'] as bool,
      data: RatingData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class RatingData {
  final String businessId;
  final String avgRating;
  final int totalRatings;

  RatingData({
    this.businessId = "",
    this.avgRating = "0.00",
    this.totalRatings = 0,
  });

  // Default constructor
  RatingData.empty()
      : businessId = "",
        avgRating = "0.00",
        totalRatings = 0;

  // CopyWith constructor
  RatingData copyWith({
    String? businessId,
    String? avgRating,
    int? totalRatings,
  }) {
    return RatingData(
      businessId: businessId ?? this.businessId,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      businessId: json['businessId'] as String,
      avgRating: json['avg_rating'] as String,
      totalRatings: json['total_ratings'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'avg_rating': avgRating,
      'total_ratings': totalRatings,
    };
  }
}