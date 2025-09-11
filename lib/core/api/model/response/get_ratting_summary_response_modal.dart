
import 'dart:convert';

GetRattingSummaryResponse getRattingSummaryResponseFromJson(String str) => GetRattingSummaryResponse.fromJson(json.decode(str));

String getRattingSummaryResponseToJson(GetRattingSummaryResponse data) => json.encode(data.toJson());

class GetRattingSummaryResponse {
    bool? success;
    GetRattingSummaryResponseData? data;

    GetRattingSummaryResponse({
        this.success,
        this.data,
    });

    factory GetRattingSummaryResponse.fromJson(Map<String, dynamic> json) => GetRattingSummaryResponse(
        success: json["success"],
        data: json["data"] == null ? null : GetRattingSummaryResponseData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
    };
}

class GetRattingSummaryResponseData {
    String? businessId;
    String? avgRating;
    int? totalRatings;

    GetRattingSummaryResponseData({
        this.businessId,
        this.avgRating,
        this.totalRatings,
    });

    factory GetRattingSummaryResponseData.fromJson(Map<String, dynamic> json) => GetRattingSummaryResponseData(
        businessId: json["businessId"],
        avgRating: json["avg_rating"],
        totalRatings: json["total_ratings"],
    );

    Map<String, dynamic> toJson() => {
        "businessId": businessId,
        "avg_rating": avgRating,
        "total_ratings": totalRatings,
    };
}
