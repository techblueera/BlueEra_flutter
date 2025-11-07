import 'dart:developer';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HorizontalVideoPlayer extends StatefulWidget {
  const HorizontalVideoPlayer({super.key});

  @override
  State<HorizontalVideoPlayer> createState() => _HorizontalVideoPlayerState();
}

class _HorizontalVideoPlayerState extends State<HorizontalVideoPlayer>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  final List<String> videoUrls = [
    'assets/video/earn_with_blue_era_video.mp4'
  ];

  // Optional: Add thumbnail paths (same order as videoUrls)
  final List<String> thumbnailUrls = [
    AppImageAssets.earnWithBlueeraVideoThumbnail // Add your thumbnail image
  ];

  VideoPlayerController? _controller;
  int _currentPage = 0;
  bool _isUserPaused = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController(videoUrls[_currentPage]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      log('App going to background - disposing controller');
      _disposeController();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      log('App resumed - reinitializing if visible');
      if (_isVisible && !_isUserPaused) {
        _initializeController(videoUrls[_currentPage]);
      }
    }
  }

  Future<void> _initializeController(String url) async {
    // Dispose old controller first
    _controller?.dispose();

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    log('Current route active: $isCurrentRoute');

    if (!isCurrentRoute) {
      log('Skipping video init: not current route');
      return;
    }

    _controller = VideoPlayerController.asset(url);

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);

      // Only play if visible and user hasn't paused
      if (!_isUserPaused && _isVisible && mounted) {
        log('Auto-playing video');
        _controller!.play();
      } else {
        log('Not auto-playing - userPaused: $_isUserPaused, visible: $_isVisible');
      }

      if (mounted) setState(() {});
    } catch (e) {
      log('Error initializing video: $e');
    }
  }

  void _disposeController() {
    if (_controller != null) {
      log('Disposing controller completely');
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
  }

  void _onPlayPause() {
    if (_controller == null) {
      // Controller was disposed, reinitialize it
      _isUserPaused = false;
      _initializeController(videoUrls[_currentPage]);
      return;
    }

    setState(() {
      if (_controller!.value.isPlaying) {
        log('User paused video');
        _controller!.pause();
        _isUserPaused = true;
      } else {
        log('User resumed video');
        _controller!.play();
        _isUserPaused = false;
      }
    });
  }

  void _onPreviousVideo() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onNextVideo() {
    if (_currentPage < videoUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return VisibilityDetector(
      key: Key('HorizontalVideoPlayer_${identityHashCode(this)}'),
      onVisibilityChanged: (info) {
        final visibleFraction = info.visibleFraction;

        log('Visibility: ${(visibleFraction * 100).toStringAsFixed(0)}%');

        _isVisible = visibleFraction >= 0.5;

        if (visibleFraction < 0.5) {
          // Destroy the controller when not visible
          if (_controller != null) {
            log('Widget < 50% visible - DESTROYING controller');
            _disposeController();
            if (!mounted) return;
            setState(() {});
          }
        } else {
          // Recreate the controller when visible again
          if (_controller == null && !_isUserPaused) {
            log('Widget >= 50% visible - RECREATING controller');
            _initializeController(videoUrls[_currentPage]);
          }
        }
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: videoUrls.length,
          onPageChanged: (index) async {
            log('Page changed to: $index');
            _currentPage = index;
            _isUserPaused = false;
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
                  // Thumbnail (shown when video is not initialized)
                  if (isCurrent && (controller == null || !controller.value.isInitialized))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child:    // Show thumbnail image
                        LocalAssets(
                          imagePath: thumbnailUrls[index],
                          boxFix: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Video player (shown when initialized)
                  if (isCurrent && controller != null && controller.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(controller),
                      ),
                    ),

                  // Fallback for non-current pages
                  if (!isCurrent)
                    Container(
                      color: Colors.black12,
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

                  // Previous button
                  if (videoUrls.length > 1)
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

                  // Next button
                  if (videoUrls.length > 1)
                    Positioned(
                      right: 8,
                      child: GestureDetector(
                        onTap: _onNextVideo,
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