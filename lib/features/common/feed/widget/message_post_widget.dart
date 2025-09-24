import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_media_carosal_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reference_widget.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/feed_tag_people_bottom_sheet.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_like_user_list_dialog.dart';
import 'package:BlueEra/widgets/post_meta_info.dart';
import 'package:flutter/material.dart';

class MessagePostWidgetNew extends StatefulWidget {
  final FeedItem? post;
  final Widget Function() authorSection;
  final Widget Function() buildActions;
  final VoidCallback  commentView;
  final double? horizontalPadding;

  MessagePostWidgetNew({
    super.key,
    required this.post,
    required this.authorSection,
    required this.buildActions,
    required this.commentView,
    this.horizontalPadding,
  });

  @override
  State<MessagePostWidgetNew> createState() => _MessagePostWidgetNewState();
}

class _MessagePostWidgetNewState extends State<MessagePostWidgetNew> {
  late FeedItem _post;
  late String subTitle;
  late String natureOfPost;
  String languageCode = 'en';

  @override
  void initState() {
    super.initState();
    updateData();
  }

  @override
  void didUpdateWidget(covariant MessagePostWidgetNew oldWidget) {
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
        horizontalPadding:widget.horizontalPadding ,
        childWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.authorSection(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: SizeConfig.size5,
                  // left: SizeConfig.size50
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
              
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_post.title?.isNotEmpty ?? false) ...[
                          // SizedBox(
                          //   height: SizeConfig.size5,
                          // ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.size15,
                              right: SizeConfig.size15,
                            ),
                            child: CustomText(
                              _post.title,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.bold,
                              // fontSize: SizeConfig.large,
                            ),
                          ),
                          // SizedBox(
                          //   height: SizeConfig.size5,
                          // ),
                        ],
                        if (subTitle.isNotEmpty) ...[
                          // SizedBox(
                          //   height: SizeConfig.size5,
                          // ),
                          Container(
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
                                  fontFamily: AppConstants.OpenSans,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size5,
                          ),
                        ],
                      ],
                    ),
              
              
                   /* if (_post.referenceLink?.isNotEmpty ?? false)
                      Padding(
                        padding: EdgeInsets.only(
                            left: SizeConfig.size15,
                            right: SizeConfig.size15,
                            top: SizeConfig.size5),
                        child: ClickableLinkText(url: _post.referenceLink!),
                      ),
                    if (_post.taggedUsers?.isNotEmpty ?? false) ...[
                      Padding(
                        padding: EdgeInsets.only(
                            left: SizeConfig.size15,
                            right: SizeConfig.size15,
                            top: SizeConfig.size10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Show first 3 users
                            ...?_post.taggedUsers?.take(2).map(
                                  (user) => UserChipFeed(
                                user: user,
                              ),
                            ),
              
                            // If more than 3, show +remaining count
                        if ((_post.taggedUsers?.length ?? 0) > 2)
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        FeedTagPeopleBottomSheet(
                                            taggedUser: _post.taggedUsers ?? []),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10,
                                      vertical: SizeConfig.size3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: CustomText(
                                    '+${(_post.taggedUsers?.length ?? 0) - 2}',
                                    color: AppColors.mainTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: SizeConfig.size12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],*/
              
                    if (_post.content?.images?.isNotEmpty ?? false) ...[
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: SizeConfig.size15, right: SizeConfig.size15),
                        child: FeedMediaCarouselWidget(
                          subTitle: _post.subTitle ?? "",
                          taggedUser: [],
                          // taggedUser: _post.taggedUsers ?? [],
                          mediaUrls:_post.content?.images ?? [],
                          postedAgo: timeAgo(_post.createdAt != null
                              ? _post.createdAt!
                              : DateTime.now()),
                          totalViews: _post.stats?.views != null
                              ? _post.stats?.views?.toString()??"0"
                              : '0',
                          audioUrl: _post.song?.externalUrl,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                    ],
                    SizedBox(
                      height: SizeConfig.size5,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size15,
                          vertical: SizeConfig.size5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ViewFeedActionWidget(
                              iconPath: AppIconAssets.clock_new,
                              data: timeAgo(_post.createdAt != null
                                  ? _post.createdAt ?? DateTime.now()
                                  : DateTime.now())),
                          ViewFeedActionWidget(
                            iconPath: AppIconAssets.eye_new,
                            data: formatNumberLikePost(_post.stats?.views ?? 0),
                          ),
                          InkWell(onTap: (){
                            if (isGuestUser()) {
                              createProfileScreen();
                            } else {
                              widget.commentView();
                            }
                          },child:   ViewFeedActionWidget(
                              iconPath: AppIconAssets.comment_new,
                              data:
                              formatNumberLikePost(_post.stats?.comments ?? 0)),),
              
                          InkWell(
                            onTap: () {
                              if ((_post.stats?.likes ?? 0) < 1) {
                                return;
                              }
              
                              showDialog(
                                context: context,
                                builder: (context) => PostLikeUserListDialog(
                                  postId: widget.post?.id ?? '',
                                ),
                              );
                            },
                            child: ViewFeedActionWidget(
                                iconPath: AppIconAssets.like_new,
                                data:
                                formatNumberLikePost(_post.stats?.likes ?? 0)),
                          ),
                          ViewFeedActionWidget(
                              iconPath: AppIconAssets.repost_new,
                              data: formatNumberLikePost(_post.stats?.shares ?? 0)),
                        ],
                      ),
                    ),
              
                    SizedBox(
                      height: SizeConfig.size5,
                    ),
              
                    widget.buildActions(),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

}
class MessagePostWidget extends StatefulWidget {
  final Post? post;
  final Widget Function() authorSection;
  final Widget Function() buildActions;
  final VoidCallback  commentView;
  final double? horizontalPadding;

