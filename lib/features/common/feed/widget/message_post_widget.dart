import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_media_carosal_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reference_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/post_meta_info.dart';
import 'package:flutter/material.dart';

class MessagePostWidget extends StatefulWidget {
  final Post? post;
  final Widget Function() authorSection;
  final Widget Function() buildActions;

  MessagePostWidget({
    super.key,
    required this.post,
    required this.authorSection,
    required this.buildActions,
  });

  @override
  State<MessagePostWidget> createState() => _MessagePostWidgetState();
}

class _MessagePostWidgetState extends State<MessagePostWidget> {
  late Post _post;
  late String subTitle;
  late String natureOfPost;
  String languageCode = 'en';

  @override
  void initState() {
    super.initState();
    updateData();
  }

  @override
  void didUpdateWidget(covariant MessagePostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      updateData();
    }
  }

  void updateData() {
    _post = widget.post!;
    subTitle = _post.subTitle ?? '';
    natureOfPost = _post.natureOfPost ?? '';

  }

  @override
  Widget build(BuildContext context) {
    return FeedCardWidget(
        childWidget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.authorSection(),
        Padding(
          padding: EdgeInsets.only(bottom: SizeConfig.size5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_post.title?.isNotEmpty ?? false)...[
                SizedBox(height: SizeConfig.size5,),
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,

                    ),
                  child: CustomText(
                    _post.title,
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.large,
                  ),
                ),
                SizedBox(height: SizeConfig.size5,),

              ],

              if (subTitle.isNotEmpty)...[
                SizedBox(height: SizeConfig.size5),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: SizeConfig.screenWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,
                    ),
                    child: ExpandableText(
                      text: subTitle.trim(),
                      trimLines: 4,
                      style: TextStyle(
                        color: AppColors.mainTextColor,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size5),
              ],

            ],
          ),
        ),
        if (_post.media?.isNotEmpty ?? false)...[
          SizedBox(height: SizeConfig.size5),
          FeedMediaCarouselWidget(
            subTitle: _post.subTitle ?? "",
            taggedUser: _post.taggedUsers ?? [],
            mediaUrls: _post.media ?? [],
            postedAgo: timeAgo(
                _post.createdAt != null ? _post.createdAt! : DateTime.now()),
            totalViews:
            _post.viewsCount != null ? _post.viewsCount.toString() : '0',
            audioUrl: _post.song?.externalUrl,
          ),
          SizedBox(height: SizeConfig.size5,),


        ],
        if (natureOfPost.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                top:
                    subTitle.isNotEmpty ? SizeConfig.size4 : SizeConfig.size10),
            child: CustomText(
              natureOfPost,
              fontSize: SizeConfig.small11,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        if (_post.referenceLink?.isNotEmpty ?? false)
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                top: SizeConfig.size5),
            child: ClickableLinkText(url: _post.referenceLink!),
          ),
        // SizedBox(width: SizeConfig.size10),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding:  EdgeInsets.only(right: SizeConfig.size15,top: SizeConfig.size10),
            child: PostMetaInfo(
              timeAgoText: timeAgo(
                  _post.createdAt != null ? _post.createdAt! : DateTime.now()),
              fontSize: SizeConfig.extraSmall,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              top: SizeConfig.size10),
          child: CommonHorizontalDivider(
            color: AppColors.secondaryTextColor,
            height: 0.5,
          ),
        ),
        widget.buildActions(),
      ],
    ));
  }
}
