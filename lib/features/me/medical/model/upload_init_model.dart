class UploadInitModel {
  String? uploadUrl;
  String? publicUrl;
  String? fileKey;

  UploadInitModel({this.uploadUrl, this.publicUrl, this.fileKey});

  UploadInitModel.fromJson(Map<String, dynamic> json) {
    uploadUrl = json['uploadUrl'];
    publicUrl = json['publicUrl'];
    fileKey = json['fileKey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['uploadUrl'] = uploadUrl;
    data['publicUrl'] = publicUrl;
    data['fileKey'] = fileKey;
    return data;
  }
}