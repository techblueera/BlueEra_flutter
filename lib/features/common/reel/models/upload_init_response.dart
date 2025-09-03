class UploadInitResponse {
  String? uploadUrl;
  String? publicUrl;
  String? fileKey;

  UploadInitResponse({this.uploadUrl, this.publicUrl, this.fileKey});

  UploadInitResponse.fromJson(Map<String, dynamic> json) {
    uploadUrl = json['uploadUrl'];
    publicUrl = json['publicUrl'];
    fileKey = json['fileKey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uploadUrl'] = this.uploadUrl;
    data['publicUrl'] = this.publicUrl;
    data['fileKey'] = this.fileKey;
    return data;
  }
}