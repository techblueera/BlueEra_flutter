import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/auth/model/adminvideo_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ListOfAppTutorialVideoView extends StatefulWidget {
  const ListOfAppTutorialVideoView({
    super.key,
    this.videosUrl,
    required this.tittle,
  });

  final String tittle;
  final List<VideoUrl>? videosUrl;

  @override
  State<ListOfAppTutorialVideoView> createState() =>
      _ListOfAppTutorialVideoViewState();
}

class _ListOfAppTutorialVideoViewState
    extends State<ListOfAppTutorialVideoView> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    final url = widget.videosUrl?.first.url ?? '';

    _controller = VideoPlayerController.network(url);

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _hasError = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _hasError = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      appBar: CommonBackAppBar(
        backArrowColor: AppColors.white,
        titleColor: AppColors.white,
        title: widget.tittle,
        appBarColor: Colors.black12,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildVideoContent(),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- VIDEO CONTENT ----------------

  Widget _buildVideoContent() {
    if (_hasError) {
      return _errorWidget();
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),

        /// PLAY BUTTON
        if (!_isPlaying)
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.play();
                _isPlaying = true;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
      ],
    );
  }

  /// ---------------- ERROR UI ----------------

  Widget _errorWidget() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.play_disabled,
            color: Colors.grey,
            size: 40,
          ),
          SizedBox(height: 6),
          Text(
            "Video unavailable",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}