import 'dart:convert';

class RideNotification {
  String? senderId;
  String? category;
  String? collapseKey;
  bool? contentAvailable;
  NotificationData? data;
  String? from;
  String? messageId;
  String? messageType;
  bool? mutableContent;
  NotificationContent? notification;
  int? sentTime;
  String? threadId;
  int? ttl;

  RideNotification({
    this.senderId,
    this.category,
    this.collapseKey,
    this.contentAvailable,
    this.data,
    this.from,
    this.messageId,
    this.messageType,
    this.mutableContent,
    this.notification,
    this.sentTime,
    this.threadId,
    this.ttl,
  });

  factory RideNotification.fromJson(Map<String, dynamic> json) {
    return RideNotification(
      senderId: json['senderId'],
      category: json['category'],
      collapseKey: json['collapseKey'],
      contentAvailable: json['contentAvailable'],
      data: json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      from: json['from'],
      messageId: json['messageId'],
      messageType: json['messageType'],
      mutableContent: json['mutableContent'],
      notification: json['notification'] != null
          ? NotificationContent.fromJson(json['notification'])
          : null,
      sentTime: json['sentTime'],
      threadId: json['threadId'],
      ttl: json['ttl'],
    );
  }
}

// ----------------------------------------------------------------------

class NotificationData {
  MetaData? metadata;
  String? orderId;
  String? shopName;
  String? deliveryLat;
  String? priority;
  String? type;
  String? title;
  String? message;
  String? userId;
  String? riderName;
  String? riderNumber;
  String? riderId;
  String? deliveryLong;
  String? shopLong;
  String? deliveryAddress;
  String? riderLat;
  String? deliveryDetails;
  String? shopNumber;
  String? notificationId;
  String? operation;
  String? shopLat;
  String? riderLong;
  String? timestamp;

  NotificationData({
    this.metadata,
    this.orderId,
    this.shopName,
    this.deliveryLat,
    this.priority,
    this.type,
    this.title,
    this.message,
    this.userId,
    this.riderName,
    this.riderNumber,
    this.riderId,
    this.deliveryLong,
    this.shopLong,
    this.deliveryAddress,
    this.riderLat,
    this.deliveryDetails,
    this.shopNumber,
    this.notificationId,
    this.operation,
    this.shopLat,
    this.riderLong,
    this.timestamp,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      metadata: json['metadata'] != null?( json['metadata'] is String)?
      MetaData.fromJson(jsonDecode(json['metadata'].toString())):
           MetaData.fromJson(json['metadata'])
          : null,
      orderId: json['orderId'],
      shopName: json['shopName'],
      deliveryLat:  (json['deliveryLat']==null)?"0":json['deliveryLat'].toString(),
      priority: json['priority'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      userId: json['userId'],
      riderName: json['riderName'],
      riderNumber: json['riderNumber'],
      riderId: json['riderId'],
      deliveryLong: (json['deliveryLong']==null)?"0":json['deliveryLong'].toString(),
      shopLong: json['shopLong'],
      deliveryAddress: json['deliveryAddress'],
      riderLat: json['riderLat'],
      deliveryDetails: json['deliveryDetails'],
      shopNumber: json['shopNumber'],
      notificationId: json['notificationId'],
      operation: json['operation'],
      shopLat: json['shopLat'],
      riderLong: json['riderLong'],
      timestamp: json['timestamp'],
    );
  }
}

// ----------------------------------------------------------------------
class DropAddress {
  String? addressId;
  String? address;
  String? lat;
  String? long;
  String? details;

  DropAddress({
    this.addressId,
    this.address,
    this.lat,
    this.long,
    this.details,
  });

  factory DropAddress.fromJson(Map<String, dynamic> json) {
    return DropAddress(
      addressId: json['Addressid'],
      address: json['Address'],
      lat: json['lat'].toString(),
      long: json['long'].toString(),
      details: json['details'],
    );
  }
}
class MetaData {
  String? orderId;
  RiderDetails? riderDetails;
  DeliveredAddress? deliveredAddress;
  DropAddress? dropAddress;
  OwnerDetails? ownerDetails;
  String? ridefare;

  MetaData({
    this.orderId,
    this.riderDetails,
    this.deliveredAddress,
    this.dropAddress,
    this.ownerDetails,
    this.ridefare,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      orderId: json['Order_id'],
      riderDetails: json['Rider details'] != null
          ? RiderDetails.fromJson(json['Rider details'])
          : null,
      deliveredAddress: json['Delivered address'] != null
          ? DeliveredAddress.fromJson(json['Delivered address'])
          : null,
      dropAddress: json['Drop address'] != null
          ? DropAddress.fromJson(json['Drop address'])
          : null,
      ownerDetails: json['owner details'] != null
          ? OwnerDetails.fromJson(json['owner details'])
          : null,
      ridefare: json['ridefare']?.toString(),
    );
  }
}


// ----------------------------------------------------------------------

class RiderDetails {
  String? userid;
  String? name;
  String? number;
  String? lat;
  String? long;

  RiderDetails({
    this.userid,
    this.name,
    this.number,
    this.lat,
    this.long,
  });

  factory RiderDetails.fromJson(Map<String, dynamic> json) {
    return RiderDetails(
      userid: json['userid'],
      name: json['Name'],
      number: json['number'],
      lat: json['lat'].toString(),
      long: json['long'].toString(),
    );
  }
}

// ----------------------------------------------------------------------

class DeliveredAddress {
  String? addressId;
  String? lat;
  String? long;
  String? details;

  DeliveredAddress({
    this.addressId,
    this.lat,
    this.long,
    this.details,
  });

  factory DeliveredAddress.fromJson(Map<String, dynamic> json) {
    return DeliveredAddress(
      addressId: json['Addressid'],
      lat: json['lat'].toString(),
      long: json['long'] .toString(),
      details: json['details'],
    );
  }
}

// ----------------------------------------------------------------------

class OwnerDetails {
  String? userid;
  String? number;
  String? lat;
  String? long;

  OwnerDetails({
    this.userid,
    this.number,
    this.lat,
    this.long,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      userid: json['userid'],
      number: json['number'],
      lat: json['lat'].toString(),
      long: json['long'] .toString(),
    );
  }
}

// ----------------------------------------------------------------------

class NotificationContent {
  String? title;
  String? body;
  AndroidNotificationForRide? android;

  NotificationContent({
    this.title,
    this.body,
    this.android,
  });

  factory NotificationContent.fromJson(Map<String, dynamic> json) {
    return NotificationContent(
      title: json['title'],
      body: json['body'],
      android: json['android'] != null
          ? AndroidNotificationForRide.fromJson(json['android'])
          : null,
    );
  }
}

// ----------------------------------------------------------------------

class AndroidNotificationForRide {
  String? channelId;
  String? color;
  String? imageUrl;
  int? priority;
  String? smallIcon;
  String? sound;

  AndroidNotificationForRide({
    this.channelId,
    this.color,
    this.imageUrl,
    this.priority,
    this.smallIcon,
    this.sound,
  });

  factory AndroidNotificationForRide.fromJson(Map<String, dynamic> json) {
    return AndroidNotificationForRide(
      channelId: json['channelId'],
      color: json['color'],
      imageUrl: json['imageUrl'],
      priority: json['priority'],
      smallIcon: json['smallIcon'],
      sound: json['sound'],
    );
  }
}
