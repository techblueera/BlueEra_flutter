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

class FeedMediaCarouselWidget extends StatefulWidget {
  final String subTitle;
  final List<User> taggedUser;
  final List<String> mediaUrls;
  final String postedAgo;
  final String totalViews;
  final Widget Function()? buildTranslationWidget;
  final Widget Function(int currentPage)? buildIndicatorDots;

  const FeedMediaCarouselWidget({
    super.key,
    required this.taggedUser,
    required this.mediaUrls,
    required this.postedAgo,
    required this.totalViews,
     this.buildTranslationWidget,
    this.buildIndicatorDots, required this.subTitle,
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
