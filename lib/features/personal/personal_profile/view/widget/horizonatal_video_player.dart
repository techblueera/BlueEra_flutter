import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HorizontalVideoPlayer extends StatefulWidget {
  const HorizontalVideoPlayer({super.key});

  @override
  State<HorizontalVideoPlayer> createState() => _HorizontalVideoPlayerState();
}

class _HorizontalVideoPlayerState extends State<HorizontalVideoPlayer> {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  // final List<String> videoUrls = [
  //   'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  //   'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  // ];
  final List<String> videoUrls = [
    'assets/video/earn_with_blue_era_video.mp4'
  ];

  VideoPlayerController? _controller;
  int _currentPage = 0;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeController(videoUrls[_currentPage]);
  }

  Future<void> _initializeController(String url) async {
    // Prevent multiple init calls
    if (_isInitializing) return;
    _isInitializing = true;

    // Dispose old controller
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }

    final controller = VideoPlayerController.asset(url);
    // final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setLooping(true);
    controller.play();

    setState(() {
      _controller = controller;
      _isInitializing = false;
    });
  }

  void _onPlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _onPreviousVideo() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _initializeController(videoUrls[_currentPage - 1]);
    }
  }

  void _onNextVideo() {
    if (_currentPage < videoUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _initializeController(videoUrls[_currentPage + 1]);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return VisibilityDetector(
      key: const ValueKey("HorizontalVideoPlayer"),
      onVisibilityChanged: (info) {
        final visibleFraction = info.visibleFraction;

        // If the widget is less than 50% visible → pause video
        if (visibleFraction < 0.5) {
          if (controller != null && controller.value.isPlaying) {
            controller.pause();
            if(!mounted) return;
            setState(() {});
          }
        }
        // else {
        //   if (controller != null && !controller.value.isPlaying) {
        //     controller.play();
        //   }
        // }
      },
      child: AspectRatio(
        aspectRatio: 16/9,
        // width: SizeConfig.screenWidth,
        // color: Colors.red,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: videoUrls.length,

          onPageChanged: (index) async {
            _currentPage = index;
            await _initializeController(videoUrls[index]);
          },
          itemBuilder: (context, index) {
            final isCurrent = index == _currentPage;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isCurrent ? _onPlayPause : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isCurrent && controller != null && controller.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16/9,
                        // width: controller.value.size.width,
                        // height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),

                  // Play/Pause overlay button
                  if (isCurrent)
                    GestureDetector(
                      child: AnimatedOpacity(
                        opacity: (controller?.value.isPlaying ?? false) ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                (controller?.value.isPlaying ?? false)
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Previous Video

                  if(videoUrls.length > 1)
                    Positioned(
                      left: 8,
                      child: GestureDetector(
                        onTap: _onPreviousVideo,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.chevron_left,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if(videoUrls.length > 1)
                    Positioned(
                      right: 8,
                      child: GestureDetector(
                        onTap: _onNextVideo,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.chevron_right,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
