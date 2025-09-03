class VideoUploadModel {
  final bool success;
  final String message;
  final VideoUploadData? data;

  VideoUploadModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory VideoUploadModel.fromJson(Map<String, dynamic> json) {
    return VideoUploadModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? VideoUploadData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class VideoUploadData {
  final String videoId;
  final String s3Key;
  final String mediaConvertJobId;

  VideoUploadData({
    required this.videoId,
    required this.s3Key,
    required this.mediaConvertJobId,
  });

  factory VideoUploadData.fromJson(Map<String, dynamic> json) {
    return VideoUploadData(
      videoId: json['videoId'] ?? '',
      s3Key: json['s3Key'] ?? '',
      mediaConvertJobId: json['mediaConvertJobId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      's3Key': s3Key,
      'mediaConvertJobId': mediaConvertJobId,
    };
  }
}
