import 'package:dio/dio.dart';

Future<MultipartFile?> multiPartImage({required String? imagePath}) async {
  MultipartFile? imageByPart;
  if (imagePath?.isNotEmpty ?? false) {
    String fileName = imagePath?.split('/').last ?? "";
    imageByPart =
        await MultipartFile.fromFile(imagePath ?? "", filename: fileName);
  }
  return imageByPart;
}
