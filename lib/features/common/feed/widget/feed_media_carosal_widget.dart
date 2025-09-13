import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
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

class _FeedMediaCarouselWidgetState extends State<FeedMediaCarouselWidget> {
  int _currentPage = 0;

  MediaType getTypeFromUrl(String url) {
    final ext = url.toLowerCase();
    if (ext.endsWith('.mp4') || ext.endsWith('.mov')) return MediaType.video;
    return MediaType.image;
  }

  @override
  Widget build(BuildContext context) {
    // return MediaViewer(
    //   mediaUrlList: widget.mediaUrls,
    // );
    return SizedBox(
      // height: SizeConfig.size240,
      height: Get.width * 0.5,

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
                return FutureBuilder<String>(
                  future: _getImageOrientation(url),
                  builder: (context, snapshot) {
                    String orientation = snapshot.data ?? "loading";

                    double height = Get.width * 0.5;
                    double width = Get.width;
                    /* if (orientation == "portrait") {
                height = Get.height * 0.5; // taller
                width = Get.width * 0.7;
              } else*/
                    if (orientation == "landscape") {
                      height = Get.width * 0.5; // shorter
                      width = Get.width;
                    } else if (orientation == "square") {
                      height = Get.width * 0.5;
                      width = Get.width * 0.5;
                    }

                    return Container(
                      // height: Get.width * 0.5,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        // borderRadius: BorderRadius.circular(12),
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
                              child: Container(
                                height: height,
                                width: width,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
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
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CustomText(
                                  "${_currentPage + 1}/${widget.mediaUrls.length}",
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
          // widget.mediaUrls.length > 1 ? _buildIndicatorDots() : SizedBox(),
          // if (widget.buildTranslationWidget != null) widget.buildTranslationWidget!(),
          // _buildPostMetaInfo(),
          if (widget.taggedUser.isNotEmpty)
            FeedTagButton(
                onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => FeedTagPeopleBottomSheet(
                          taggedUser: widget.taggedUser),
                    ))
        ],
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
