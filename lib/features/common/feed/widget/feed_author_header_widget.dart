import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_profile.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_option_popup_menu.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/block_user_dialog.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';

class PostAuthorHeader extends StatelessWidget {
  final Post? post;
  final String authorId;
  final PostType postType;
  final VoidCallback? onTapAvatar;
  final VoidCallback? onTapOptions;
  final String? postedAgo;

  const PostAuthorHeader({
    super.key,
    required this.post,
    required this.authorId,
    required this.postType,
    this.onTapAvatar,
    this.onTapOptions,
    this.postedAgo,
  });

  @override
  Widget build(BuildContext context) {

    // print('user Id--> ${post?.user?}');
    String name =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? post?.user?.name ?? 'User'
            : post?.user?.businessName ?? 'User';

    String designation =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? post?.user?.designation ?? "OTHERS"
            : (post?.user?.categoryOfBusiness?.isNotEmpty ?? false)
                ? post?.user?.categoryOfBusiness ?? 'OTHERS'
                : (post?.user?.subCategoryOfBusiness?.isNotEmpty ?? false)
                    ? post?.user?.subCategoryOfBusiness ?? 'OTHERS'
                    : (post?.user?.natureOfBusiness ?? 'OTHERS');

    String id =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? authorId
            : post?.user?.business_id ?? '';

    return Padding(
      padding: EdgeInsets.only(

          // right: SizeConfig.size10,
          left: SizeConfig.size15,
          top: SizeConfig.size10,
          bottom: SizeConfig.size5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (((authorId == userId) ||
                        (post?.user?.business_id == businessId)) &&
                    (postType == PostType.myPosts ||
                        postType == PostType.saved)) {
                  return;
                }
                if (post?.user?.accountType?.toUpperCase() ==
                    AppConstants.individual) {
                  if (userId == authorId) {
                    navigatePushTo(context, PersonalProfileSetupScreen());
                  } else {
                    Get.to(() => NewVisitProfileScreen(
                          authorId: authorId,
                          screenFromName: AppConstants.feedScreen,
                          channelId: '',
                        ));
                    // Get.to(() => VisitProfileScreen(authorId: authorId));
                    // Get.to(() => PersonalChatProfile(userId: authorId));
                  }
                }
                if (post?.user?.accountType?.toUpperCase() ==
                    AppConstants.business) {
                  if (businessId == post?.user?.business_id) {
                    navigatePushTo(context, BusinessOwnProfileScreen());
                  } else {
                    Get.to(() => VisitBusinessProfileNew(
                        businessId: post?.user?.business_id ?? ""));
                  }
                }
              },
              child: ChannelProfileHeader(
                  imageUrl: post?.user?.profileImage ?? '',
                  title: '$name',
                  userName: '${post?.user?.username}',
                  subtitle: designation != "null" ? designation : 'OTHERS',
                  avatarSize: SizeConfig.size42,
                  borderColor: AppColors.primaryColor,
                  postedAgo: postedAgo),
            ),
          ),
          if (post?.user?.accountType == AppConstants.individual)
            if (id != userId)
              Container(
                height: 20,
                width: 20,
                margin: EdgeInsets.only(right: SizeConfig.size15),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  // offset: const Offset(-6, 36),
                  color: AppColors.white,

                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) async {
                    onTapFunction(valueData: value);
                  },
                  icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                  itemBuilder: (context) => popupMenuVisitProfileActionItems(
                      isSavePost: (post?.isPostSavedLocal ?? false)),
                ),
              )
            /*IconButton(
                onPressed:(){
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else {
                    onTapOptions ?? blockReportUserPopUp();
                  }
                },
                icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
              )*/
            else
              FeedPopUpMenu(
                post: post ?? Post(id: ''),
                postFilteredType: postType,
              )
          else if (post?.user?.accountType == AppConstants.business)
            if (id != businessId)
              Container(
                height: 20,
                width: 20,
                margin: EdgeInsets.only(right: SizeConfig.size12),

                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  // offset: const Offset(-6, 36),
                  color: AppColors.white,

                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) async {
                    onTapFunction(valueData: value);
                  },
                  icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                  itemBuilder: (context) => popupMenuVisitProfileActionItems(),
                ),
              )
            else
              FeedPopUpMenu(
                  post: post ?? Post(id: ''), postFilteredType: postType)
        ],
      ),
    );
  }

  void onTapFunction({required String valueData}) {
    String value = valueData.toUpperCase();
    if (value == "SAVE") {
      Get.find<FeedController>().savePostToLocalDB(
        postId: post?.id ?? '0',
        type: postType,
      );
    }
    if (value == "Block User".toUpperCase()) {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        blockUserPopUp();
      }
    }
    if (value == "Report Post".toUpperCase()) {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        postReportPopUp();
      }
    }
  }

  void blockReportUserPopUp() {
    openBlockSelectionDialog(
        context: Get.context!,
        userId: authorId,
        contentId: post?.id ?? '',
        reportType: 'POST',
        userBlockVoidCallback: () {
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          Get.find<FeedController>()
              .userBlocked(otherUserId: post?.authorId ?? '', type: postType);
        },
        reportCallback: (params) async {
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          Get.find<FeedController>().postReport(
              postId: post?.id ?? '', type: postType, params: params);
        });
  }

  void blockUserPopUp() {
    showDialog(
      context: Get.context!,
      builder: (context) => BlockUserDialog(
        onConfirm: () {
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          Get.find<FeedController>()
              .userBlocked(otherUserId: post?.authorId ?? '', type: postType);
        },
        userName: post?.user?.name,
      ),
    );
    // openBlockDialog(
    //   context: Get.context!,
    //   userId: authorId,
    //   contentId: post?.id ?? '',
    //   reportType: 'POST',
    //   userBlockVoidCallback: () {
    //     if (isGuestUser()) {
    //       createProfileScreen();
    //
    //       return;
    //     }
    //     Get.find<FeedController>()
    //         .userBlocked(otherUserId: post?.authorId ?? '', type: postType);
    //   },
    // );
  }

  void postReportPopUp() {
    Get.back();
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Material(
              color: AppColors.white,
              child: ReportDialog(
                reportType: "POST",
                reportReasons: {
                  'Sexual content': false,
                  'Voilent or repulsive content': false,
                  'Hateful or abusive content': false,
                  'Harrasement or bullying': false,
                  'Harmful or dangerous act': false,
                  'Suicide, self harm or eating disorder ': false,
                  'Misinformation': false,
                  'Child abuse': false,
                  'Promotes terrorism': false,
                  'Spam or misleading': false,
                  'Legal issue': false,
                },
                contentId: post?.id ?? '',
                otherUserId: authorId,
                reportCallback: (params) async {
                  if (isGuestUser()) {
                    createProfileScreen();

                    return;
                  }
                  Get.find<FeedController>().postReport(
                      postId: post?.id ?? '', type: postType, params: params);
                },
              ),
            ),
          ),
        );
      },
    );
    // openPostReportDialog(
    //     context: Get.context!,
    //     userId: authorId,
    //     contentId: post?.id ?? '',
    //     reportType: 'POST',
    //     reportCallback: (params) async {
    //       if (isGuestUser()) {
    //         createProfileScreen();
    //
    //         return;
    //       }
    //       Get.find<FeedController>().postReport(
    //           postId: post?.id ?? '', type: postType, params: params);
    //     }
    //     );
  }
}
