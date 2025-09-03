// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:get_thumbnail_video/index.dart';
// import 'package:get_thumbnail_video/video_thumbnail.dart';
// // import 'package:get_thumbnail_video/index.dart';
// // import 'package:get_thumbnail_video/video_thumbnail.dart';
// import 'package:path_provider/path_provider.dart';
// // import 'package:video_thumbnail/video_thumbnail.dart';
//
// class CustomThumbnail {
//   static Future<String> onGet(String videoPath) async {
//     try {
//       final videoThumbnail = await VideoThumbnail.thumbnailFile(
//         video: videoPath,
//         thumbnailPath: (await getTemporaryDirectory()).path,
//         imageFormat: ImageFormat.JPEG,
//         timeMs: -1,
//         maxHeight: 400,
//         quality: 100,
//       );
//       return videoThumbnail.path;
//     } catch (e) {
//       logs("Get Thumbnail Error => $e");
//     }
//     return "";
//   }
// }
