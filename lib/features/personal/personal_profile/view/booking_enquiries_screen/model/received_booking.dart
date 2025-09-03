// To parse this JSON data, do
//
//     final receivedBooking = receivedBookingFromJson(jsonString);

import 'dart:convert';

ReceivedBookingResponse receivedBookingFromJson(String str) => ReceivedBookingResponse.fromJson(json.decode(str));

String receivedBookingToJson(ReceivedBookingResponse data) => json.encode(data.toJson());

class ReceivedBookingResponse {
    bool success;
    int count;
    List<ReceivedBooking> data;

    ReceivedBookingResponse({
        required this.success,
        required this.count,
        required this.data,
    });

    factory ReceivedBookingResponse.fromJson(Map<String, dynamic> json) => ReceivedBookingResponse(
        success: json["success"],
        count: json["count"],
        data: List<ReceivedBooking>.from(json["data"].map((x) => ReceivedBooking.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class ReceivedBooking {
    String id;
    String serviceProviderChannelId;
    String serviceTakerId;
    String videoId;
    DateTime bookingTime;
    int? durationInMinutes;
    int? amount;
    CustomerDetails customerDetails;
    String status;
    DateTime createdAt;
    DateTime updatedAt;
    int? v;
    String videoTitle;

    ReceivedBooking({
        required this.id,
        required this.serviceProviderChannelId,
        required this.serviceTakerId,
        required this.videoId,
        required this.bookingTime,
        this.durationInMinutes,
        this.amount,
        required this.customerDetails,
        required this.status,
        required this.createdAt,
        required this.updatedAt,
        this.v,
        required this.videoTitle,
    });

    factory ReceivedBooking.fromJson(Map<String, dynamic> json) => ReceivedBooking(
        id: json["_id"] ?? '',
        serviceProviderChannelId: json["serviceProviderChannelId"] ?? '',
        serviceTakerId: json["serviceTakerId"] ?? '',
        videoId: json["videoId"] ?? '',
        bookingTime: DateTime.parse(json["bookingTime"] ?? DateTime.now().toIso8601String()),
        durationInMinutes: json["durationInMinutes"],
        amount: json["amount"],
        customerDetails: CustomerDetails.fromJson(json["customerDetails"] ?? {}),
        status: json["status"] ?? '',
        createdAt: DateTime.parse(json["createdAt"] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json["updatedAt"] ?? DateTime.now().toIso8601String()),
        v: json["__v"],
        videoTitle: json["videoTitle"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "serviceProviderChannelId": serviceProviderChannelId,
        "serviceTakerId": serviceTakerId,
        "videoId": videoId,
        "bookingTime": bookingTime.toIso8601String(),
        "durationInMinutes": durationInMinutes,
        "amount": amount,
        "customerDetails": customerDetails.toJson(),
        "status": status,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
        "videoTitle": videoTitle,
    };
}

class CustomerDetails {
    String name;
    String mobileNumber;
    String email;

    CustomerDetails({
        required this.name,
        required this.mobileNumber,
        required this.email,
    });

    factory CustomerDetails.fromJson(Map<String, dynamic> json) => CustomerDetails(
        name: json["name"] ?? '',
        mobileNumber: json["mobileNumber"] ?? '',
        email: json["email"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "mobileNumber": mobileNumber,
        "email": email,
    };
}
