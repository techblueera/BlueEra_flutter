import 'dart:developer';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HorizontalVideoPlayer extends StatefulWidget {
  final bool isAutoPlay;
  const HorizontalVideoPlayer({super.key, this.isAutoPlay = false});

  @override
  State<HorizontalVideoPlayer> createState() => _HorizontalVideoPlayerState();
}

class _HorizontalVideoPlayerState extends State<HorizontalVideoPlayer>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  final List<String> videoUrls = ['assets/video/earn_with_blue_era_video.mp4'];
  final List<String> thumbnailUrls = [
    AppImageAssets.earnWithBlueeraVideoThumbnail
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      log('App background → pause video');
      _pauseVideo();
    } else if (state == AppLifecycleState.resumed) {
      log('App resumed → maybe resume video');
      if (_isVisible && !_isUserPaused) _playVideo();
    }
  }

  Future<void> _initializeController(String path) async {
    _disposeController();

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    log('Current route active: $isCurrentRoute');

    if (!isCurrentRoute) {
      log('Skipping video init: not current route');
      return;
    }

    _controller = VideoPlayerController.asset(path);

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.addListener(_onVideoControllerUpdated);

      if (widget.isAutoPlay && _isVisible && !_isUserPaused) {
        _controller!.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      log('Video init failed: $e');
    }
  }

  void _onVideoControllerUpdated() {
    if (!context.mounted) return;
    setState(() {});
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  void _pauseVideo() {
    if (_controller?.value.isPlaying ?? false) _controller?.pause();
  }

  void _playVideo() {
    if (!(_controller?.value.isPlaying ?? true)) _controller?.play();
  }

  void _togglePlayPause() {
    if (_controller == null) {
      _isUserPaused = false;
      _initializeController(videoUrls[_currentPage]);
      return;
    }

    if (_controller!.value.isPlaying) {
      _pauseVideo();
      _isUserPaused = true;
    } else {
      _playVideo();
      _isUserPaused = false;
    }

    setState(() {});
  }

  void _goToPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNext() {
    if (_currentPage < videoUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('HorizontalVideoPlayer_${identityHashCode(this)}'),
      onVisibilityChanged: (info) {
        final visibleFraction = info.visibleFraction;
        final wasVisible = _isVisible;
        _isVisible = visibleFraction >= 0.5;

        if (!wasVisible && _isVisible && !_isUserPaused) {
          log('Video became visible → resume');
          _playVideo();
        } else if (wasVisible && !_isVisible) {
          log('Video became hidden → pause');
          _pauseVideo();
        }
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: videoUrls.length,
          onPageChanged: (index) async {
            _currentPage = index;
            _isUserPaused = false;
            await _initializeController(videoUrls[index]);
          },
          itemBuilder: (context, index) {
            final isCurrent = index == _currentPage;
            final controller = _controller;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isCurrent ? _togglePlayPause : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- Thumbnail (before load) ---
                  if (isCurrent &&
                      (controller == null || !controller.value.isInitialized))
                    _buildThumbnail(thumbnailUrls[index]),

                  // --- Video player ---
                  if (isCurrent &&
                      controller != null &&
                      controller.value.isInitialized)
                    _buildVideo(controller),

                  if (!isCurrent) _buildDimmedBackground(),

                  // --- Play overlay button ---
                  if (isCurrent) _buildPlayPauseOverlay(controller),

                  // --- Navigation buttons ---
                  if (videoUrls.length > 1) _buildNavigationButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnail(String thumbnail) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LocalAssets(imagePath: thumbnail, boxFix: BoxFit.cover),
  );

  Widget _buildVideo(VideoPlayerController controller) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: VideoPlayer(controller),
  );

  Widget _buildDimmedBackground() =>
      Container(color: Colors.black12, width: double.infinity, height: double.infinity);

  Widget _buildPlayPauseOverlay(VideoPlayerController? controller) {
    final isPlaying = controller?.value.isPlaying ?? false;
    return AnimatedOpacity(
      opacity: isPlaying ? 0.0 : 1.0,
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
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() => Stack(
    children: [
      Positioned(
        left: 8,
        child: _navButton(Icons.chevron_left, _goToPrevious),
      ),
      Positioned(
        right: 8,
        child: _navButton(Icons.chevron_right, _goToNext),
      ),
    ],
  );

  Widget _navButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    ),
  );
}
