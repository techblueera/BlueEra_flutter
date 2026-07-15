import 'dart:developer';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/model/referral_testimonial_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HorizontalVideoPlayer extends StatefulWidget {
  final bool isAutoPlay;
  final List<String>? videoUrls;
  final bool? isNetworkUrl;

  /// Aspect ratio of the player box. Defaults to 16:9 (landscape). Pass a
  /// smaller value (e.g. 3/4, 9/16) to make the player taller for portrait
  /// content. Also used as the placeholder ratio while a video initializes.
  final double aspectRatio;

  /// When true, once a video is initialized the box adopts the video's own
  /// aspect ratio (so portrait clips render tall and undistorted) instead of
  /// the fixed [aspectRatio]. [aspectRatio] then acts as the loading fallback.
  final bool useVideoAspectRatio;

  /// Shows a mute / unmute toggle in the top-right corner of the player.
  final bool showMuteButton;

  const HorizontalVideoPlayer({
    super.key,
    this.isAutoPlay = false,
    this.videoUrls,
    this.isNetworkUrl,
    this.aspectRatio = 16 / 9,
    this.useVideoAspectRatio = false,
    this.showMuteButton = false,
  });

  @override
  State<HorizontalVideoPlayer> createState() => _HorizontalVideoPlayerState();
}

class _HorizontalVideoPlayerState extends State<HorizontalVideoPlayer>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  // Used only when no [videoUrls] are supplied — the intro/overview video is
  // pulled from GET /earn-service/overview instead of being bundled in the app.
  final ReferralController _referralController =
      getOrPut(() => ReferralController());
  Worker? _overviewWorker;

  List<String> _videoUrls = const [];
  // Overview videos are always remote; explicitly-passed URLs honour the
  // widget's [isNetworkUrl] flag.
  bool _isNetworkUrl = false;
  // True when the URL list is being sourced from the overview API (so the
  // build can show a loader while it resolves).
  bool _usingOverview = false;

  VideoPlayerController? _controller;
  int _currentPage = 0;
  // Sound state for the mute/unmute toggle. Starts unmuted so the video plays
  // with audio the first time the screen opens; the user can mute it.
  bool _isMuted = false;

  /// The ratio the player box should use right now — the initialized video's
  /// own ratio when [useVideoAspectRatio] is on, otherwise the fixed
  /// [widget.aspectRatio] (also the fallback while a video loads).
  double get _effectiveAspectRatio {
    if (widget.useVideoAspectRatio) {
      final c = _controller;
      if (c != null && c.value.isInitialized && c.value.aspectRatio > 0) {
        return c.value.aspectRatio;
      }
    }
    return widget.aspectRatio;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provided = widget.videoUrls;
    if (provided != null && provided.isNotEmpty) {
      _videoUrls = List<String>.from(provided);
      _isNetworkUrl = widget.isNetworkUrl != null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeController(_videoUrls[_currentPage]);
      });
    } else {
      // No explicit URLs → fetch the intro video from the overview API rather
      // than shipping a heavy local asset. Overview videos are remote.
      _usingOverview = true;
      _isNetworkUrl = true;
      _bindOverviewVideos();
    }
  }

  /// Subscribes to the controller's overview list, applies whatever is already
  /// cached, and triggers a fresh fetch. Video URLs are derived from overview
  /// posts that carry a video.
  void _bindOverviewVideos() {
    _overviewWorker = ever<List<ReferralTestimonial>>(
        _referralController.overviews, _applyOverviewVideos);
    if (_referralController.overviews.isNotEmpty) {
      _applyOverviewVideos(_referralController.overviews);
    }
    _referralController.fetchOverview();
  }

  void _applyOverviewVideos(List<ReferralTestimonial> list) {
    if (!mounted) return;
    final urls =
        list.where((o) => o.hasVideo).map((o) => o.video!).toList();
    // Skip a redundant re-init when the URL set hasn't changed.
    if (urls.join(',') == _videoUrls.join(',')) {
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _videoUrls = urls;
      _currentPage = 0;
    });
    if (urls.isNotEmpty) {
      _initializeController(urls[_currentPage]);
    } else {
      _disposeController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overviewWorker?.dispose();
    _disposeController();
    // The controller listener can't clear the flag from dispose (mounted
    // is already false), so release it explicitly — otherwise the
    // testimonial grid would stay suppressed after leaving the screen.
    _referralController.overviewVideoPlaying.value = false;
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

  Future<void> _initializeController(String path) async {
    _disposeController();
    // if (!mounted) return; // ← ADD THIS

    if (_isNetworkUrl) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.asset(path);
    }


    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      // Apply the current mute state before playback starts.
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      _controller!.addListener(_onControllerTick);

      if (widget.isAutoPlay) {
        _controller!.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      log('Video init failed: $e');
    }
  }

  /// Rebuilds on controller updates and mirrors the play state to
  /// [ReferralController.overviewVideoPlaying] so the testimonial grid can
  /// pause its autoplay while this intro video is playing.
  void _onControllerTick() {
    if (!mounted) return;
    setState(() {});
    final playing = _controller?.value.isPlaying ?? false;
    if (_referralController.overviewVideoPlaying.value != playing) {
      _referralController.overviewVideoPlaying.value = playing;
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
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
    // No video to show yet: keep the 16:9 slot with a loader while the
    // overview API resolves, otherwise render nothing.
    if (_videoUrls.isEmpty) {
      final status = _referralController.overviewResponse.value.status;
      final loading = _usingOverview &&
          (status == Status.LOADING || status == Status.INITIAL);
      return AspectRatio(
        aspectRatio: _effectiveAspectRatio,
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const SizedBox.shrink(),
        ),
      );
    }
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
        aspectRatio: _effectiveAspectRatio,
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
                  // Loader (before the video is initialized)
                  if (isCurrent &&
                      (controller == null || !controller.value.isInitialized))
                    const Center(child: CircularProgressIndicator()),

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

                  // Mute / unmute toggle (top-right), above the play/pause.
                  if (widget.showMuteButton &&
                      isCurrent &&
                      controller != null &&
                      controller.value.isInitialized)
                    _buildMuteButton(),

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

  // Circular glass mute/unmute button pinned to the player's top-right,
  // mirroring the nav-button styling.
  Widget _buildMuteButton() => Positioned(
        top: 8,
        right: 8,
        child: GestureDetector(
          onTap: _toggleMute,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );

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
