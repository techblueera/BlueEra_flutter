import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../core/constants/app_enum.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import '../../../../../common/auth/model/adminvideo_model.dart';
import '../../../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';


class AppTutorialScreen extends StatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  final bottomBarController = Get.find<BottomBarController>();

  @override
  void initState() {
    super.initState();
    bottomBarController.fetchAllAdminVideoApiMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: CommonBackAppBar(
      title: "App Tutorial",
    ),
      body: Obx(() {
        if (bottomBarController.adminVideoLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bottomBarController.adminVideos.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noDataFound.tr,
              fontSize: SizeConfig.medium,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bottomBarController.adminVideos.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TutorialVideoCard(
                videoItem: bottomBarController.adminVideos[index],
                videoType: VideoType.latest,
              ),
            );
          },
        );
      }),
    );
  }
}

class TutorialVideoCard extends StatefulWidget {
  final AdminVideo videoItem;
  final VideoType videoType;

  const TutorialVideoCard({
    super.key,
    required this.videoItem,
    required this.videoType,
  });

  @override
  State<TutorialVideoCard> createState() => _TutorialVideoCardState();
}

class _TutorialVideoCardState extends State<TutorialVideoCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showControls = false;
  bool _isExpanded = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    final url = widget.videoItem.videoUrls?.first.url ?? '';

    _controller = VideoPlayerController.network(url)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _showControls = false;
    });

    if (!_isExpanded) {
      _controller?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          /// 🔹 TITLE ROW (CLICK TO EXPAND)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      widget.videoItem.title ?? '',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  )
                ],
              ),
            ),
          ),

          /// 🔹 EXPANDED CONTENT
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: const EdgeInsets.all(12),
              child: _videoContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= VIDEO UI (UNCHANGED) =================

  Widget _videoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
            onDoubleTap: _togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _initialized
                    ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
                    : Image.network(
                  widget.videoItem.thumbnailUrl ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                  ),
                ),

                if (!_controller!.value.isPlaying && !_showControls)
                  const Icon(
                    Icons.play_circle_fill,
                    size: 56,
                    color: Colors.white,
                  ),

                if (_showControls && _initialized) _controls(),

                if (_showControls && _initialized)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: PopupMenuButton<double>(
                      initialValue: _speed,
                      onSelected: (v) {
                        _controller!.setPlaybackSpeed(v);
                        setState(() => _speed = v);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 1.0, child: CustomText("1x")),
                        PopupMenuItem(value: 1.25, child: CustomText("1.25x")),
                        PopupMenuItem(value: 1.5, child: CustomText("1.5x")),
                        PopupMenuItem(value: 2.0, child: CustomText("2x")),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomText(
                          "${_speed}x",
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        CustomText(
          widget.videoItem.description ?? '',
          fontSize: SizeConfig.small,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  /// ================= CONTROLS (UNCHANGED) =================

  Widget _controls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.white),
              onPressed: _seekBack,
            ),
            IconButton(
              iconSize: 52,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: _togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.white),
              onPressed: _seekForward,
            ),
          ],
        ),
      ],
    );
  }

  /// ================= HELPERS =================

  void _togglePlayPause() {
    setState(() {
      _controller!.value.isPlaying
          ? _controller!.pause()
          : _controller!.play();
    });
  }

  void _seekForward() {
    _controller!.seekTo(
      _controller!.value.position + const Duration(seconds: 10),
    );
  }

  void _seekBack() {
    final pos =
        _controller!.value.position - const Duration(seconds: 10);
    _controller!.seekTo(pos > Duration.zero ? pos : Duration.zero);
  }
}