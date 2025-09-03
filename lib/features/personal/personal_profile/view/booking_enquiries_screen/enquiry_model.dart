class EnquiryResponse {
  final bool success;
  final int count;
  final List<Enquiry> data;

  EnquiryResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory EnquiryResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<Enquiry> parsedList;

    if (rawData is List) {
      parsedList = List<Enquiry>.from(rawData.map((x) => Enquiry.fromJson(x)));
    } else if (rawData is Map<String, dynamic>) {
      parsedList = [Enquiry.fromJson(rawData)];
    } else {
      parsedList = <Enquiry>[];
    }

    final int computedCount = json['count'] is int ? json['count'] as int : parsedList.length;

    return EnquiryResponse(
      success: json['success'] == null ? true : (json['success'] as bool),
      count: computedCount,
      data: parsedList,
    );
  }
}

class EnquiryMessage {
  final String? id;
  final String? senderId;
  final String? senderType;
  final String? content;
  final String? createdAt;
  final String? updatedAt;

  EnquiryMessage({
    this.id,
    this.senderId,
    this.senderType,
    this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory EnquiryMessage.fromJson(Map<String, dynamic> json) {
    return EnquiryMessage(
      id: json['_id'] as String?,
      senderId: json['senderId'] as String?,
      senderType: json['senderType'] as String?,
      content: json['content'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "senderId": senderId,
      "senderType": senderType,
      "content": content,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}

class Enquiry {
  // Legacy UI fields (kept for backward compatibility with existing widgets)
  final String title;
  final String date;
  final String message;
  final String status;

  // New API fields
  final String? id;
  final String? serviceProviderChannelId;
  final String? inquirerId;
  final String? videoId;
  final String? userEmail;
  final String? userPhone;
  final String? userName;
  final String? subject; // maps to title for UI
  final List<EnquiryMessage> messagesList;
  final String? createdAt;
  final String? updatedAt;
  final String? channelName;
  final String? channelUsername;
  final String? videoTitle;

  Enquiry({
    // required (legacy UI expectations)
    required this.title,
    required this.date,
    required this.message,
    required this.status,
    // optional new fields
    this.id,
    this.serviceProviderChannelId,
    this.inquirerId,
    this.videoId,
    this.userEmail,
    this.userPhone,
    this.userName,
    this.subject,
    this.messagesList = const <EnquiryMessage>[],
    this.createdAt,
    this.updatedAt,
    this.channelName,
    this.channelUsername,
    this.videoTitle,
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    // Handle both old and new formats
    final List<dynamic>? rawMessages = json['messages'] as List<dynamic>?;
    final List<EnquiryMessage> parsedMessages = rawMessages == null
        ? <EnquiryMessage>[]
        : rawMessages
            .whereType<Map<String, dynamic>>()
            .map((m) => EnquiryMessage.fromJson(m))
            .toList();

    final String subject = (json['subject'] ?? json['title'] ?? '') as String;
    final String createdAt = (json['createdAt'] ?? json['date'] ?? '') as String;
    String latestMessage = '';
    if (parsedMessages.isNotEmpty) {
      latestMessage = parsedMessages.last.content ?? '';
    } else {
      latestMessage = (json['message'] ?? '') as String;
    }

    return Enquiry(
      // Map to legacy UI fields
      title: subject,
      date: createdAt,
      message: latestMessage,
      status: (json['status'] ?? '') as String,
      // New fields
      id: json['_id'] as String?,
      serviceProviderChannelId: json['serviceProviderChannelId'] as String?,
      inquirerId: json['inquirerId'] as String?,
      videoId: json['videoId'] as String?,
      userEmail: (json['userEmail'] ?? json['user_email']) as String?,
      userPhone: (json['userPhone'] ?? json['user_phone']) as String?,
      userName: (json['userName'] ?? json['user_name']) as String?,
      subject: json['subject'] as String?,
      messagesList: parsedMessages,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      channelName: json['channelName'] as String?,
      channelUsername: json['channelUsername'] as String?,
      videoTitle: json['videoTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Keep legacy keys for compatibility
      "title": title,
      "date": date,
      "message": message,
      "status": status,
      // New fields
      "_id": id,
      "serviceProviderChannelId": serviceProviderChannelId,
      "inquirerId": inquirerId,
      "videoId": videoId,
      "user_email": userEmail,
      "user_phone": userPhone,
      "user_name": userName,
      "subject": subject ?? title,
      "messages": messagesList.map((m) => m.toJson()).toList(),
      "createdAt": createdAt ?? date,
      "updatedAt": updatedAt,
      "channelName": channelName,
      "channelUsername": channelUsername,
      "videoTitle": videoTitle,
    };
  }
}
