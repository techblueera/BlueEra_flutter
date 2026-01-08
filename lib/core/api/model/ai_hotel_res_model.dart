import 'dart:convert';
AiHotelResModel aiHotelResModelFromJson(String str) => AiHotelResModel.fromJson(json.decode(str));
String aiHotelResModelToJson(AiHotelResModel data) => json.encode(data.toJson());
class AiHotelResModel {
  AiHotelResModel({
      this.success, 
      this.data,});

  AiHotelResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? AiHotelData.fromJson(json['data']) : null;
  }
  bool? success;
  AiHotelData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

AiHotelData dataFromJson(String str) => AiHotelData.fromJson(json.decode(str));
String dataToJson(AiHotelData data) => json.encode(data.toJson());
class AiHotelData {
  AiHotelData({
      this.appMetadata, 
      this.screens,});

  AiHotelData.fromJson(dynamic json) {
    appMetadata = json['appMetadata'] != null ? AppMetadata.fromJson(json['appMetadata']) : null;
    screens = json['screens'] != null ? AiHotelScreens.fromJson(json['screens']) : null;
  }
  AppMetadata? appMetadata;
  AiHotelScreens? screens;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (appMetadata != null) {
      map['appMetadata'] = appMetadata?.toJson();
    }
    if (screens != null) {
      map['screens'] = screens?.toJson();
    }
    return map;
  }

}

AiHotelScreens screensFromJson(String str) => AiHotelScreens.fromJson(json.decode(str));
String screensToJson(AiHotelScreens data) => json.encode(data.toJson());
class AiHotelScreens {
  AiHotelScreens({
      this.aboutProperty, 
      this.contactUs, 
      this.home, 
      this.hotelAmenities, 
      this.hotelPolicies, 
      this.propertyPhotos, 
      this.restaurantMenu, 
      this.roomAmenities, 
      this.roomDetails,});

  AiHotelScreens.fromJson(dynamic json) {
    aboutProperty = json['aboutProperty'] != null ? AboutProperty.fromJson(json['aboutProperty']) : null;
    contactUs = json['contactUs'] != null ? ContactUs.fromJson(json['contactUs']) : null;
    home = json['home'] != null ? Home.fromJson(json['home']) : null;
    hotelAmenities = json['hotelAmenities'] != null ? HotelAmenities.fromJson(json['hotelAmenities']) : null;
    hotelPolicies = json['hotelPolicies'] != null ? HotelPolicies.fromJson(json['hotelPolicies']) : null;
    propertyPhotos = json['propertyPhotos'] != null ? PropertyPhotos.fromJson(json['propertyPhotos']) : null;
    restaurantMenu = json['restaurantMenu'] != null ? RestaurantMenu.fromJson(json['restaurantMenu']) : null;
    roomAmenities = json['roomAmenities'] != null ? RoomAmenities.fromJson(json['roomAmenities']) : null;
    roomDetails = json['roomDetails'] != null ? RoomDetails.fromJson(json['roomDetails']) : null;
  }
  AboutProperty? aboutProperty;
  ContactUs? contactUs;
  Home? home;
  HotelAmenities? hotelAmenities;
  HotelPolicies? hotelPolicies;
  PropertyPhotos? propertyPhotos;
  RestaurantMenu? restaurantMenu;
  RoomAmenities? roomAmenities;
  RoomDetails? roomDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (aboutProperty != null) {
      map['aboutProperty'] = aboutProperty?.toJson();
    }
    if (contactUs != null) {
      map['contactUs'] = contactUs?.toJson();
    }
    if (home != null) {
      map['home'] = home?.toJson();
    }
    if (hotelAmenities != null) {
      map['hotelAmenities'] = hotelAmenities?.toJson();
    }
    if (hotelPolicies != null) {
      map['hotelPolicies'] = hotelPolicies?.toJson();
    }
    if (propertyPhotos != null) {
      map['propertyPhotos'] = propertyPhotos?.toJson();
    }
    if (restaurantMenu != null) {
      map['restaurantMenu'] = restaurantMenu?.toJson();
    }
    if (roomAmenities != null) {
      map['roomAmenities'] = roomAmenities?.toJson();
    }
    if (roomDetails != null) {
      map['roomDetails'] = roomDetails?.toJson();
    }
    return map;
  }

}

