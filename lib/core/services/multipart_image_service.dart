import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads a remote image [url] into a local temp file and returns its path.
///
/// Lets callers treat an already-uploaded (network) profile image exactly like
/// a freshly picked local image — the existing multipart-upload flow keeps
/// working unchanged because it always receives a real on-disk file.
///
/// Returns `null` on any failure (not a network URL, network error, empty
/// download) so callers can safely fall back to manual image selection.
Future<String?> downloadImageToTempFile(String? url) async {
  if (!isNetworkImage(url)) return null;
  try {
    final dir = await getTemporaryDirectory();
    final savePath =
        '${dir.path}/guest_prefill_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Dio().download(url!, savePath);
    final file = File(savePath);
    if (await file.exists() && await file.length() > 0) {
      return savePath;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<MultipartFile?> multiPartImage({required String? imagePath}) async {
  MultipartFile? imageByPart;
  // Only build a multipart from a real local file. A network URL (e.g. an
  // already-uploaded S3 path) cannot be read off disk and would crash
  // MultipartFile.fromFile with PathNotFoundException.
  if ((imagePath?.isNotEmpty ?? false) && !isNetworkImage(imagePath)) {
    String fileName = imagePath?.split('/').last ?? "";
    imageByPart =
        await MultipartFile.fromFile(imagePath ?? "", filename: fileName);
  }
  return imageByPart;
}

Future<List<MultipartFile>> multiPartMultipleImages({
  required List<File>? arrImages,
}) async {
  final List<MultipartFile> imageParts = [];

  if (arrImages != null && arrImages.isNotEmpty) {
    for (final file in arrImages) {
      final path = file.path;
      final fileName = path.split('/').last;

      final mimeType = 'image/${fileName.split('.').last}';

      imageParts.add(
        await MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }
  }

  return imageParts;
}



