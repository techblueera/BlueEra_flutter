import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_tag_button.dart';
import 'package:BlueEra/features/common/feed/widget/video_player.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/feed_tag_people_bottom_sheet.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

// class _FeedMediaCarouselWidgetState extends State<FeedMediaCarouselWidget>
//     with TickerProviderStateMixin {
//   int _currentPage = 0;
//   late AudioPlayer _audioPlayer;
//   bool _isPlaying = false;
//   bool _isAudioEnabled = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;
//   bool _isVisible = true;
//
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _initializeAudio();
//     _setupAnimations();
//   }
//
//   void _setupAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     );
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//
//     _pulseController.repeat(reverse: true);
//   }
//
//   void _initializeAudio() {
//     if (widget.audioUrl == null) return;
//
//     _audioPlayer.onDurationChanged.listen((duration) {
//       setState(() => _duration = duration);
//     });
//
//     _audioPlayer.onPositionChanged.listen((position) {
//       setState(() => _position = position);
//     });
//
//     _audioPlayer.onPlayerStateChanged.listen((state) {
//       setState(() => _isPlaying = state == PlayerState.playing);
//     });
//
//     _audioPlayer.onPlayerComplete.listen((event) {
//       setState(() {
//         _isPlaying = false;
//         _position = Duration.zero;
//       });
//     });
//   }
//
//   MediaType getTypeFromUrl(String url) {
//     final ext = url.toLowerCase();
//     if (ext.endsWith('.mp4') || ext.endsWith('.mov')) return MediaType.video;
//     return MediaType.image;
//   }
//
//   Future<void> _toggleAudio() async {
//     if (widget.audioUrl == null) return;
//
//     try {
//       if (_isPlaying) {
//         await _audioPlayer.pause();
//       } else {
//         if (_position == Duration.zero) {
//           await _audioPlayer.play(UrlSource(widget.audioUrl!));
//         } else {
//           await _audioPlayer.resume();
//         }
//       }
//     } catch (e) {
//       print('Error playing audio: $e');
//     }
//   }
//
//   Future<void> _pauseAudio() async {
//     if (_isPlaying) {
//       await _audioPlayer.pause();
//     }
//   }
//
//   void _onVisibilityChanged(VisibilityInfo info) {
//     final isFullyVisible = info.visibleFraction >= 0.8; // 80% visibility threshold
//
//     if (_isVisible != isFullyVisible) {
//       setState(() => _isVisible = isFullyVisible);
//
//       if (!isFullyVisible && _isPlaying) {
//         _pauseAudio();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return VisibilityDetector(
//       key: Key('feed-carousel-${widget.hashCode}'),
//       onVisibilityChanged: _onVisibilityChanged,
//       child: SizedBox(
//         height: SizeConfig.size240,
//         child: Stack(
//           children: [
//             PageView.builder(
//               itemCount: widget.mediaUrls.length,
//               onPageChanged: (index) => setState(() => _currentPage = index),
//               itemBuilder: (context, index) {
//                 final url = widget.mediaUrls[index];
//                 final mediaType = getTypeFromUrl(url);
//                 if (mediaType == MediaType.video) {
//                   return VideoPlayerWidget(videoUrl: url);
//                 } else {
//                   return GestureDetector(
//                     onTap: () {
//                       navigatePushTo(
//                         context,
//                         ImageViewScreen(
//                           subTitle: widget.subTitle,
//                           appBarTitle: AppLocalizations.of(context)!.imageViewer,
//                           imageUrls: widget.mediaUrls,
//                           initialIndex: index,
//                         ),
//                       );
//                     },
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(10)),
//                       child: CachedNetworkImage(
//                         imageUrl: url,
//                         height: SizeConfig.size220,
//                         width: double.infinity,
//                         fit: BoxFit.cover,
//                         placeholder: (context, url) => const Center(
//                           child: CircularProgressIndicator(),
//                         ),
//                         errorWidget: (context, url, error) => Center(
//                           child: LocalAssets(
//                             imagePath: AppIconAssets.blueEraIcon,
//                             boxFix: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//               },
//             ),
//
//             // Indicator dots
//             if (widget.mediaUrls.length > 1) _buildIndicatorDots(),
//
//             // Tagged users button
//             if (widget.taggedUser.isNotEmpty)
//               FeedTagButton(
//                 onTap: () => showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   backgroundColor: Colors.transparent,
//                   builder: (context) => FeedTagPeopleBottomSheet(
//                       taggedUser: widget.taggedUser),
//                 ),
//               ),
//
//             // Audio control button (bottom right)
//             if (widget.audioUrl != null) _buildAudioControls(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildIndicatorDots() {
//     return Positioned(
//       right: 0,
//       bottom: SizeConfig.size15,
//       left: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: List.generate(widget.mediaUrls.length, (index) {
//           final isActive = _currentPage == index;
//           return AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             margin: const EdgeInsets.symmetric(horizontal: 4),
//             width: SizeConfig.size10,
//             height: SizeConfig.size10,
//             decoration: BoxDecoration(
//               color: isActive ? AppColors.white : AppColors.white45,
//               shape: BoxShape.circle,
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   Widget _buildAudioControls() {
//     return Positioned(
//       bottom: SizeConfig.size20,
//       right: SizeConfig.size15,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Audio progress indicator (optional)
//           if (_isAudioEnabled && _duration.inSeconds > 0)
//             Container(
//               width: 60,
//               height: 4,
//               margin: EdgeInsets.only(bottom: SizeConfig.size8),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(2),
//                 color: AppColors.white45,
//               ),
//               child: Stack(
//                 children: [
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     width: (_position.inMilliseconds / _duration.inMilliseconds) * 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(2),
//                       color: AppColors.primaryColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main audio control button
//           GestureDetector(
//             onTap: () {
//               // toggle mute / un-mute
//               _toggleAudio();
//             },
//             child: AnimatedBuilder(
//               animation: _isPlaying ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
//               builder: (_, __) {
//                 return Transform.scale(
//                   scale: _isPlaying ? _pulseAnimation.value : 1.0,
//                   child: Container(
//                     padding: EdgeInsets.all(SizeConfig.size6),
//                     decoration: BoxDecoration(
//                       color: AppColors.blackCC,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.black.withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       _getAudioIcon(),
//                       color: AppColors.white,
//                       size: SizeConfig.size20,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   IconData _getAudioIcon() =>
//       _isPlaying ? Icons.volume_up : Icons.volume_off;
// }


class _FeedMediaCarouselWidgetState extends State<FeedMediaCarouselWidget> {
  int _currentPage = 0;

  MediaType getTypeFromUrl(String url) {
    final ext = url.toLowerCase();
    if (ext.endsWith('.mp4') || ext.endsWith('.mov')) return MediaType.video;
    return MediaType.image;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SizeConfig.size240,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final url = widget.mediaUrls[index];
              final mediaType = getTypeFromUrl(url);
              if (mediaType == MediaType.video) {
                return VideoPlayerWidget(videoUrl: url);
              } else {
                return GestureDetector(
                    onTap: (){
                      navigatePushTo(
                        context,
                        ImageViewScreen(
                          subTitle: widget.subTitle,
                          appBarTitle: AppLocalizations.of(context)!.imageViewer,
                          imageUrls: widget.mediaUrls,
                          initialIndex: index,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        height: SizeConfig.size220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: LocalAssets(
                            imagePath: AppIconAssets.blueEraIcon,
                            boxFix: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                );
              }
            },
          ),
          widget.mediaUrls.length > 1 ? _buildIndicatorDots() : SizedBox(),
          // if (widget.buildTranslationWidget != null) widget.buildTranslationWidget!(),
          // _buildPostMetaInfo(),
          if (widget.taggedUser.isNotEmpty)
            FeedTagButton(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>  FeedTagPeopleBottomSheet(taggedUser: widget.taggedUser),
                )
            )
        ],
      ),
    );
  }

  Widget _buildIndicatorDots() {
    return Positioned(
      right: 0,
      bottom: SizeConfig.size15,
      left: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.mediaUrls.length, (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: SizeConfig.size10,
            height: SizeConfig.size10,
            decoration: BoxDecoration(
              color: isActive ? AppColors.white : AppColors.white45,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

}