RoomDetails roomDetailsFromJson(String str) => RoomDetails.fromJson(json.decode(str));
String roomDetailsToJson(RoomDetails data) => json.encode(data.toJson());
class RoomDetails {
  RoomDetails({
      this.actionButton, 
      this.headerTitle, 
      this.rooms,});

  RoomDetails.fromJson(dynamic json) {
    actionButton = json['actionButton'];
    headerTitle = json['headerTitle'];
    if (json['rooms'] != null) {
      rooms = [];
      json['rooms'].forEach((v) {
        rooms?.add(AiHotelRooms.fromJson(v));
      });
    }
  }
  String? actionButton;
  String? headerTitle;
  List<AiHotelRooms>? rooms;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['actionButton'] = actionButton;
    map['headerTitle'] = headerTitle;
    if (rooms != null) {
      map['rooms'] = rooms?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

AiHotelRooms roomsFromJson(String str) => AiHotelRooms.fromJson(json.decode(str));
String roomsToJson(AiHotelRooms data) => json.encode(data.toJson());
class AiHotelRooms {
  AiHotelRooms({
      this.available, 
      this.price, 
      this.type,});

  AiHotelRooms.fromJson(dynamic json) {
    available = json['available'];
    price = json['price'];
    type = json['type'];
  }
  bool? available;
  String? price;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['available'] = available;
    map['price'] = price;
    map['type'] = type;
    return map;
  }

}

RoomAmenities roomAmenitiesFromJson(String str) => RoomAmenities.fromJson(json.decode(str));
String roomAmenitiesToJson(RoomAmenities data) => json.encode(data.toJson());
class RoomAmenities {
  RoomAmenities({
      this.amenities, 
      this.headerTitle,});

  RoomAmenities.fromJson(dynamic json) {
    amenities = json['amenities'] != null ? json['amenities'].cast<String>() : [];
    headerTitle = json['headerTitle'];
  }
  List<String>? amenities;
  String? headerTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['amenities'] = amenities;
    map['headerTitle'] = headerTitle;
    return map;
  }

}

RestaurantMenu restaurantMenuFromJson(String str) => RestaurantMenu.fromJson(json.decode(str));
String restaurantMenuToJson(RestaurantMenu data) => json.encode(data.toJson());
class RestaurantMenu {
  RestaurantMenu({
      this.available, 
      this.cuisines,});

  RestaurantMenu.fromJson(dynamic json) {
    available = json['available'];
    cuisines = json['cuisines'] != null ? json['cuisines'].cast<String>() : [];
  }
  bool? available;
  List<String>? cuisines;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['available'] = available;
    map['cuisines'] = cuisines;
    return map;
  }

}

PropertyPhotos propertyPhotosFromJson(String str) => PropertyPhotos.fromJson(json.decode(str));
String propertyPhotosToJson(PropertyPhotos data) => json.encode(data.toJson());
class PropertyPhotos {
  PropertyPhotos({
      this.galleries, 
      this.headerTitle,});

  PropertyPhotos.fromJson(dynamic json) {
    if (json['galleries'] != null) {
      galleries = [];
      json['galleries'].forEach((v) {
        galleries?.add(Galleries.fromJson(v));
      });
    }
    headerTitle = json['headerTitle'];
  }
  List<Galleries>? galleries;
  String? headerTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (galleries != null) {
      map['galleries'] = galleries?.map((v) => v.toJson()).toList();
    }
    map['headerTitle'] = headerTitle;
    return map;
  }

}

Galleries galleriesFromJson(String str) => Galleries.fromJson(json.decode(str));
String galleriesToJson(Galleries data) => json.encode(data.toJson());
class Galleries {
  Galleries({
      this.category, 
      this.coverImage, 
      this.imageCount, 
      this.lastUpdate,});

  Galleries.fromJson(dynamic json) {
    category = json['category'];
    coverImage = json['coverImage'];
    imageCount = json['imageCount'];
    lastUpdate = json['lastUpdate'];
  }
  String? category;
  String? coverImage;
  String? imageCount;
  String? lastUpdate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['category'] = category;
    map['coverImage'] = coverImage;
    map['imageCount'] = imageCount;
    map['lastUpdate'] = lastUpdate;
    return map;
  }

}

HotelPolicies hotelPoliciesFromJson(String str) => HotelPolicies.fromJson(json.decode(str));
String hotelPoliciesToJson(HotelPolicies data) => json.encode(data.toJson());
class HotelPolicies {
  HotelPolicies({
      this.checkInTime, 
      this.checkOutTime, 
      this.foodRestrictions, 
      this.headerTitle, 
      this.rules,});

