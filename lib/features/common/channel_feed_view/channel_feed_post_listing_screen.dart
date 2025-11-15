import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelFeedPostListingScreen extends StatefulWidget {
  ChannelFeedPostListingScreen({super.key, required this.channelData});

  final ChannelFeedData? channelData;

  @override
  State<ChannelFeedPostListingScreen> createState() =>
      _ChannelFeedPostListingScreenState();
}

class _ChannelFeedPostListingScreenState
    extends State<ChannelFeedPostListingScreen> {
  final controller = Get.find<ChannelFeedController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.isChannelJoin.value = widget.channelData?.isFollowing??false;

    super.initState();
  }

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
                                widget.channelData?.ownership?.claimedBy,
                          },
                        );
                      },
                      child: SizedBox(
                        width: Get.width,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (widget.channelData?.logoUrl?.isNotEmpty ??
                                false)
                              InkWell(
                                onTap: () {
                                  navigatePushTo(
                                    context,
                                    ImageViewScreen(
                                      appBarTitle: AppLocalizations.of(context)!
                                          .imageViewer,
                                      // imageUrls: [post?.author.profileImage ?? ''],
                                      imageUrls: [
                                        widget.channelData?.logoUrl ?? ""
                                      ],
                                      initialIndex: 0,
                                    ),
                                  );
                                },
                                child: CachedAvatarWidget(
                                    imageUrl: widget.channelData?.logoUrl,
                                    size: 40,
                                    borderColor: Colors.white,
                                    borderRadius: 25),
                              ),
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
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size2),
                                  CustomText(
                                    "${formatNumberLikePost(widget.channelData?.followers ?? 0)} ${AppStrings.members.tr}",
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    // color: AppColors.white,
                                  ),
                                  SizedBox(height: SizeConfig.size5),
                                ],
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),

                            // Add optional follower/follow section if needed
                            Obx(() {
                              return GestureDetector(
                                onTap: () async {
                                  if (isGuestUser()) {
                                    createProfileScreen();
                                  } else {
                                    if (controller.isChannelJoin.value) {
                                      await controller.unFollowUserController(
                                          candidateResumeId:
                                              widget.channelData?.id);
                                    } else {
                                      await controller.followUserController(
                                          candidateResumeId:
                                              widget.channelData?.id);
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: controller.isChannelJoin.value
                                        ? AppColors.colorTextDarkGrey
                                        : AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      CustomText(
                                        controller.isChannelJoin.value
                                            ? AppStrings.unjoin
                                            : AppStrings.join,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: SizeConfig.size10,
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.person_add_alt,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }),
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
            padding: const EdgeInsets.only(
                top: 8.0, left: 20, right: 20, bottom: 20),
            child: FeedScreen(
                key: ValueKey(
                    'feedScreen_user_posts_${widget.channelData?.ownership?.claimedBy}'),
                postFilterType: PostType.otherChannelPosts,
                isInParentScroll: false,
                bottomPaddingChannel: 20,
                id: widget.channelData?.ownership?.claimedBy),
          ),
        ],
      ),
    );
  }
}
