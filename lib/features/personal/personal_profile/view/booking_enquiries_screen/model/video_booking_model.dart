// To parse this JSON data, do
//
//     final receivedBookingList = receivedBookingListFromJson(jsonString);

import 'dart:convert';

ReceivedBookingList receivedBookingListFromJson(String str) =>
    ReceivedBookingList.fromJson(json.decode(str));

String receivedBookingListToJson(ReceivedBookingList data) =>
    json.encode(data.toJson());

class ReceivedBookingList {
  bool success;
  List<ReceivedBookingData> data;

  ReceivedBookingList({
    required this.success,
    required this.data,
  });

  factory ReceivedBookingList.fromJson(Map<String, dynamic> json) =>
      ReceivedBookingList(
        success: json["success"],
        data: List<ReceivedBookingData>.from(
            json["data"].map((x) => ReceivedBookingData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class ReceivedBookingData {
  List<dynamic> tags;
  List<String> keywords;
  List<String> categories;
  List<dynamic> taggedUsers;
  List<dynamic> taggedChannelProducts;
  List<dynamic> reports;
  TranscodedUrls transcodedUrls;
  Ails thumbnails;
  Ails bankDetails;
  String id;
  String userId;
  String channelId;
  String type;
  String status;
  String title;
  String description;
  String caption;
  String coverUrl;
  String videoUrl;
  int duration;
  String visibility;
  dynamic location;
  dynamic song;
  bool isCollaboration;
  bool allowComments;
  bool isMatureContent;
  String relatedVideoLink;
  bool isBrandPromotion;
  String brandPromotionLink;
  bool acceptBookingsOrEnquiries;
  dynamic bookingConfig;
  bool isFlagged;
  Stats stats;
  AtedAt createdAt;
  AtedAt updatedAt;
  int bookingCount;
  int fee;
  String bookingType;

  ReceivedBookingData({
    required this.tags,
    required this.keywords,
    required this.categories,
    required this.taggedUsers,
    required this.taggedChannelProducts,
    required this.reports,
    required this.transcodedUrls,
    required this.thumbnails,
    required this.bankDetails,
    required this.id,
    required this.userId,
    required this.channelId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.caption,
    required this.coverUrl,
    required this.videoUrl,
    required this.duration,
    required this.visibility,
    required this.location,
    required this.song,
    required this.isCollaboration,
    required this.allowComments,
    required this.isMatureContent,
    required this.relatedVideoLink,
    required this.isBrandPromotion,
    required this.brandPromotionLink,
    required this.acceptBookingsOrEnquiries,
    required this.bookingConfig,
    required this.isFlagged,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    required this.bookingCount,
    required this.fee,
    required this.bookingType,
  });

  factory ReceivedBookingData.fromJson(Map<String, dynamic> json) =>
      ReceivedBookingData(
        tags: List<dynamic>.from(json["tags"].map((x) => x)),
        keywords: List<String>.from(json["keywords"].map((x) => x)),
        categories: List<String>.from(json["categories"].map((x) => x)),
        taggedUsers: List<dynamic>.from(json["tagged_users"].map((x) => x)),
        taggedChannelProducts:
            List<dynamic>.from(json["tagged_channel_products"].map((x) => x)),
        reports: List<dynamic>.from(json["reports"].map((x) => x)),
        transcodedUrls: TranscodedUrls.fromJson(json["transcoded_urls"]),
        thumbnails: Ails.fromJson(json["thumbnails"]),
        bankDetails: Ails.fromJson(json["bank_details"]),
        id: json["id"],
        userId: json["user_id"],
        channelId: json["channel_id"],
        type: json["type"],
        status: json["status"],
        title: json["title"],
        description: json["description"],
        caption: json["caption"],
        coverUrl: json["cover_url"],
        videoUrl: json["video_url"],
        duration: json["duration"],
        visibility: json["visibility"],
        location: json["location"],
        song: json["song"],
        isCollaboration: json["is_collaboration"],
        allowComments: json["allow_comments"],
        isMatureContent: json["is_mature_content"],
        relatedVideoLink: json["related_video_link"],
        isBrandPromotion: json["is_brand_promotion"],
        brandPromotionLink: json["brand_promotion_link"],
        acceptBookingsOrEnquiries: json["accept_bookings_or_enquiries"],
        bookingConfig: json["booking_config"],
        isFlagged: json["is_flagged"],
        stats: Stats.fromJson(json["stats"]),
        createdAt: AtedAt.fromJson(json["created_at"]),
        updatedAt: AtedAt.fromJson(json["updated_at"]),
        bookingCount: json["bookingCount"],
        fee: json["fee"],
        bookingType: json["bookingType"],
      );

  Map<String, dynamic> toJson() => {
        "tags": List<dynamic>.from(tags.map((x) => x)),
        "keywords": List<dynamic>.from(keywords.map((x) => x)),
        "categories": List<dynamic>.from(categories.map((x) => x)),
        "tagged_users": List<dynamic>.from(taggedUsers.map((x) => x)),
        "tagged_channel_products":
            List<dynamic>.from(taggedChannelProducts.map((x) => x)),
        "reports": List<dynamic>.from(reports.map((x) => x)),
        "transcoded_urls": transcodedUrls.toJson(),
        "thumbnails": thumbnails.toJson(),
        "bank_details": bankDetails.toJson(),
        "id": id,
        "user_id": userId,
        "channel_id": channelId,
        "type": type,
        "status": status,
        "title": title,
        "description": description,
        "caption": caption,
        "cover_url": coverUrl,
        "video_url": videoUrl,
        "duration": duration,
        "visibility": visibility,
        "location": location,
        "song": song,
        "is_collaboration": isCollaboration,
        "allow_comments": allowComments,
        "is_mature_content": isMatureContent,
        "related_video_link": relatedVideoLink,
        "is_brand_promotion": isBrandPromotion,
        "brand_promotion_link": brandPromotionLink,
        "accept_bookings_or_enquiries": acceptBookingsOrEnquiries,
        "booking_config": bookingConfig,
        "is_flagged": isFlagged,
        "stats": stats.toJson(),
        "created_at": createdAt.toJson(),
        "updated_at": updatedAt.toJson(),
        "bookingCount": bookingCount,
        "fee": fee,
        "bookingType": bookingType,
      };
}

class Ails {
  Ails();

  factory Ails.fromJson(Map<String, dynamic> json) => Ails();

  Map<String, dynamic> toJson() => {};
}

class AtedAt {
  String seconds;
  int nanos;

  AtedAt({
    required this.seconds,
    required this.nanos,
  });

  factory AtedAt.fromJson(Map<String, dynamic> json) => AtedAt(
        seconds: json["seconds"],
        nanos: json["nanos"],
      );

  Map<String, dynamic> toJson() => {
        "seconds": seconds,
        "nanos": nanos,
      };
}

class Stats {
  String views;
  String likes;
  String shares;
  String comments;

  Stats({
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        views: json["views"],
        likes: json["likes"],
        shares: json["shares"],
        comments: json["comments"],
      );

  Map<String, dynamic> toJson() => {
        "views": views,
        "likes": likes,
        "shares": shares,
        "comments": comments,
      };
}

class TranscodedUrls {
  String the360P;
  String the720P;
  String the1080P;

  TranscodedUrls({
    required this.the360P,
    required this.the720P,
    required this.the1080P,
  });

  factory TranscodedUrls.fromJson(Map<String, dynamic> json) => TranscodedUrls(
        the360P: json["360p"],
        the720P: json["720p"],
        the1080P: json["1080p"],
      );

  Map<String, dynamic> toJson() => {
        "360p": the360P,
        "720p": the720P,
        "1080p": the1080P,
      };
}