  HotelPolicies.fromJson(dynamic json) {
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    foodRestrictions = json['foodRestrictions'] != null ? json['foodRestrictions'].cast<String>() : [];
    headerTitle = json['headerTitle'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }
  String? checkInTime;
  String? checkOutTime;
  List<String>? foodRestrictions;
  String? headerTitle;
  Rules? rules;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['checkInTime'] = checkInTime;
    map['checkOutTime'] = checkOutTime;
    map['foodRestrictions'] = foodRestrictions;
    map['headerTitle'] = headerTitle;
    if (rules != null) {
      map['rules'] = rules?.toJson();
    }
    return map;
  }

}

Rules rulesFromJson(String str) => Rules.fromJson(json.decode(str));
String rulesToJson(Rules data) => json.encode(data.toJson());
class Rules {
  Rules({
      this.aadharMandatory, 
      this.allowBachelors, 
      this.allowUnmarriedCouples, 
      this.earlyCheckInAllowed, 
      this.lateCheckOutAllowed, 
      this.localIDAllowed, 
      this.smokingDrinkingAllowed,});

  Rules.fromJson(dynamic json) {
    aadharMandatory = json['aadharMandatory'];
    allowBachelors = json['allowBachelors'];
    allowUnmarriedCouples = json['allowUnmarriedCouples'];
    earlyCheckInAllowed = json['earlyCheckInAllowed'];
    lateCheckOutAllowed = json['lateCheckOutAllowed'];
    localIDAllowed = json['localIDAllowed'];
    smokingDrinkingAllowed = json['smokingDrinkingAllowed'];
  }
  bool? aadharMandatory;
  bool? allowBachelors;
  bool? allowUnmarriedCouples;
  bool? earlyCheckInAllowed;
  bool? lateCheckOutAllowed;
  bool? localIDAllowed;
  bool? smokingDrinkingAllowed;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['aadharMandatory'] = aadharMandatory;
    map['allowBachelors'] = allowBachelors;
    map['allowUnmarriedCouples'] = allowUnmarriedCouples;
    map['earlyCheckInAllowed'] = earlyCheckInAllowed;
    map['lateCheckOutAllowed'] = lateCheckOutAllowed;
    map['localIDAllowed'] = localIDAllowed;
    map['smokingDrinkingAllowed'] = smokingDrinkingAllowed;
    return map;
  }

}

HotelAmenities hotelAmenitiesFromJson(String str) => HotelAmenities.fromJson(json.decode(str));
String hotelAmenitiesToJson(HotelAmenities data) => json.encode(data.toJson());
class HotelAmenities {
  HotelAmenities({
      this.amenities, 
      this.headerTitle,});

  HotelAmenities.fromJson(dynamic json) {
    amenities = json['amenities'] != null ? json['amenities'].cast<String>() : [];
    headerTitle = json['headerTitle'];
  }
  List<String>? amenities;
  String? headerTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['amenities'] = amenities;
    map['headerTitle'] = headerTitle;
    return map;
  }

}

Home homeFromJson(String str) => Home.fromJson(json.decode(str));
String homeToJson(Home data) => json.encode(data.toJson());
class Home {
  Home({
      this.headerTitle, 
      this.menuGrid, 
      this.userProfileStatus,});

  Home.fromJson(dynamic json) {
    headerTitle = json['headerTitle'];
    if (json['menuGrid'] != null) {
      menuGrid = [];
      json['menuGrid'].forEach((v) {
        menuGrid?.add(MenuGrid.fromJson(v));
      });
    }
    userProfileStatus = json['userProfileStatus'] != null ? UserProfileStatus.fromJson(json['userProfileStatus']) : null;
  }
  String? headerTitle;
  List<MenuGrid>? menuGrid;
  UserProfileStatus? userProfileStatus;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['headerTitle'] = headerTitle;
    if (menuGrid != null) {
      map['menuGrid'] = menuGrid?.map((v) => v.toJson()).toList();
    }
    if (userProfileStatus != null) {
      map['userProfileStatus'] = userProfileStatus?.toJson();
    }
    return map;
  }

}

