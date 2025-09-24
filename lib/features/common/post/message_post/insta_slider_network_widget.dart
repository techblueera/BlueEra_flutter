import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:ui' as ui;

class InstaSliderNetwork extends StatefulWidget {
  const InstaSliderNetwork({
    super.key,
  });

  @override
  State<InstaSliderNetwork> createState() => _InstaSliderNetworkState();
}

class _InstaSliderNetworkState extends State<InstaSliderNetwork> {
  int _currentPage = 0;
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: 250,
      // height: Get.width * 0.5,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView.builder(
        itemCount: msgPostController.uploadImageList.length,
        scrollDirection: Axis.horizontal,
        // swipe left/right
        controller: PageController(viewportFraction: 1.0),
        // full width page
        onPageChanged: (index) {
          _currentPage = index;
          setState(() {});
        },
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 250,
                    // height: Get.width * 0.5,
                    width: 250,
                    // width: Get.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      image: DecorationImage(
                        image: NetworkImage(
                            msgPostController.uploadImageList[index]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              if (msgPostController.uploadImageList.length > 1)
                // --- Page Indicator ---
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      "${_currentPage + 1}/${msgPostController.uploadImageList.length}",
                      color: Colors.white,
                    ),
                  ),
                ),

              /// --- Debug: Show image width ---
            ],
          );
        },
      ),
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
//                           color: Colors.black.withOpacity(0.6),
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
