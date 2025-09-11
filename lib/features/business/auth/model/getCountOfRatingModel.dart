class RatingDistributionResponse {
  final bool success;
  final List<RatingDistribution> data;

  RatingDistributionResponse({
    this.success = false,
    List<RatingDistribution>? data,
  }) : data = data ?? [];

  // Default constructor
  RatingDistributionResponse.empty() : this(success: false, data: []);

  // CopyWith constructor
  RatingDistributionResponse copyWith({
    bool? success,
    List<RatingDistribution>? data,
  }) {
    return RatingDistributionResponse(
      success: success ?? this.success,
      data: data ?? this.data,
    );
  }

  factory RatingDistributionResponse.fromJson(Map<String, dynamic> json) {
    return RatingDistributionResponse(
      success: json['success'] as bool,
      data: (json['data'] as List)
          .map((item) => RatingDistribution.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class RatingDistribution {
  final int rating;
  final int count;

  RatingDistribution({
    this.rating = 0,
    this.count = 0,
  });

  // Default constructor
  RatingDistribution.empty() : this(rating: 0, count: 0);

  // CopyWith constructor
  RatingDistribution copyWith({
    int? rating,
    int? count,
  }) {
    return RatingDistribution(
      rating: rating ?? this.rating,
      count: count ?? this.count,
    );
  }

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      rating: json['rating'] as int,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'count': count,
    };
  }
}