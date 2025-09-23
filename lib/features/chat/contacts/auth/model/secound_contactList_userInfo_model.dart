/// id : "68b6d9b9afbad8dbdd47e875"
/// name : "Shishant"
/// profile_image : ""
/// profession : "ARTIST"

class SecondContactListUserInfoModel {
  SecondContactListUserInfoModel({
      this.id, 
      this.name, 
      this.profileImage, 
      this.profession,});

  SecondContactListUserInfoModel.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    profession = json['profession'];
  }
  String? id;
  String? name;
  String? profileImage;
  String? profession;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_image'] = profileImage;
    map['profession'] = profession;
    return map;
  }

}