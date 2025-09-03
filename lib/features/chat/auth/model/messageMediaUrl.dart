/// url : "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/68834aebd37dcddbbe519b87/audios/1753436266448_countdown-from-10-190389.mp3"
/// type : "audio"
/// name : "countdown-from-10-190389.mp3"
/// size : 1493786
/// mimetype : "audio/mpeg"
/// _id : "6883506ae2c0ad7335a44d01"

class MessageMediaUrl {
  MessageMediaUrl({
      this.url, 
      this.type, 
      this.name, 
      this.size, 
      this.mimetype, 
      this.id,});

  MessageMediaUrl.fromJson(dynamic json) {
    url = json['url'];
    type = json['type'];
    name = json['name'];
    size = json['size'];
    mimetype = json['mimetype'];
    id = json['_id'];
  }
  String? url;
  String? type;
  String? name;
  num? size;
  String? mimetype;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['type'] = type;
    map['name'] = name;
    map['size'] = size;
    map['mimetype'] = mimetype;
    map['_id'] = id;
    return map;
  }

}