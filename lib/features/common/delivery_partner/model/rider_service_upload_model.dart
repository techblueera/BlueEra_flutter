class RiderServiceUploadModel {
  String? uploadURL;
  String? fileUrl;

  RiderServiceUploadModel({this.uploadURL, this.fileUrl});

  RiderServiceUploadModel.fromJson(Map<String, dynamic> json) {
    uploadURL = json['uploadURL'];
    fileUrl = json['fileUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uploadURL'] = this.uploadURL;
    data['fileUrl'] = this.fileUrl;
    return data;
  }
}