UserProfileStatus userProfileStatusFromJson(String str) => UserProfileStatus.fromJson(json.decode(str));
String userProfileStatusToJson(UserProfileStatus data) => json.encode(data.toJson());
class UserProfileStatus {
  UserProfileStatus({
      this.callToAction, 
      this.message,});

  UserProfileStatus.fromJson(dynamic json) {
    callToAction = json['callToAction'];
    message = json['message'];
  }
  String? callToAction;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['callToAction'] = callToAction;
    map['message'] = message;
    return map;
  }

}

MenuGrid menuGridFromJson(String str) => MenuGrid.fromJson(json.decode(str));
String menuGridToJson(MenuGrid data) => json.encode(data.toJson());
class MenuGrid {
  MenuGrid({
      this.icon, 
      this.id, 
      this.title,});

  MenuGrid.fromJson(dynamic json) {
    icon = json['icon'];
    id = json['id'];
    title = json['title'];
  }
  String? icon;
  String? id;
  String? title;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['icon'] = icon;
    map['id'] = id;
    map['title'] = title;
    return map;
  }

}

ContactUs contactUsFromJson(String str) => ContactUs.fromJson(json.decode(str));
String contactUsToJson(ContactUs data) => json.encode(data.toJson());
class ContactUs {
  ContactUs({
      this.actionButton, 
      this.emergency, 
      this.headerTitle, 
      this.hotelName, 
      this.reception, 
      this.website,});

  ContactUs.fromJson(dynamic json) {
    actionButton = json['actionButton'];
    emergency = json['emergency'] != null ? Emergency.fromJson(json['emergency']) : null;
    headerTitle = json['headerTitle'];
    hotelName = json['hotelName'];
    reception = json['reception'] != null ? Reception.fromJson(json['reception']) : null;
    website = json['website'];
  }
  String? actionButton;
  Emergency? emergency;
  String? headerTitle;
  String? hotelName;
  Reception? reception;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['actionButton'] = actionButton;
    if (emergency != null) {
      map['emergency'] = emergency?.toJson();
    }
    map['headerTitle'] = headerTitle;
    map['hotelName'] = hotelName;
    if (reception != null) {
      map['reception'] = reception?.toJson();
    }
    map['website'] = website;
    return map;
  }

}

Reception receptionFromJson(String str) => Reception.fromJson(json.decode(str));
String receptionToJson(Reception data) => json.encode(data.toJson());
class Reception {
  Reception({
      this.email, 
      this.phone,});

  Reception.fromJson(dynamic json) {
    email = json['email'];
    phone = json['phone'];
  }
  String? email;
  String? phone;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['email'] = email;
    map['phone'] = phone;
    return map;
  }

}

Emergency emergencyFromJson(String str) => Emergency.fromJson(json.decode(str));
String emergencyToJson(Emergency data) => json.encode(data.toJson());
class Emergency {
  Emergency({
      this.fireBrigade, 
      this.hospital, 
      this.phone, 
      this.policeStation,});

  Emergency.fromJson(dynamic json) {
    fireBrigade = json['fireBrigade'];
    hospital = json['hospital'];
    phone = json['phone'];
    policeStation = json['policeStation'];
  }
  String? fireBrigade;
  String? hospital;
  String? phone;
  String? policeStation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['fireBrigade'] = fireBrigade;
    map['hospital'] = hospital;
    map['phone'] = phone;
    map['policeStation'] = policeStation;
    return map;
  }

}

AboutProperty aboutPropertyFromJson(String str) => AboutProperty.fromJson(json.decode(str));
String aboutPropertyToJson(AboutProperty data) => json.encode(data.toJson());
class AboutProperty {
  AboutProperty({
      this.description, 
      this.name, 
      this.website,});

  AboutProperty.fromJson(dynamic json) {
    description = json['description'];
    name = json['name'];
    website = json['website'];
  }
  String? description;
  String? name;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['name'] = name;
    map['website'] = website;
    return map;
  }

}

AppMetadata appMetadataFromJson(String str) => AppMetadata.fromJson(json.decode(str));
String appMetadataToJson(AppMetadata data) => json.encode(data.toJson());
class AppMetadata {
  AppMetadata({
      this.appName, 
      this.statusBarTime,});

  AppMetadata.fromJson(dynamic json) {
    appName = json['appName'];
    statusBarTime = json['statusBarTime'];
  }
  String? appName;
  String? statusBarTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['appName'] = appName;
    map['statusBarTime'] = statusBarTime;
    return map;
  }

}