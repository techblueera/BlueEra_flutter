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

/// Maps a file extension to a real IANA media type.
///
/// The previous form was `'image/${fileName.split('.').last}'`, which produces
/// **`image/jpg`** for the `.jpg` files this app's own picker writes
/// (`PhotoPickerService.compressImage` saves `compressed_<ts>.jpg`).
/// `image/jpg` is not a registered media type — the correct one is
/// `image/jpeg` — and server-side upload validators that whitelist media types
/// (multer, NestJS `FileTypeValidator`, DRF, …) reject it. That rejection is
/// indistinguishable from a malformed request at the client, and surfaces as a
/// generic "invalid payload"-class error.
///
/// It degraded in two other ways as well: a file with no extension yielded
/// `image/<whole filename>`, and `PHOTO.JPG` yielded `image/JPG`.
MediaType _mediaTypeForFile(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return MediaType('image', 'jpeg');
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'heic':
      return MediaType('image', 'heic');
    case 'heif':
      return MediaType('image', 'heif');
    case 'gif':
      return MediaType('image', 'gif');
    case 'bmp':
      return MediaType('image', 'bmp');
    case 'pdf':
      return MediaType('application', 'pdf');
    default:
      // Unknown or absent extension. JPEG rather than
      // `application/octet-stream`: every producer feeding this helper is an
      // image picker or the app's own compressor, and a whitelist that accepts
      // images will reject the octet-stream fallback outright.
      return MediaType('image', 'jpeg');
  }
}

Future<List<MultipartFile>> multiPartMultipleImages({
  required List<File>? arrImages,
}) async {
  final List<MultipartFile> imageParts = [];

  if (arrImages != null && arrImages.isNotEmpty) {
    for (final file in arrImages) {
      final path = file.path;
      // Split on BOTH separators: on Windows-authored paths — and anything
      // that reaches here via a plugin using backslashes — `split('/').last`
      // returns the whole path, which then becomes the upload's filename.
      final fileName = path.split(RegExp(r'[/\\]')).last;

      imageParts.add(
        await MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: _mediaTypeForFile(fileName),
        ),
      );
    }
  }

  return imageParts;
}



