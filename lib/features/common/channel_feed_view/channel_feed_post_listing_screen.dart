import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../reel/models/create_channel_model.dart';
// https://be.blueera.ai/api/post-service/post/channel-posts-filtered?page=1&limit=40&filter=latest&refresh=true&authorId=689df0cb7e62ed576245195f
// https://be.blueera.ai/api/post-service/post/channel-posts-filtered?page=1&limit=40&filter=latest&refresh=true&authorId=68ccf0ad28492e584c3656ca


class ChannelFeedPostListingScreen extends StatefulWidget {
  ChannelFeedPostListingScreen({super.key, required this.channelData});

  final ChannelFeedData? channelData;

  @override
  State<ChannelFeedPostListingScreen> createState() =>
      _ChannelFeedPostListingScreenState();
}

class _ChannelFeedPostListingScreenState
    extends State<ChannelFeedPostListingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size(Get.width, 50),
        child: SafeArea(
          child: Material(
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // LocalAssets(imagePath: AppIconAssets.back_arrow),
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 20,
                      )),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(
                          RouteHelper.getChannelScreenRoute(),
                          arguments: {
                            ApiKeys.argAccountType: accountTypeGlobal,
                            ApiKeys.channelId: widget.channelData?.id,
                            ApiKeys.authorId:
                                (accountTypeGlobal == AppConstants.individual)
                                    ? userId
                                    : businessId
                          },
                        );
                      },
                      child: SizedBox(
                        width: Get.width,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /*   if (channelData.ownership.isNotEmpty)
                            InkWell(
                              onTap: () {
                                navigatePushTo(
                                  context,
                                  ImageViewScreen(
                                    appBarTitle: AppLocalizations.of(context)!
                                        .imageViewer,
                                    // imageUrls: [post?.author.profileImage ?? ''],
                                    imageUrls: [],
                                    initialIndex: 0,
                                  ),
                                );
                              },
                              child: CachedAvatarWidget(
                                  imageUrl: widget.video.avatar,
                                  size: 40,
                                  borderColor: Colors.white,
                                  borderRadius: 25),
                            ),*/
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: Get.width,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: CustomText(
                                            widget.channelData?.name,
                                            fontWeight: FontWeight.w600,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        /*  if (widget.video.authorUsername != null &&
                                          (widget.video.authorUsername
                                              .isNotEmpty ??
                                              false))
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 3),
                                            child: CustomText(
                                              " @${widget.video.authorUsername}",
                                              fontWeight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),*/
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size2),
                                  /*  CustomText(
                                  widget.video.account_type.toUpperCase() ==
                                      AppConstants.business
                                      ? widget.video.business_category
                                      : widget.video.designation,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.white,
                                )*/
                                  // Add optional follower/follow section if needed
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppImageAssets.chating_bg,
            fit: BoxFit.cover,
            width: SizeConfig.screenWidth,
            height: SizeConfig.screenHeight,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FeedScreen(
                key: ValueKey(
                    'feedScreen_user_posts_${widget.channelData?.ownership?.claimedBy}'),
                postFilterType: PostType.otherChannelPosts,
                isInParentScroll: false,
                id: widget.channelData?.ownership?.claimedBy),
          ),
        ],
      ),
    );
  }
}
