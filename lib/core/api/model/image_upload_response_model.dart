class ImageUploadResponseModel {
  final String? uploadUrl; // Presigned URL for AWS PUT request
  final String? fileUrl;   // Public/Permanent URL of the file

  ImageUploadResponseModel({
    this.uploadUrl,
    this.fileUrl,
  });

  factory ImageUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponseModel(
      uploadUrl: json['uploadURL'],
      fileUrl: json['fileUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadURL': uploadUrl,
      'fileUrl': fileUrl,
    };
  }
}