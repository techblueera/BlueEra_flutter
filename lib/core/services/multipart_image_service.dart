import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

Future<MultipartFile?> multiPartImage({required String? imagePath}) async {
  MultipartFile? imageByPart;
  if (imagePath?.isNotEmpty ?? false) {
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



