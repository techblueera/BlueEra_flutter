// To parse this JSON data, do
//
//     final receivedEnquiryResponse = receivedEnquiryResponseFromJson(jsonString);

import 'dart:convert';

ReceivedEnquiryResponse receivedEnquiryResponseFromJson(String str) => ReceivedEnquiryResponse.fromJson(json.decode(str));

String receivedEnquiryResponseToJson(ReceivedEnquiryResponse data) => json.encode(data.toJson());

class ReceivedEnquiryResponse {
    bool success;
    int count;
    List<ReceivedEnquiry> data;

    ReceivedEnquiryResponse({
        required this.success,
        required this.count,
        required this.data,
    });

    factory ReceivedEnquiryResponse.fromJson(Map<String, dynamic> json) => ReceivedEnquiryResponse(
        success: json["success"],
        count: json["count"],
        data: List<ReceivedEnquiry>.from(json["data"].map((x) => ReceivedEnquiry.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class ReceivedEnquiry {
    String id;
    String serviceProviderChannelId;
    String inquirerId;
    String videoId;
    String subject;
    List<Message> messages;
    String status;
    DateTime createdAt;
    DateTime updatedAt;
    int v;
    dynamic channelName;
    dynamic channelUsername;
    String videoTitle;
    dynamic userName;
    dynamic userEmail;
    String? datumUserEmail;
    String? userPhone;
    String? datumUserName;

    ReceivedEnquiry({
        required this.id,
        required this.serviceProviderChannelId,
        required this.inquirerId,
        required this.videoId,
        required this.subject,
        required this.messages,
        required this.status,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
        required this.channelName,
        required this.channelUsername,
        required this.videoTitle,
        required this.userName,
        required this.userEmail,
        this.datumUserEmail,
        this.userPhone,
        this.datumUserName,
    });

    factory ReceivedEnquiry.fromJson(Map<String, dynamic> json) => ReceivedEnquiry(
        id: json["_id"],
        serviceProviderChannelId: json["serviceProviderChannelId"],
        inquirerId: json["inquirerId"],
        videoId: json["videoId"],
        subject: json["subject"],
        messages: List<Message>.from(json["messages"].map((x) => Message.fromJson(x))),
        status: json["status"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
        channelName: json["channelName"],
        channelUsername: json["channelUsername"],
        videoTitle: json["videoTitle"],
        userName: json["userName"],
        userEmail: json["userEmail"],
        datumUserEmail: json["user_email"],
        userPhone: json["user_phone"],
        datumUserName: json["user_name"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "serviceProviderChannelId": serviceProviderChannelId,
        "inquirerId": inquirerId,
        "videoId": videoId,
        "subject": subject,
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
        "status": status,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
        "channelName": channelName,
        "channelUsername": channelUsername,
        "videoTitle": videoTitle,
        "userName": userName,
        "userEmail": userEmail,
        "user_email": datumUserEmail,
        "user_phone": userPhone,
        "user_name": datumUserName,
    };
}

class Message {
    String senderId;
    String senderType;
    String content;
    String id;
    DateTime createdAt;
    DateTime updatedAt;

    Message({
        required this.senderId,
        required this.senderType,
        required this.content,
        required this.id,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        senderId: json["senderId"],
        senderType: json["senderType"],
        content: json["content"],
        id: json["_id"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "senderId": senderId,
        "senderType": senderType,
        "content": content,
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
    };
}
