
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/feed_network_video_preview_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InstaSliderNetwork extends StatefulWidget {
  const InstaSliderNetwork({
    super.key,
    required this.post,
  });

  final Post? post;

  @override
  State<InstaSliderNetwork> createState() => _InstaSliderNetworkState();
}

class _InstaSliderNetworkState extends State<InstaSliderNetwork> {
  int _currentPage = 0;
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            widget.post?.media_types?.firstOrNull == "video/mp4" ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: msgPostController.uploadImageList.length,
      itemBuilder: (context, index) {
        final file = msgPostController.uploadImageList[index];
        final isVideo = widget.post?.media_types?.firstOrNull == "video/mp4";
        final thumb = widget.post?.thumbnail;

        return GestureDetector(
          onTap: isVideo
              ? () {
                  Get.to(NetworkVideoPreviewScreen(
                    videoUrl: widget.post?.media?.firstOrNull ?? "",
                  ));
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isVideo
                    ? (thumb != null
                    ? Image.network(widget.post?.thumbnail ?? "",
                    fit: BoxFit.cover)
                    : Container(
                  color: Colors.black12,
                  child: const Center(
                      child: CircularProgressIndicator()),
                ))
                    : Image.network(file, fit: BoxFit.cover),
              ),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 40),
                ),

            ],
          ),
        );
      },
    );
  }
}

// class MediaViewer extends StatefulWidget {
//   final List<String> mediaUrlList;
//
//   const MediaViewer({super.key, required this.mediaUrlList});
//
//   @override
//   State<MediaViewer> createState() => _MediaViewerState();
// }
//
// class _MediaViewerState extends State<MediaViewer> {
//   int _currentPage = 0;
//   Map<String, String> imageOrientation = {}; // cache url → orientation
//
//   Future<String> _getImageOrientation(String url) async {
//     if (imageOrientation.containsKey(url)) {
//       return imageOrientation[url]!;
//     }
//
//     final completer = Completer<ui.Image>();
//     final stream = NetworkImage(url).resolve(const ImageConfiguration());
//
//     stream.addListener(
//       ImageStreamListener((info, _) {
//         completer.complete(info.image);
//       }),
//     );
//
//     final ui.Image image = await completer.future;
//
//     String type;
//     if (image.width > image.height) {
//       type = "landscape";
//     }
//     /*else if (image.height > image.width) {
//       type = "portrait";
//     }*/
//     else {
//       type = "square";
//     }
//
//     imageOrientation[url] = type;
//     return type;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: Get.width * 0.5,
//       padding: EdgeInsets.zero,
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: PageView.builder(
//         itemCount: widget.mediaUrlList.length,
//         controller: PageController(viewportFraction: 1.0),
//         onPageChanged: (index) {
//           _currentPage = index;
//           setState(() {});
//         },
//         itemBuilder: (context, index) {
//           final url = widget.mediaUrlList[index];
//
//           return FutureBuilder<String>(
//             future: _getImageOrientation(url),
//             builder: (context, snapshot) {
//               String orientation = snapshot.data ?? "loading";
//
//               double height = Get.width * 0.5;
//               double width = Get.width;
//               logs("orientation===$orientation");
//               /* if (orientation == "portrait") {
//                 height = Get.height * 0.5; // taller
//                 width = Get.width * 0.7;
//               } else*/
//               if (orientation == "landscape") {
//                 height = Get.width * 0.5; // shorter
//                 width = Get.width;
//               } else if (orientation == "square") {
//                 height = Get.width * 0.5;
//                 width = Get.width * 0.5;
//               }
//
//               return Stack(
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       navigatePushTo(
//                         context,
//                         ImageViewScreen(
//                           subTitle: widget.subTitle,
//                           appBarTitle:
//                               AppLocalizations.of(context)!.imageViewer,
//                           imageUrls: widget.mediaUrlList,
//                           initialIndex: index,
//                         ),
//                       );
//                     },
//                     child: Center(
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(
//                             (orientation == "square") ? 0 : 12),
//                         child: Container(
//                           height: height,
//                           width: width,
//                           decoration: BoxDecoration(
//                             image: DecorationImage(
//                               image: NetworkImage(url),
//                               fit: BoxFit.fitWidth,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Page indicator
//                   if (widget.mediaUrlList.length > 1)
//                     Positioned(
//                       top: 12,
//                       right: 12,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.6),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: CustomText(
//                           "${_currentPage + 1}/${widget.mediaUrlList.length}",
//                          color: Colors.white,
//                         ),
//                       ),
//                     ),
//
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
