import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_option_popup_menu.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/shared_preference_utils.dart';

class PostAuthorHeader extends StatelessWidget {
  final Post? post;
  final String authorId;
  final PostType postFilteredType;
  final VoidCallback? onTapAvatar;
  final VoidCallback? onTapOptions;
  final String? postedAgo;

  const PostAuthorHeader({
    super.key,
    required this.post,
    required this.authorId,
    required this.postFilteredType,
    this.onTapAvatar,
    this.onTapOptions,
    this.postedAgo,
  });

  @override
  Widget build(BuildContext context) {
    String name = (post?.user?.accountType == AppConstants.individual)
        ? post?.user?.name ?? ''
        : post?.user?.businessName ?? '';

    String designation = (post?.user?.accountType == AppConstants.individual)
        ?
      post?.user?.designation ?? "OTHERS"

        : post?.user?.businessCategory ?? '';


    String id = (post?.user?.accountType == AppConstants.individual)
        ? authorId
        : post?.user?.business_id??'';

    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.size15,
          top: SizeConfig.size10,
          bottom: SizeConfig.size15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (((authorId == userId) ||
                        (post?.user?.business_id == businessId)) &&
                    (postFilteredType == PostType.myPosts ||
                        postFilteredType == PostType.saved)) {
                  return;
                }
                if (post?.user?.accountType?.toUpperCase() ==
                    AppConstants.individual) {
                  if (userId == authorId) {
                    navigatePushTo(context, PersonalProfileSetupScreen());
                  } else {
                    Get.to(() => VisitProfileScreen(authorId: authorId));
                  }
                }
                if (post?.user?.accountType?.toUpperCase() ==
                    AppConstants.business) {
                  if (businessId == post?.user?.business_id) {
                    navigatePushTo(context, BusinessOwnProfileScreen());
                  } else {
                    Get.to(() => VisitBusinessProfile(
                        businessId: post?.user?.business_id ?? ""
                      )
                    );
                  }
                }
              },
              child: ChannelProfileHeader(
                imageUrl: post?.user?.profileImage ?? '',
                title: '$name',
                userName: '${post?.user?.username}',
                subtitle: designation,
                avatarSize: SizeConfig.size42,
                borderColor: AppColors.primaryColor,
                postedAgo: postedAgo
              ),
            ),
          ),

          if(post?.user?.accountType == AppConstants.individual)
            if(id != userId)
              IconButton(
                onPressed:(){
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else {
                    onTapOptions ?? blockUserPopUp();                  }

                },
                icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
              )
            else
              FeedPopUpMenu(
                  post: post ?? Post(id: ''),
                  postFilteredType: postFilteredType,
              )
          else if(post?.user?.accountType == AppConstants.business)
            if(id != businessId)
              IconButton(
                onPressed: onTapOptions ??
                        () => blockUserPopUp(),
                icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
              )
            else
              FeedPopUpMenu(
                  post: post ?? Post(id: ''),
                  postFilteredType: postFilteredType
              )

        ],
      ),
    );
  }

  void blockUserPopUp(){
    openBlockSelectionDialog(
        context: Get.context!,
        userBlockVoidCallback: () {
          Get.find<FeedController>().userBlocked(
              otherUserId: post?.authorId??'',
              type: postFilteredType
          );
        },
        postBlockVoidCallback: (){

        }
    );
  }
}