  MessagePostWidget({
    super.key,
    required this.post,
    required this.authorSection,
    required this.buildActions,
    required this.commentView,
    this.horizontalPadding,
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
        horizontalPadding:widget.horizontalPadding ,
        childWidget: Column(
          children: [
            widget.authorSection(),
            Padding(
              padding: EdgeInsets.only(
                  bottom: SizeConfig.size5,
                  // left: SizeConfig.size50
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_post.title?.isNotEmpty ?? false) ...[
                        // SizedBox(
                        //   height: SizeConfig.size5,
                        // ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: SizeConfig.size15,
                            right: SizeConfig.size15,
                          ),
                          child: CustomText(
                            _post.title,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.bold,
                            // fontSize: SizeConfig.large,
                          ),
                        ),
                        // SizedBox(
                        //   height: SizeConfig.size5,
                        // ),
                      ],
                      if (subTitle.isNotEmpty) ...[
                        // SizedBox(
                        //   height: SizeConfig.size5,
                        // ),
                        Container(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.size15,
                              right: SizeConfig.size15,
                            ),
                            child: ExpandableText(
                              text: subTitle.trim(),
                              trimLines: 2,expandMode: ExpandMode.dialog,
                              style: TextStyle(
                                color: AppColors.mainTextColor,
                                fontFamily: AppConstants.OpenSans,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                      ],
                    ],
                  ),


                  if (_post.referenceLink?.isNotEmpty ?? false)
                    Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          top: SizeConfig.size5),
                      child: ClickableLinkText(url: _post.referenceLink!),
                    ),
                  if (_post.taggedUsers?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                          top: SizeConfig.size10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Show first 3 users
                          ...?_post.taggedUsers?.take(2).map(
                                (user) => UserChipFeed(
                                  user: user,
                                ),
                              ),

                          // If more than 3, show +remaining count
                          if ((_post.taggedUsers?.length ?? 0) > 2)
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      FeedTagPeopleBottomSheet(
                                          taggedUser: _post.taggedUsers ?? []),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.size10,
                                    vertical: SizeConfig.size3),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CustomText(
                                  '+${(_post.taggedUsers?.length ?? 0) - 2}',
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.size12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  ],

                  if (_post.media?.isNotEmpty ?? false) ...[
                    SizedBox(
                      height: SizeConfig.size5,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.size15, right: SizeConfig.size15),
                      child: FeedMediaCarouselWidget(
                        subTitle: _post.subTitle ?? "",
                        taggedUser: _post.taggedUsers ?? [],
                        mediaUrls: _post.media ?? [],
                        postedAgo: timeAgo(_post.createdAt != null
                            ? _post.createdAt!
                            : DateTime.now()),
                        totalViews: _post.viewsCount != null
                            ? _post.viewsCount.toString()
                            : '0',
                        audioUrl: _post.song?.externalUrl,
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size5,
                    ),
                  ],
                  SizedBox(
                    height: SizeConfig.size5,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size15,
                        vertical: SizeConfig.size5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ViewFeedActionWidget(
                            iconPath: AppIconAssets.clock_new,
                            data: timeAgo(_post.createdAt != null
                                ? _post.createdAt ?? DateTime.now()
                                : DateTime.now())),
                        ViewFeedActionWidget(
                          iconPath: AppIconAssets.eye_new,
                          data: formatNumberLikePost(_post.viewsCount ?? 0),
                        ),
                        InkWell(onTap: (){
                          if (isGuestUser()) {
                            createProfileScreen();
                          } else {
                            widget.commentView();
                          }
                        },child:   ViewFeedActionWidget(
                            iconPath: AppIconAssets.comment_new,
                            data:
                            formatNumberLikePost(_post.commentsCount ?? 0)),),

                        InkWell(
                          onTap: () {
                            if ((_post.likesCount ?? 0) < 1) {
                              return;
                            }

                            showDialog(
                              context: context,
                              builder: (context) => PostLikeUserListDialog(
                                postId: widget.post?.id ?? '',
                              ),
                            );
                          },
                          child: ViewFeedActionWidget(
                              iconPath: AppIconAssets.like_new,
                              data:
                                  formatNumberLikePost(_post.likesCount ?? 0)),
                        ),
                        ViewFeedActionWidget(
                            iconPath: AppIconAssets.repost_new,
                            data: formatNumberLikePost(_post.repostCount ?? 0)),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: SizeConfig.size5,
                  ),

                  widget.buildActions(),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                ],
              ),
            ),
          ],
        ));
  }

}
ViewFeedActionWidget({required String iconPath, required String data}) {
  return Padding(
    padding: EdgeInsets.only(right: SizeConfig.size10),
    child: Row(
      children: [
        LocalAssets(
          imagePath: iconPath,
          width: SizeConfig.size18,
          height: SizeConfig.size18,
        ),
        SizedBox(
          width: SizeConfig.size5,
        ),
        CustomText(
          data,
          color: AppColors.secondaryTextColor,
          fontSize: SizeConfig.size10,
        ),
      ],
    ),
  );
}
