import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullVideoPreview extends StatefulWidget {
  final String videoPath;
  final PostVia? argPostVia;
  FullVideoPreview({required this.videoPath, this.argPostVia});

  @override
  State<FullVideoPreview> createState() => _FullVideoPreviewState();
}

class _FullVideoPreviewState extends State<FullVideoPreview> with RouteAware {
  VideoPlayerController? _controller;
  String _videoPath = '';
  Duration? _videoDuration;
  Video videoType = Video.short;

  @override
  void initState() {
    super.initState();
    _videoPath = widget.videoPath;
    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Navigating to a new screen
    _controller?.pause();
  }

  @override
  void didPopNext() {
    // Came back from another screen
    _controller?.play();
  }


  void _initializeVideo(){
    _controller = VideoPlayerController.file(File(_videoPath))
      ..initialize().then((_) {
        _setVideoTypeBasedOnAspectRatio(); // auto detect type
        _getVideoDuration();
        setState(() {});
      })
      ..setLooping(true)
      ..setVolume(1.0)
      ..play();;
  }

  void _getVideoDuration() {
    final duration = _controller?.value.duration;

    if (duration != null) {
      setState(() {
        _videoDuration = duration;
      });
      print("Video duration: ${duration.inSeconds} seconds");
    } else {
      print("Failed to get video duration");
    }
  }

  void _setVideoTypeBasedOnAspectRatio() {
    final size = _controller!.value.size;
    final aspectRatio = size.width / size.height;

    if (aspectRatio >= 1.5) {
      // Roughly 16:9 or wider
      videoType = Video.video; // long video
    } else {
      // Roughly vertical (e.g., 9:16)
      videoType = Video.short;
    }
    log("videoType --> $videoType");
    setState(() {});
  }

  Future<void> _goToTrimScreen() async {
    log("go to trim");
    final result = await Navigator.pushNamed(
      context,
      RouteHelper.getVideoTrimScreenRoute(),
      arguments: {
        ApiKeys.videoPath: widget.videoPath,
        ApiKeys.videoType: videoType,
        ApiKeys.isFrom: RouteConstant.fullVideoPreview},
    ) as String?;

    if (result != null && result.isNotEmpty) {
      setState(() {
        _videoPath = result;
      });
    }
  }

  Widget _buildVideoPlayer() {
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }

    final videoSize = _controller!.value.size;
    final aspectRatio = videoSize.width / videoSize.height;

    // Choose fit based on aspect ratio: vertical videos (reels) => cover, horizontal => contain
    final fit = aspectRatio < 0.8 ? BoxFit.cover : BoxFit.contain;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: FittedBox(
            fit: fit,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: "Video Preview",
        // isTrimmedButton: widget.videoType == VideoType.short,
        // onTrimmedTap: (widget.videoType == VideoType.short) ? ()=> _goToTrimScreen() : null,
      ),
      body: Stack(
        children: [
          _buildVideoPlayer(),
          Positioned(
            bottom: SizeConfig.size40,
            left: SizeConfig.size20,
            right: SizeConfig.size20,
            child: CustomBtn(
              onTap: () async {
                if (videoType == Video.short && (_videoDuration?.inSeconds ?? 0) > 600) {
                  await showCommonDialog(
                    context: context,
                    text: "The selected video is longer than 600 seconds.",
                    confirmCallback: () => Navigator.of(context).pop(),
                    // confirmCallback: () => _goToTrimScreen(),
                    cancelCallback: () => Navigator.of(context).pop(),
                    confirmText: 'Yes',
                    cancelText: 'No',
                  );
                  return;
                }
                Navigator.pushNamed(
                  context,
                  RouteHelper.getCreateReelScreenRoute(),
                  arguments: {
                    ApiKeys.videoPath: _videoPath,
                    ApiKeys.videoType: videoType,
                    ApiKeys.argPostVia: widget.argPostVia
                  },
                );

                // await _handleVideoCompressionAndNavigate(File(_videoPath), context, widget.videoType);

              },
              title: 'Continue',
              isValidate: true,
            ),
          )
        ],
      ),
    );
  }
}

// Future<void> _handleVideoCompressionAndNavigate(
//     File videoFile,
//     BuildContext context,
//     VideoType videoType,
//     ) async {
//
//   try {
//     // Step 1: Show loading dialog
//     _showSimpleCompressionDialog(context);
//
//     // Step 2: Compress the video (showing the dialog during compression)
//     final File compressedFile = await compressVideoIfNeeded(context, videoFile);
//
//     // Step 3: Close the dialog after compression
//     if (context.mounted) Navigator.pop(context);
//
//     // Step 4: Navigate to CreateReelScreen with compressed file path
//     if (context.mounted) {
//       Navigator.pushNamed(
//         context,
//         RouteHelper.getCreateReelScreenRoute(),
//         arguments: {
//           ApiKeys.videoPath: compressedFile.path,
//           ApiKeys.videoType: videoType,
//         },
//       );
//     }
//   } catch (e) {
//     // Step 5: Ensure dialog is dismissed on error
//     if (context.mounted) Navigator.pop(context);
//     print("❗ Compression failed: $e");
//     // You can show a snackbar or alert here if needed
//   }
// }
//
//
// void _showSimpleCompressionDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (_) {
//       return WillPopScope(
//         onWillPop: () async => false,
//         child: AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.0)
//           ),
//           content: Row(
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(width: 16),
//               const Expanded(child: Text("Video is compressing...")),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

