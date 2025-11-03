class UploadS3ImageModel {
  final String path;
  final String mimeType;
  String? preSignedUrl;

  UploadS3ImageModel({
    required this.path,
    required this.mimeType,
    this.preSignedUrl,
  });

  Map<String, dynamic> toJson() => {
    "path": path,
    "mimeType": mimeType,
    "preSignedUrl": preSignedUrl,
  };
}