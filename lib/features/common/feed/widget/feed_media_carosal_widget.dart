import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_tag_button.dart';
import 'package:BlueEra/features/common/feed/widget/video_player.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/feed_tag_people_bottom_sheet.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../post/message_post/insta_slider_network_widget.dart';
import 'dart:ui' as ui;

class FeedMediaCarouselWidget extends StatefulWidget {
  final String subTitle;
  final List<User> taggedUser;
  final List<String> mediaUrls;
  final String postedAgo;
  final String totalViews;
  final String? audioUrl; // Add audio URL parameter
  final Widget Function()? buildTranslationWidget;
  final Widget Function(int currentPage)? buildIndicatorDots;

  const FeedMediaCarouselWidget({
    super.key,
    required this.taggedUser,
    required this.mediaUrls,
    required this.postedAgo,
    required this.totalViews,
    required this.subTitle,
    this.audioUrl,
    this.buildTranslationWidget,
    this.buildIndicatorDots,
  });

  @override
  State<FeedMediaCarouselWidget> createState() =>
      _FeedMediaCarouselWidgetState();
}

class _FeedMediaCarouselWidgetState extends State<FeedMediaCarouselWidget>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isAudioEnabled = false;
  bool _isLoadingAudio = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isVisible = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late Map<String, String> _orientationCache;

  @override
  void initState() {
    super.initState();
    _orientationCache = {};
    for (var url in widget.mediaUrls) {
      _getImageOrientation(url).then((orientation) {
        setState(() {
          _orientationCache[url] = orientation;
        });
      });
    }
    _audioPlayer = AudioPlayer();
    _initializeAudio();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeAudio() async {
    if (widget.audioUrl == null) return;

    // Preload audio but don't play yet
    await _audioPlayer.setSourceUrl(widget.audioUrl!);

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoadingAudio = false;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  MediaType getTypeFromUrl(String url) {
    final ext = url.toLowerCase();
    if (ext.endsWith('.mp4') || ext.endsWith('.mov')) return MediaType.video;
    return MediaType.image;
  }

  Future<void> _toggleAudio() async {
    if (widget.audioUrl == null) return;

    try {
      setState(() => _isLoadingAudio = true);

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          await _audioPlayer.resume(); // 👈 instant play after preloaded
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _pauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isFullyVisible =
        info.visibleFraction >= 0.8; // 80% visibility threshold

    if (!mounted) return;

    if (_isVisible != isFullyVisible) {
      setState(() => _isVisible = isFullyVisible);

      if (!isFullyVisible && _isPlaying) {
        _pauseAudio();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return MediaViewer(
    //   mediaUrlList: widget.mediaUrls,
    // );
    return VisibilityDetector(
      key: Key('feed-carousel-${widget.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: SizedBox(
        height: SizeConfig.size250,
        // height: Get.width * 0.4,

        child: Stack(
          children: [
            PageView.builder(
              itemCount: _orientationCache.length,
              // itemCount: widget.mediaUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final url = widget.mediaUrls[index];
                final mediaType = getTypeFromUrl(url);
                if (mediaType == MediaType.video) {
                  return VideoPlayerWidget(videoUrl: url);
                } else {
                  final url = widget.mediaUrls[index];
                  final orientation = _orientationCache[url] ?? "loading";

                  double height = 250;
                  double width = Get.width;/*      double height = Get.width * 0.5;
                  double width = Get.width;*/
                  /* if (orientation == "portrait") {
                  height = Get.height * 0.5; // taller
                  width = Get.width * 0.7;
                } else*/
                  // if (orientation == "landscape") {
                  //   height = Get.width * 0.5; // shorter
                  //   width = Get.width;
                  // } else if (orientation == "square") {
                  //   height = Get.width * 0.5;
                  //   width = Get.width * 0.5;
                  // }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      // height: Get.width * 0.5,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              navigatePushTo(
                                context,
                                ImageViewScreen(
                                  subTitle: widget.subTitle,
                                  appBarTitle:
                                      AppLocalizations.of(context)!.imageViewer,
                                  imageUrls: widget.mediaUrls,
                                  initialIndex: index,
                                ),
                              );
                            },
                            child: Center(
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                width: width,
                                height: height,
                                placeholder: (context, _) => const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, _, __) =>LocalAssets(imagePath: AppIconAssets.blue_era_app_logo),
                              ) /*Container(
                                    height: height,
                                    width: width,
                                    decoration: BoxDecoration(

                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  )*/
                              ,
                            ),
                          ),

                          // Page indicator
                          if (widget.mediaUrls.length > 1)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.mainTextColor
                                      .withValues(alpha: 0.80),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CustomText(
                                  "${_currentPage + 1}/${widget.mediaUrls.length}",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                  ;
                  return FutureBuilder<String>(
                    future: _getImageOrientation(url),
                    builder: (context, snapshot) {
                      String orientation = snapshot.data ?? "loading";
                    },
                  );
                }
              },
            ),
            // widget.mediaUrls.length > 1 ? _buildIndicatorDots() : SizedBox(),
            // if (widget.buildTranslationWidget != null) widget.buildTranslationWidget!(),
            // _buildPostMetaInfo(),
            // if (widget.taggedUser.isNotEmpty)
            //   FeedTagButton(
            //       onTap: () => showModalBottomSheet(
            //             context: context,
            //             isScrollControlled: true,
            //             backgroundColor: Colors.transparent,
            //             builder: (context) => FeedTagPeopleBottomSheet(
            //                 taggedUser: widget.taggedUser),
            //           )),

            // Audio control button (bottom right)
            if (widget.audioUrl != null) _buildAudioControls(),
          ],
        ),
      ),
    );
  }

  Map<String, String> imageOrientation = {}; // cache url → orientation

  Future<String> _getImageOrientation(String url) async {
    if (imageOrientation.containsKey(url)) {
      return imageOrientation[url]!;
    }

    final completer = Completer<ui.Image>();
    final stream = NetworkImage(url).resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener((info, _) {
        completer.complete(info.image);
      }),
    );

    final ui.Image image = await completer.future;

    String type;
    if (image.width > image.height) {
      type = "landscape";
    }
    /*else if (image.height > image.width) {
      type = "portrait";
    }*/
    else {
      type = "square";
    }

    imageOrientation[url] = type;
    return type;
  }

  Widget _buildAudioControls() {
    return Positioned(
      right: SizeConfig.size15,
      bottom: SizeConfig.size7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAudioEnabled && _duration.inSeconds > 0) _buildProgressBar(),
          GestureDetector(
            onTap: () {
              if (!_isLoadingAudio) {
                _toggleAudio();
              }
            },
            child: AnimatedBuilder(
              animation: _isPlaying
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              builder: (_, __) {
                return Transform.scale(
                  scale: _isPlaying ? _pulseAnimation.value : 1.0,
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size6),
                    decoration: BoxDecoration(
                      color: AppColors.mainTextColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingAudio
                        ? SizedBox(
                            width: SizeConfig.size16,
                            height: SizeConfig.size16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.white),
                            ),
                          )
                        : Icon(
                            _getAudioIcon(),
                            color: AppColors.white,
                            size: SizeConfig.size18,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAudioIcon() => _isPlaying ? Icons.volume_up : Icons.volume_off;

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: SizedBox(
        width: 100, // adjust width for your UI
        child: LinearProgressIndicator(
          value: _duration.inMilliseconds == 0
              ? 0
              : _position.inMilliseconds / _duration.inMilliseconds,
          backgroundColor: AppColors.white.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
          minHeight: 3,
        ),
      ),
    );
  }
}
