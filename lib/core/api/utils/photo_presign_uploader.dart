import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Upload one local file via the user-service presign flow
/// (`GET user-service/upload/init` → returns `{uploadURL, fileUrl}` →
/// `PUT` the file's bytes to `uploadURL`). Returns the public `fileUrl`
/// on success, or `null` on any failure (network error, missing file,
/// bad response shape — silently swallowed, the caller decides what to
/// do with a missing URL).
///
/// Used by the enquiry sheets (hotel / healthcare / education) so the
/// photos the customer attached on the inquiry form land as visible URLs
/// in the eventual chat card. The vehicle flow uses VehicleController's
/// own `uploadFile`, which is kept as-is.
Future<String?> uploadFileViaUserPresign(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) {
      log('[PRESIGN] file missing: $path');
      return null;
    }
    final fileName = p.basename(path);
    final fileType = lookupMimeType(path) ?? 'application/octet-stream';
    log('[PRESIGN] init → GET user-service/upload/init '
        'fileName=$fileName fileType=$fileType');

    final initRes = await ApiBaseHelper().getHTTP(
      'user-service/upload/init',
      params: {ApiKeys.fileName: fileName, ApiKeys.fileType: fileType},
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
    if (!initRes.isSuccess) {
      log('[PRESIGN] init failed: statusCode=${initRes.statusCode} '
          'message=${initRes.message} data=${initRes.response?.data}');
      return null;
    }

    final rawBody = initRes.response?.data;
    log('[PRESIGN] init response body=$rawBody');
    final init = ImageUploadResponseModel.fromJson(
        Map<String, dynamic>.from(rawBody ?? {}));
    final uploadUrl = init.uploadUrl;
    final fileUrl = init.fileUrl;
    if (uploadUrl == null || fileUrl == null) {
      // The response didn't carry either the presigned upload URL or the
      // public file URL under any of the known key names. Log the raw
      // body so it's obvious which key is missing on the wire.
      log('[PRESIGN] init parsed but uploadUrl/fileUrl missing '
          '(uploadUrl=$uploadUrl fileUrl=$fileUrl body=$rawBody)');
      return null;
    }

    final putRes = await ApiBaseHelper().uploadVideoToS3(
      uploadUrl,
      file: file,
      fileType: fileType,
      showProgress: false,
    );
    if (putRes == null || !putRes.isSuccess) {
      log('[PRESIGN] S3 PUT failed: statusCode=${putRes?.statusCode} '
          'message=${putRes?.message}');
      return null;
    }
    log('[PRESIGN] uploaded → $fileUrl');
    return fileUrl;
  } catch (e, st) {
    log('[PRESIGN] threw: $e\n$st');
    return null;
  }
}

/// Sequentially upload a list of local file paths via
/// [uploadFileViaUserPresign]. Paths that fail to upload are silently
/// skipped — the returned list contains only the URLs that succeeded,
/// in the same order the inputs were uploaded.
Future<List<String>> uploadFilesViaUserPresign(List<String> paths) async {
  if (paths.isEmpty) return const [];
  log('[PRESIGN] batch upload → ${paths.length} file(s)');
  final urls = <String>[];
  for (final path in paths) {
    final url = await uploadFileViaUserPresign(path);
    if (url != null && url.isNotEmpty) urls.add(url);
  }
  log('[PRESIGN] batch done → ${urls.length}/${paths.length} succeeded');
  return urls;
}
