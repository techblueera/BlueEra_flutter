class GetAllResumesModel {
  String? message;
  List<Resumes>? resumes;

  GetAllResumesModel({this.message, this.resumes});

  GetAllResumesModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['resumes'] != null) {
      resumes = <Resumes>[];
      json['resumes'].forEach((v) {
        resumes!.add(new Resumes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.resumes != null) {
      data['resumes'] = this.resumes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Resumes {
  String? id;
  String? userId;
  String? fileName;
  String? fileUrl;
  String? createdAt;

  Resumes({this.id, this.userId, this.fileName, this.fileUrl, this.createdAt});

  Resumes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    fileName = json['fileName'];
    fileUrl = json['fileUrl'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['fileName'] = this.fileName;
    data['fileUrl'] = this.fileUrl;
    data['createdAt'] = this.createdAt;
    return data;
  }
}
