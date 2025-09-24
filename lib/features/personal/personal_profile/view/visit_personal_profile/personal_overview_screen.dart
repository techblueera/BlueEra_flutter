import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalOverviewScreen extends StatelessWidget {
  final String userId;
  final String videoType;
  final String screenFromName;

  PersonalOverviewScreen({
    required this.userId,
    required this.videoType,
    required this.screenFromName,
  });

  final OverviewController controller = Get.put(OverviewController());
  final visitingController = Get.find<VisitProfileController>();

  @override
  Widget build(BuildContext context) {
    controller.loadOverviewData(userId, videoType);

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.isNotEmpty) {
        return Center(
            child: CustomText("Error: ${controller.errorMessage.value}"));
      }

      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: NeverScrollableScrollPhysics(),
        children: [

          // controller.userData.value?.user
          // RatingSummaryWidget(
          //   rating: visitingController.userData.value?.ratingSummary?.avgRating
          //           ?.toDouble() ??
          //       0.0,
          //   ratingPersonCount: visitingController.userData.value?.ratingSummary?.totalRatings??0,
          //   userId: userId,
          //   screenFromName: screenFromName, ratingForAccountName: AppConstants.individual, businessId: '',
          // ),
          SizedBox(
            height: SizeConfig.size5,
          ),
          // ✅ Show only latest testimonial
          if (controller.testimonialsList.isNotEmpty) ...[
            SizedBox(
              height: SizeConfig.size5,
            ),
            CommonCardWidget(
              // padding: SizeConfig.size10,
              borderRadius: 0,
              cardMargin: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget("Testimonial"),
                  Container(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(SizeConfig.size12),
                        border: Border.all(color: AppColors.whiteDB, width: 1)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          controller.testimonialsList.first.description,
                          textAlign: TextAlign.start,
                          fontSize: SizeConfig.size14,
                          color: AppColors.grayText,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.primaryColor,
                              backgroundImage: controller.testimonialsList.first
                                          .fromUser?.profileImage !=
                                      null
                                  ? NetworkImage(controller.testimonialsList
                                          .first.fromUser?.profileImage ??
                                      "")
                                  : null,
                              child: controller.testimonialsList.first.fromUser
                                          ?.profileImage ==
                                      null
                                  ? CustomText(
                                      getInitials(controller.testimonialsList
                                              .first.fromUser?.name ??
                                          "U"),
                                      fontSize: SizeConfig.size18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  '${controller.testimonialsList.first.fromUser?.name ?? "User"}',
                                  // fontSize: SizeConfig.size16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryTextColor,
                                ),
                                Row(
                                  children: [
                                    // ...List.generate(
                                    //   5,
                                    //   (index) => Icon(Icons.star,
                                    //       color: AppColors.yellow,
                                    //       size: SizeConfig.size16),
                                    // ),
                                    // SizedBox(width: SizeConfig.size6),
                                    CustomText(
                                      getTimeAgo(controller.testimonialsList
                                              .first.updatedAt ??
                                          ""),
                                      color: AppColors.secondaryTextColor,
                                      fontSize: SizeConfig.size12,
                                    )
                                  ],
                                ),

                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ✅ Show only latest post
          if (controller.postsList.isNotEmpty) ...[
            SizedBox(
              height: SizeConfig.size10,
            ),
            CommonCardWidget(
              borderRadius: 0,
              cardMargin: 0,
              // padding: SizeConfig.size10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget("Post"),
                  FeedCard(
                    post: controller.postsList.first,
                    index: 0,
                    postFilteredType: PostType.myPosts,
                    horizontalPadding: 0,
                  ),
                ],
              ),
            ),
          ],

          // ✅ Show only latest short
          if (controller.shortsList.isNotEmpty) ...[
            CommonCardWidget(
              // padding: SizeConfig.size10,
              borderRadius: 0,
              cardMargin: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget("Short"),
                  Container(
                    height: 250,
                    padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.shortsList.length>2?2:controller.shortsList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding:  EdgeInsets.only(right: SizeConfig.size10),
                          child: ClipRRect(
                            borderRadius: (BorderRadius.circular(12)),
                            child: SingleShortStructure(
                              shorts: Shorts.latest,
                              allLoadedShorts: controller.shortsList,
                              initialIndex:index,
                              shortItem: controller.shortsList[index],
                              withBackground: true,
                              imageWidth: 170,
                              imageHeight: 250,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              ),
            ),
          ],
          // ✅ Show only latest video
          if (controller.videosList.isNotEmpty) ...[
            CommonCardWidget(
              padding: SizeConfig.size10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget("Video"),
                  AutoPlayVideoCard(
                    videoItem: controller.videosList.first,
                    globalMuteNotifier: ValueNotifier(false),
                    videoType: VideoType.videoFeed,
                    onTapOption: () {
                      openBlockSelectionDialog(
                          context: context,
                          reportType: 'VIDEO_POST',
                          userId:
                              controller.videosList.first.video?.userId ?? '',
                          contentId:
                              controller.videosList.first.video?.id ?? '',
                          userBlockVoidCallback: () async {
                            await Get.find<VideoController>().userBlocked(
                              videoType: VideoType.videoFeed,
                              otherUserId:
                                  controller.videosList.first.video?.userId ??
                                      '',
                            );
                          },
                          reportCallback: (params) {
                            Get.find<VideoController>().videoPostReport(
                                videoId:
                                    controller.videosList.first.video?.id ?? '',
                                videoType: VideoType.videoFeed,
                                params: params);
                          });
                    },
                  ),
                ],
              ),
            ),
          ],
          // VideoWidget(video: controller.videosList.first),
        ],
      );
    });
  }

  TitleWidget(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: CustomText(
        title,
        fontWeight: FontWeight.w600,
        fontSize: SizeConfig.medium15,
          color: AppColors.secondaryTextColor
      ),
    );
  }
}
