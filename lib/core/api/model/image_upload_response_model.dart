class ImageUploadResponseModel {
  final String? uploadUrl; // Presigned URL for AWS PUT request
  final String? fileUrl;   // Public/Permanent URL of the file

  ImageUploadResponseModel({
    this.uploadUrl,
    this.fileUrl,
  });

  factory ImageUploadResponseModel.fromJson(Map<String, dynamic> json) {
    // The user-service presign returns `uploadURL` / `fileUrl` (existing
    // shape used by hotel / healthcare / education flows). The
    // other-service presign, per
    // `lib/docs/other-enquiry-ui-integration.md` §1, returns
    // `uploadUrl` / `publicUrl`. Accept both so either producer parses.
    return ImageUploadResponseModel(
      uploadUrl: json['uploadURL'] ?? json['uploadUrl'],
      fileUrl: json['fileUrl'] ?? json['publicUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadURL': uploadUrl,
      'fileUrl': fileUrl,
    };
  }
}