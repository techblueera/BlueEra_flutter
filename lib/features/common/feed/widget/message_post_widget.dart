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

  /*  return Container(
      decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.whiteDB, width: 2),
          borderRadius:
          BorderRadius.circular(SizeConfig.size12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedMediaCarouselWidget(
            subTitle: _post.subTitle??"",
            taggedUser: _post.taggedUsers ?? [],
            mediaUrls: _post.media ?? [],
            *//*  buildTranslationWidget: () =>
              (subTitle.isNotEmpty) || (natureOfPost.isNotEmpty)
                  ? TranslationButton(
                onTap: () {
                  translateToOtherLan();
                },
              )
                  : SizedBox(),*//*
            postedAgo: timeAgo(
                _post.createdAt != null ? _post.createdAt! : DateTime.now()),
            totalViews:
            _post.viewsCount != null ? _post.viewsCount.toString() : '0',
          ),
          // ClipRRect(
          //     borderRadius: BorderRadius.only(
          //         topLeft:
          //         Radius.circular(SizeConfig.size12),
          //         topRight:
          //         Radius.circular(SizeConfig.size12)),
          //     child:
          //     Image.network(data.media?.first ?? "")
          //
          // ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CustomText(
                  _post.title,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  subTitle,
                  fontSize: SizeConfig.size12,
                  color: AppColors.coloGreyText,
                ),
                // SizedBox(height: SizeConfig.size10),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.borderGray,
                            width: 2),
                        borderRadius:
                        BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        child: Image.network(
                            _post.user?.profileImage ??
                                ""),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          text: TextSpan(
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13),
                            children: [
                              TextSpan(
                                  text: "Sathi: ",
                                  style: TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold)),
                              TextSpan(
                                  text:
                                  "Bharat Mata Ki Jai...❤️🙏 Lorem ipsum Dolor Amet"),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.edit,
                          size: 18,
                          color: Colors.grey[600]),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.borderGray,
                          width: 2),
                      borderRadius:
                      BorderRadius.circular(12)),
                  child: PopupMenuButton(
                      onSelected: (value) {},
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 1,
                            child: CustomText(
                                "Re-post")),
                        PopupMenuItem(
                            value: 2,
                            child:
                            CustomText("Share")),
                        PopupMenuItem(
                            value: 3,
                            child: CustomText("Save"))
                      ]),
                ),
              ],
            ),
          ),
          SizedBox(
            height: SizeConfig.size16,
          ),
        ],
      ),
    );*/


    return FeedCardWidget(
        childWidget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.authorSection(),
        FeedMediaCarouselWidget(
          subTitle: _post.subTitle??"",
          taggedUser: _post.taggedUsers ?? [],
          mediaUrls: _post.media ?? [],
          /*  buildTranslationWidget: () =>
              (subTitle.isNotEmpty) || (natureOfPost.isNotEmpty)
                  ? TranslationButton(
                onTap: () {
                  translateToOtherLan();
                },
              )
                  : SizedBox(),*/
          postedAgo: timeAgo(
              _post.createdAt != null ? _post.createdAt! : DateTime.now()),
          totalViews:
              _post.viewsCount != null ? _post.viewsCount.toString() : '0',
        ),
        Padding(
          padding: EdgeInsets.only(bottom: SizeConfig.size5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subTitle.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,
                      top: SizeConfig.size10,
                      bottom: SizeConfig.size1),
                  child: ExpandableText(
                    text: subTitle,
                    trimLines: 2,
                    style: TextStyle(
                      color: AppColors.mainTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.only(
                    left: SizeConfig.size15,
                    right: SizeConfig.size15,
                    top: subTitle.isNotEmpty
                        ? SizeConfig.size4
                        : SizeConfig.size10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (natureOfPost.isNotEmpty)
                      Expanded(
                        child: CustomText(
                          natureOfPost,
                          fontSize: SizeConfig.small11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    SizedBox(width: SizeConfig.size10),
                    PostMetaInfo(
                      timeAgoText: timeAgo(_post.createdAt != null
                          ? _post.createdAt!
                          : DateTime.now()),
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ],
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

              // widget.authorSection(),

              // Padding(
              //   padding: EdgeInsets.only(left: SizeConfig.size15, right: SizeConfig.size15,),
              //   child: PostMetaInfo(
              //     timeAgoText: timeAgo(_post.createdAt != null ? _post.createdAt! : DateTime.now()),
              //     totalViews: _post.viewsCount != null ? _post.viewsCount.toString() : '0',
              //     fontSize: SizeConfig.extraSmall,
              //   ),
              // ),
              // SizedBox(height: SizeConfig.size8),

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
          ),
        ),
      ],
    ));
  }
/*
  Future<void> translateToOtherLan() async {
    // final Locale locale = context.read<LocaleBloc>().state.locale; // Fix A assumed here

    if (languageCode == 'en') {
      // It's English
      languageCode = 'hi';
    } else if (languageCode == 'hi') {
      // It's Hindi
      languageCode = 'en';
    }

    final results = await Future.wait([
      CustomTranslator().translateToOtherLanguage(natureOfPost, languageCode),
      CustomTranslator().translateToOtherLanguage(subTitle, languageCode),
    ]);

    setState(() {
      natureOfPost = results[0];
      subTitle = results[1];
    });
  }*/
}
