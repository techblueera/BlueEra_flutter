class GetResumeById {
  String? message;
  Resume? resume;

  GetResumeById({this.message, this.resume});

  GetResumeById.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    resume =
        json['resume'] != null ? new Resume.fromJson(json['resume']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.resume != null) {
      data['resume'] = this.resume!.toJson();
    }
    return data;
  }
}

class Resume {
  String? id;
  String? name;
  String? email;
  String? location;

  Resume({
    this.id,
    this.name,
    this.email,
    this.location,
  });

  Resume.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['location'] = this.location;

    return data;
  }
}
