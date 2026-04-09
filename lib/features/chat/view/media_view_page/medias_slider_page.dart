import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/load_chat_medias_controller.dart';

class MediaSliderPage extends StatefulWidget {
  final String conversationId;
  final String seletedUrl;
  final String conversationPersonName;

  const MediaSliderPage({
    super.key,
    required this.conversationId,
    required this.conversationPersonName,
    required this.seletedUrl,
  });

  @override
  State<MediaSliderPage> createState() => _MediaSliderPageState();
}

class _MediaSliderPageState extends State<MediaSliderPage> {
  final controller = Get.isRegistered<LoadChatMediasController>()
      ? Get.find<LoadChatMediasController>()
      : Get.put(LoadChatMediasController());
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    super.initState();
    controller.loadOfflineMessages(widget.conversationId,widget.seletedUrl,chatViewController.getListOfMessageData??[]);

  }
  bool isNetworkUrl(String url) {
    return url.startsWith("http://") || url.startsWith("https://");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Obx(() {
        if (controller.allMediaResponse.value.status ==
            Status.COMPLETE) {
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  top: 28,
                  bottom: 18,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      controller.isBarsVisible.value =
                      !controller.isBarsVisible.value;
                    },
                    child: PageView.builder(
                      controller: controller.pageController,
                      physics: const PageScrollPhysics(),
                      itemCount: controller.allMedias.length,
                      itemBuilder: (context, index) {
                        final media = controller.allMedias[index];
                        final url = media.url ?? "";
                        final mimetype = media.mimetype ?? "";
                        Future.delayed(Duration.zero, () {
                          controller.onChangeMyMessage(media.myMessage);
                          controller.onChangeMessageTime(media.createdAt);
                          controller.onChangeMimeType(mimetype);
                        });

                        if (mimetype.contains("pdf")) {
                          return _buildPDFViewer(url);
                        } else if (mimetype.contains("video")) {
                          return _buildVideoPlayer(url);
                        } else {
                          return _buildImageViewer(url);
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: controller.isBarsVisible.value ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !controller.isBarsVisible.value,
                      child: Container(
                        height: 66,
                        padding: EdgeInsets.only(
                            left: SizeConfig.size20,
                            right: SizeConfig.size18,
                            top: SizeConfig.size4,
                        bottom: SizeConfig.size2),
                        color: AppColors.black.withOpacity(0.5),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => Get.back(),
                                  child: Icon(Icons.arrow_back_ios,
                                      color: AppColors.white),
                                ),
                                SizedBox(width: SizeConfig.size12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(() {
                                      if (controller.myMessage?.value ?? true) {
                                        return CustomText(AppStrings.youLabel.tr,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white);
                                      } else {
                                        return CustomText(
                                            "${widget.conversationPersonName}",
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white);
                                      }
                                    }),
                                    Obx(() {
                                      return CustomText(
                                          controller.createdAt?.value,
                                          fontSize: 14, color: AppColors.white);
                                    }),
                                  ],
                                ),
                              ],
                            ),
                            if(controller.mimeType.value.contains('pdf'))
                              Icon(Icons.picture_as_pdf,color: AppColors.white,)
                            else if(controller.mimeType.value.contains('video'))
                              Icon(Icons.video_camera_back_outlined,color: AppColors.white,)
                            else
                              Icon(Icons.image,color: AppColors.white,),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: controller.isBarsVisible.value ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !controller.isBarsVisible.value,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size14,
                            vertical: SizeConfig.size24),
                        color: AppColors.black.withOpacity(0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size12,
                                  vertical: SizeConfig.size5),
                              decoration: BoxDecoration(
                                color: AppColors.grayText,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.reply, color: AppColors.white),
                                  SizedBox(width: SizeConfig.size6),
                                  CustomText(AppStrings.replyLabel.tr,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
      }),
    );
  }

  Widget _buildImageViewer(String url) {
    final isNetwork = isNetworkUrl(url);

    return InteractiveViewer(
      maxScale: 8,
      child: isNetwork
          ? Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                const SizedBox(height: 8),
                CustomText(
                  AppStrings.failedToLoadImage.tr,
                 color: Colors.grey[600],
                ),
              ],
            ),
          );
        },
      )
        : Image.file(
        File(url),
        fit: BoxFit.contain,
      ),
    );
  }
  Future<String> _preparePdf(String url) async {
    if (!isNetworkUrl(url)) return url;

    final bytes = await HttpClient().getUrl(Uri.parse(url)).then((r) => r.close()).then((r) => r.fold<List<int>>([], (p, e) => p..addAll(e)));

    final temp = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
    await temp.writeAsBytes(bytes);

    return temp.path;
  }

  Widget _buildPDFViewer(String url) {
    return FutureBuilder(
      future: _preparePdf(url),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final localPath = snapshot.data!;
        return _pdfView(localPath);
      },
    );
  }

  Widget _pdfView(String filePath) {
    return PDFView(
      filePath: filePath,
      enableSwipe: true,
      fitEachPage: true,
    );
  }


  Widget _buildVideoPlayer(String url) {
    final isNetwork = isNetworkUrl(url);

    return VideoPlayerWidget(
      videoPath: url,
      isNetwork: isNetwork,
    );
  }

}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool isNetwork;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    required this.isNetwork,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController controller;
  bool isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.isNetwork) {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))..initialize().then((_) {
        setState(() {});
      });
    } else {
      controller = VideoPlayerController.file(File(widget.videoPath))..initialize().then((_) {
        setState(() {});
      });
    }

      ;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return
      // GestureDetector(
      // onTap: () {
      //   setState(() {
      //     isControlsVisible = !isControlsVisible;
      //   });
      // },
      // child:
      Stack(
        alignment: Alignment.center,
        children: [

          /// 🔥 FULL SCREEN RESPONSIVE VIDEO
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover, // FULL SCREEN
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),

          /// 🔥 Play / Pause Controls
          if (isControlsVisible)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black.withOpacity(0.4),
                ),
                child: IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                      // if(controller.value.isPlaying){
                      //     isControlsVisible =false;
                      //
                      // }
                    });
                  },
                ),
              ),
            ),
        ],
      );

  }
}

class FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
