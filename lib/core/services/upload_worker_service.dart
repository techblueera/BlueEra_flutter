// import 'dart:io';
// import 'package:dio/dio.dart';
//
// class UploadWorker {
//   static final Dio _dio = Dio();
//
//   /// Runs in the background isolate
//   static Future<bool> run(Map<String, dynamic> data) async {
//     try {
//       /* ---------- 1.  upload video + cover to S3 ---------- */
//       final videoFile  = File(data['videoPath']);
//       final coverFile  = File(data['coverPath']);
//       final vInfo      = _fileInfo(videoFile, isVideo: true);
//       final cInfo      = _fileInfo(coverFile, isVideo: false);
//
//       // video
//       final vInit = await _uploadInit(vInfo['fileName']!, vInfo['mimeType']!, true);
//       await _uploadToS3(videoFile, vInfo['mimeType']!, vInit['uploadUrl']!);
//
//       // cover
//       final cInit = await _uploadInit(cInfo['fileName']!, cInfo['mimeType']!, false);
//       await _uploadToS3(coverFile, cInfo['mimeType']!, cInit['uploadUrl']!);
//
//       /* ---------- 2.  build the final request body ---------- */
//       final bool isLong = data['videoType'] == 'video';
//       final req = isLong ? _longPayload(data, vInit, cInit)
//           : _shortPayload(data, vInit, cInit);
//
//       /* ---------- 3.  final API call ---------- */
//       await _dio.post(
//         'https://api.example.com/videos',
//         data: req,
//         options: Options(
//           headers: {'Authorization': 'Bearer ${data['token']}'},
//         ),
//       );
//       return true; // success
//     } catch (e) {
//       print('[UploadWorker] error: $e');
//       return false; // Workmanager may retry
//     }
//   }
//
//   /* ---------- helpers ---------- */
//
//   static Map<String, String> _fileInfo(File file, {required bool isVideo}) {
//     final mime = isVideo ? 'video/mp4' : 'image/jpeg';
//     return {'fileName': file.path.split('/').last, 'mimeType': mime};
//   }
//
//   static Future<Map<String, dynamic>> _uploadInit(
//       String fileName, String fileType, bool isVideo) async {
//     final res = await _dio.get(
//       'https://api.example.com/upload/init',
//       queryParameters: {
//         'fileName': fileName,
//         'fileType': fileType,
//         'isVideo': isVideo,
//       },
//     );
//     return res.data as Map<String, dynamic>;
//   }
//
//   static Future<void> _uploadToS3(File file, String mime, String url) async {
//     await _dio.put(
//       url,
//       data: file.openRead(),
//       options: Options(
//         headers: {
//           'Content-Type': mime,
//           'Content-Length': file.lengthSync(),
//         },
//       ),
//     );
//   }
//
