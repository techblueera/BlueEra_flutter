// To parse this JSON data, do
//
//     final getCountRattingResponse = getCountRattingResponseFromJson(jsonString);

import 'dart:convert';

GetCountRattingResponse getCountRattingResponseFromJson(String str) => GetCountRattingResponse.fromJson(json.decode(str));

String getCountRattingResponseToJson(GetCountRattingResponse data) => json.encode(data.toJson());

class GetCountRattingResponse {
    bool? success;
    List<GetCountRattingResponseDatum>? data;

    GetCountRattingResponse({
        this.success,
        this.data,
    });

    factory GetCountRattingResponse.fromJson(Map<String, dynamic> json) => GetCountRattingResponse(
        success: json["success"],
        data: json["data"] == null ? [] : List<GetCountRattingResponseDatum>.from(json["data"]!.map((x) => GetCountRattingResponseDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class GetCountRattingResponseDatum {
    int? rating;
    int? count;

    GetCountRattingResponseDatum({
        this.rating,
        this.count,
    });

    factory GetCountRattingResponseDatum.fromJson(Map<String, dynamic> json) => GetCountRattingResponseDatum(
        rating: json["rating"],
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "rating": rating,
        "count": count,
    };
}
