import 'dart:convert';
UserTestimonialModel userTestimonialModelFromJson(String str) => UserTestimonialModel.fromJson(json.decode(str));
String userTestimonialModelToJson(UserTestimonialModel data) => json.encode(data.toJson());
class UserTestimonialModel {
  UserTestimonialModel({
      this.status, 
      this.testimonials,});

  UserTestimonialModel.fromJson(dynamic json) {
    status = json['status'];
    if (json['testimonials'] != null) {
      testimonials = [];
      json['testimonials'].forEach((v) {
        testimonials?.add(Testimonials.fromJson(v));
      });
    }
  }
  bool? status;
  List<Testimonials>? testimonials;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (testimonials != null) {
      map['testimonials'] = testimonials?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Testimonials testimonialsFromJson(String str) => Testimonials.fromJson(json.decode(str));
String testimonialsToJson(Testimonials data) => json.encode(data.toJson());
class Testimonials {
  Testimonials({
      this.id, 
      this.toUser, 
      this.fromUser, 
      this.title, 
      this.description, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Testimonials.fromJson(dynamic json) {
    id = json['_id'];
    toUser = json['toUser'];
    fromUser = json['fromUser'] != null ? FromUser.fromJson(json['fromUser']) : null;
    title = json['title'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? toUser;
  FromUser? fromUser;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['toUser'] = toUser;
    if (fromUser != null) {
      map['fromUser'] = fromUser?.toJson();
    }
    map['title'] = title;
    map['description'] = description;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

FromUser fromUserFromJson(String str) => FromUser.fromJson(json.decode(str));
String fromUserToJson(FromUser data) => json.encode(data.toJson());
class FromUser {
  FromUser({
      this.id, 
      this.name, 
      this.designation, 
      this.profileImage,});

  FromUser.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    designation = json['designation'];
    profileImage = json['profile_image'];
  }
  String? id;
  String? name;
  String? designation;
  String? profileImage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['designation'] = designation;
    map['profile_image'] = profileImage;
    return map;
  }

}