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
  final List<String>? videoUrls;
  final bool? isNetworkUrl;
  const HorizontalVideoPlayer({
    super.key,
    this.isAutoPlay = false,
    this.videoUrls,
    this.isNetworkUrl
  });

  @override
  State<HorizontalVideoPlayer> createState() => _HorizontalVideoPlayerState();
}

class _HorizontalVideoPlayerState extends State<HorizontalVideoPlayer>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  late List<String> _videoUrls;
  final List<String> thumbnailUrls = [
    AppImageAssets.earnWithBlueeraVideoThumbnail
  ];

  VideoPlayerController? _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoUrls = widget.videoUrls ?? ['assets/video/earn_with_blue_era_video.mp4'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController(_videoUrls[_currentPage]);
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
      _controller?.pause();
    }
    // Don't auto-resume on app resume - let user control it
  }

  // void _getVideoThumbnail(){
  //   XFile thumbnailFile = await VideoThumbnail.thumbnailFile(
  //       video: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
  //       thumbnailPath: (await getTemporaryDirectory()).path,
  //       imageFormat: ImageFormat.WEBP,
  //       maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
  //       quality: 75,
  //   );
  // }

  Future<void> _initializeController(String path) async {
    _disposeController();
    // if (!mounted) return; // ← ADD THIS

    if(widget.isNetworkUrl!=null){
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    }else{
      _controller = VideoPlayerController.asset(path);
    }


    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });

      if (widget.isAutoPlay) {
        _controller!.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      log('Video init failed: $e');
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  void _togglePlayPause() {
    if (_controller == null) {
      _initializeController(_videoUrls[_currentPage]);
      return;
    }

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
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
    if (_currentPage < _videoUrls.length - 1) {
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
        // Only pause when scrolled away - never auto-play
        if (info.visibleFraction < 0.5) {
          _controller?.pause();
        }
        // User must manually tap to play
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: _videoUrls.length,
          onPageChanged: (index) async {
            _currentPage = index;
            await _initializeController(_videoUrls[index]);
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
                  // Thumbnail (before load)
                  if (isCurrent &&
                      (controller == null || !controller.value.isInitialized))
                    (widget.isNetworkUrl!=null)
                    ? Center(child: CircularProgressIndicator())
                    : _buildThumbnail(thumbnailUrls[index]),

                  // Video player
                  if (isCurrent &&
                      controller != null &&
                      controller.value.isInitialized)
                    _buildVideo(controller),

                  if (!isCurrent) _buildDimmedBackground(),

                  // Play/Pause overlay
                  if (isCurrent &&
                      controller != null &&
                      controller.value.isInitialized) _buildPlayPauseOverlay(controller),

                  // Navigation buttons
                  if (_videoUrls.length > 1) _buildNavigationButtons(),
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

  Widget _buildDimmedBackground() => Container(
      color: Colors.black12, width: double.infinity, height: double.infinity);

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


