import 'dart:io';

import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../auth/model/messageMediaUrl.dart';
import 'custom_video_player.dart';

class FullImagePreviewPage extends StatelessWidget {
  final List<MessageMediaUrl> images;
  final int initialIndex;
  bool? isFromComment;

  FullImagePreviewPage({
    super.key,
    required this.images,
    required this.initialIndex,
    this.isFromComment
  });

  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);

  bool isVideo(String url) {
    return url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mkv');
  }


  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: initialIndex);
    currentIndexNotifier.value = initialIndex;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Medias",
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              child: PageView.builder(
                scrollDirection: Axis.horizontal,
                controller: controller,
                itemCount: images.length,
                onPageChanged: (index) => currentIndexNotifier.value = index,
                itemBuilder: (context, index) {
                  final media = images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (isVideo(media.url??''))
                        ? ChatCustomVideoPlayer(videoUrl: media.url ?? '',isFromComment: isFromComment,)
                        : InteractiveViewer(
                          child: (media.url!.contains('http'))?Image.network(
                                                media.url ?? '',
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ):Image.file(
                                                File(media.url ?? ''),
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ),
                        ),
                  );
                },
              ),
            ),

            // 🔢 Page count indicator (e.g. 2 / 5)
            Positioned(
              top: 16,
              right: 20,
              child: ValueListenableBuilder<int>(
                valueListenable: currentIndexNotifier,
                builder: (context, value, _) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${value + 1} / ${images.length}',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
