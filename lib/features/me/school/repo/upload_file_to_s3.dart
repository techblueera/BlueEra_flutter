import 'dart:io';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

import 'dart:io';
import 'package:get/get.dart';

// Using a typedef makes the code cleaner and prevents type mismatch errors
typedef UploadResult = ({bool isSuccess, String url, String message});

class S3UploadService {

  static Future<UploadResult> uploadFile(File file) async {
    try {
      // 1. Basic File Validation
      if (!file.existsSync()) {
        return (isSuccess: false, url: "", message: "File does not exist");
      }

      String fileName = file.path.split('/').last;
      String mimeType = _getMimeType(file.path);

      Map<String, dynamic> queryParams = {
        "fileName": fileName,
        "fileType": mimeType
      };

      // 2. Step 1: Get Pre-signed URL
      var response = await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        final uploadInit = UploadInitResponse.fromJson(response?.response?.data);
        final String preSignedUrl = uploadInit.uploadUrl ?? "";
        final String publicUrl = uploadInit.publicUrl ?? "";

        if (preSignedUrl.isEmpty) {
          return (isSuccess: false, url: "", message: "Invalid Upload URL received");
        }

        // 3. Step 2: Upload Binary to S3
        var s3Response = await ChannelRepo().uploadVideoToS3(
          file: file,
          fileType: mimeType,
          preSignedUrl: preSignedUrl,
          onProgress: (sent) => print("Uploading: $sent"),
        );

        if (s3Response?.isSuccess ?? false) {
          return (isSuccess: true, url: publicUrl, message: "Upload Successful");
        } else {
          // .toString() ensures the Record matches the 'String' type requirement
          return (
          isSuccess: false,
          url: "",
          message: (s3Response?.message ?? "S3 Upload Failed").toString()
          );
        }
      } else {
        return (
        isSuccess: false,
        url: "",
        message: (response?.message ?? "Failed to get upload URL").toString()
        );
      }
    } catch (e) {
      return (isSuccess: false, url: "", message: "Error: ${e.toString()}");
    }
  }

  // Simple Helper for MimeTypes
  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'pdf':  return 'application/pdf';
      default:     return 'application/octet-stream';
    }
  }
}
