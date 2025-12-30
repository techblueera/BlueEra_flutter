class DocumentsResponse {
  Files? files;
  String? sId;
  String? userId;
  String? documentType;
  bool? isVerified;
  String? createdAt;
  String? updatedAt;
  int? iV;

  DocumentsResponse(
      {this.files,
        this.sId,
        this.userId,
        this.documentType,
        this.isVerified,
        this.createdAt,
        this.updatedAt,
        this.iV});

  DocumentsResponse.fromJson(Map<String, dynamic> json) {
    files = json['files'] != null ? new Files.fromJson(json['files']) : null;
    sId = json['_id'];
    userId = json['userId'];
    documentType = json['documentType'];
    isVerified = json['isVerified'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.files != null) {
      data['files'] = this.files!.toJson();
    }
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['documentType'] = this.documentType;
    data['isVerified'] = this.isVerified;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Files {
  String? front;
  String? back;

  Files({this.front, this.back});

  Files.fromJson(Map<String, dynamic> json) {
    front = json['front'];
    back = json['back'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['front'] = this.front;
    data['back'] = this.back;
    return data;
  }
}